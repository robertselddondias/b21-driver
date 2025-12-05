// lib/controller/auto_assignment_controller.dart - VERSÃO COMPLETA COM BLOQUEIO
import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/constant/collection_name.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/send_notification.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/model/order/driverId_accept_reject.dart';
import 'package:driver/model/order_model.dart';
import 'package:driver/ui/dashboard_screen.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:driver/widget/ride_assignment_modal.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class AutoAssignmentController extends GetxController {
  static AutoAssignmentController get instance => Get.find();

  // Variáveis de controle
  RxBool isOnline = false.obs;
  Rx<DriverUserModel> driverModel = DriverUserModel().obs;
  Timer? assignmentTimer;
  Timer? responseTimer;
  StreamSubscription? orderStreamSubscription;
  StreamSubscription? activeRideMonitoringSubscription;

  // Variáveis da corrida atual
  Rx<OrderModel?> currentAssignedRide = Rx<OrderModel?>(null);
  RxBool isShowingModal = false.obs;
  RxBool isProcessingOrder = false.obs;

  // Variáveis para monitoramento de resposta
  RxBool isWaitingPassengerResponse = false.obs;
  StreamSubscription? passengerResponseListener;
  Timer? passengerResponseTimeout;

  // Configurações
  static const int ASSIGNMENT_TIMEOUT = 60;
  static const double MAX_ASSIGNMENT_RADIUS = 50.0;

  @override
  void onInit() {
    super.onInit();
    initializeDriver();
  }

  @override
  void onClose() {
    assignmentTimer?.cancel();
    responseTimer?.cancel();
    orderStreamSubscription?.cancel();
    passengerResponseListener?.cancel();
    passengerResponseTimeout?.cancel();
    activeRideMonitoringSubscription?.cancel();
    super.onClose();
  }

  /// ====================================================================
  /// VERIFICAÇÃO DE CORRIDA ATIVA - NOVO RECURSO
  /// ====================================================================

  /// Verifica se o motorista tem uma corrida ativa
  Future<bool> hasActiveRide() async {
    try {
      final snapshot = await FireStoreUtils.fireStore
          .collection(CollectionName.orders)
          .where('driverId', isEqualTo: FireStoreUtils.getCurrentUid())
          .where('status', whereIn: [
        Constant.rideActive,
        Constant.rideInProgress,
      ])
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      // Em caso de erro, assume que não tem corrida ativa (modo seguro)
      return false;
    }
  }

  /// Monitora mudanças em tempo real de corridas ativas
  void startActiveRideMonitoring() {
    activeRideMonitoringSubscription?.cancel();

    activeRideMonitoringSubscription = FireStoreUtils.fireStore
        .collection(CollectionName.orders)
        .where('driverId', isEqualTo: FireStoreUtils.getCurrentUid())
        .where('status', whereIn: [
      Constant.rideActive,
      Constant.rideInProgress,
    ])
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        // Se tem corrida ativa, limpa qualquer atribuição pendente
        if (isShowingModal.value || currentAssignedRide.value != null) {
          _clearCurrentAssignment();
        }
        // Para o listener de novas corridas
        stopOrderListener();
      } else {
        // Se não tem mais corrida ativa e está online, reinicia listener
        if (isOnline.value && driverModel.value.location != null) {
          startRealTimeOrderListener();
        }
      }
    });
  }

  /// ====================================================================
  /// INICIALIZAÇÃO DO MOTORISTA
  /// ====================================================================

  /// Inicializa informações do motorista
  void initializeDriver() async {
    String currentUserId = FireStoreUtils.getCurrentUid();

    FireStoreUtils.fireStore
        .collection(CollectionName.driverUsers)
        .doc(currentUserId)
        .snapshots()
        .listen((event) {
      if (event.exists) {
        driverModel.value = DriverUserModel.fromJson(event.data()!);
        bool wasOnline = isOnline.value;
        isOnline.value = driverModel.value.isOnline ?? false;

        if (isOnline.value && !wasOnline) {
          // Ficou online agora
          startActiveRideMonitoring();

          // Inicia listener apenas se não tiver corrida ativa
          hasActiveRide().then((hasActive) {
            if (!hasActive && driverModel.value.location != null) {
              startRealTimeOrderListener();
            }
          });

        } else if (!isOnline.value && wasOnline) {
          // Ficou offline agora
          stopOrderListener();
          forceCleanState();
        }
      }
    });
  }

  /// ====================================================================
  /// LISTENER DE CORRIDAS DISPONÍVEIS (COM BLOQUEIO)
  /// ====================================================================

  /// Inicia listener em tempo real para corridas disponíveis
  void startRealTimeOrderListener() {
    if (driverModel.value.location == null) {
      return;
    }

    if (driverModel.value.serviceId == null || driverModel.value.serviceId!.isEmpty) {
      return;
    }

    stopOrderListener();

    orderStreamSubscription = FireStoreUtils.fireStore
        .collection(CollectionName.orders)
        .where('serviceId', isEqualTo: driverModel.value.serviceId)
        .where('status', isEqualTo: Constant.ridePlaced)
        .snapshots()
        .listen((snapshot) async {

      // ⚠️ VERIFICAÇÃO CRÍTICA #1: Bloqueia se já tem corrida ativa
      bool activeRide = await hasActiveRide();
      if (activeRide) {
        stopOrderListener();
        return;
      }

      if (isProcessingOrder.value || isShowingModal.value) {
        return;
      }

      if (currentAssignedRide.value != null) {
        return;
      }

      for (var doc in snapshot.docs) {
        try {
          // ⚠️ VERIFICAÇÃO CRÍTICA #2: Verifica novamente durante o loop
          activeRide = await hasActiveRide();
          if (activeRide) {
            stopOrderListener();
            return;
          }

          OrderModel order = OrderModel.fromJson(doc.data());

          if (order.id == null || order.sourceLocationLAtLng == null) {
            continue;
          }

          // Verifica se já foi rejeitada por este motorista
          if (order.rejectedDriverId != null &&
              order.rejectedDriverId!.contains(FireStoreUtils.getCurrentUid())) {
            continue;
          }

          // Verifica se já tem motorista atribuído
          if (order.assignedDriverId != null && order.assignedDriverId!.isNotEmpty) {
            continue;
          }

          // Calcula distância do motorista até o ponto de partida
          double distance = _calculateDistance(
            driverModel.value.location!.latitude!,
            driverModel.value.location!.longitude!,
            order.sourceLocationLAtLng!.latitude!,
            order.sourceLocationLAtLng!.longitude!,
          );

          if (distance <= MAX_ASSIGNMENT_RADIUS) {
            // ⚠️ VERIFICAÇÃO CRÍTICA #3: Última verificação antes do modal
            activeRide = await hasActiveRide();
            if (activeRide) {
              stopOrderListener();
              return;
            }

            _assignRideToDriver(order);
            return;
          }
        } catch (e) {
          // Erro ao processar pedido individual - continua para próximo
          continue;
        }
      }
    }, onError: (error) {
      // Erro no listener - reinicia após delay
      Future.delayed(const Duration(seconds: 5), () {
        if (isOnline.value && driverModel.value.location != null) {
          startRealTimeOrderListener();
        }
      });
    });
  }

  /// Para o listener de corridas
  void stopOrderListener() {
    orderStreamSubscription?.cancel();
    orderStreamSubscription = null;
  }

  /// ====================================================================
  /// ATRIBUIÇÃO DE CORRIDA
  /// ====================================================================

  /// Atribui corrida ao motorista e mostra modal
  void _assignRideToDriver(OrderModel order) async {
    if (isShowingModal.value || isProcessingOrder.value) {
      return;
    }

    isProcessingOrder.value = true;
    currentAssignedRide.value = order;

    await Future.delayed(const Duration(milliseconds: 300));

    isShowingModal.value = true;
    isProcessingOrder.value = false;

    startResponseTimer();

    Get.dialog(
      RideAssignmentModal(
        orderModel: order,
        onAccept: acceptAssignedRide,
        onReject: rejectAssignedRide,
      ),
      barrierDismissible: false,
    );
  }

  /// ====================================================================
  /// ACEITAR/REJEITAR CORRIDA
  /// ====================================================================

  /// Aceita corrida atribuída
  Future<void> acceptAssignedRide() async {
    if (currentAssignedRide.value == null) {
      return;
    }

    // ⚠️ VERIFICAÇÃO CRÍTICA #4: Confirma que não tem corrida ativa
    bool activeRide = await hasActiveRide();
    if (activeRide) {
      ShowToastDialog.showToast("Você já possui uma corrida ativa");
      _clearCurrentAssignment();
      return;
    }

    try {
      ShowToastDialog.showLoader("Aceitando corrida...".tr);
      OrderModel orderModel = currentAssignedRide.value!;

      // Marca como atribuída no Firestore
      await FireStoreUtils.fireStore
          .collection(CollectionName.orders)
          .doc(orderModel.id)
          .update({
        'assignedDriverId': FireStoreUtils.getCurrentUid(),
        'assignedAt': Timestamp.now(),
      });

      // Atualiza acceptedDriverId
      List<dynamic> newAcceptedDriverId = orderModel.acceptedDriverId ?? [];
      newAcceptedDriverId.add(FireStoreUtils.getCurrentUid());
      orderModel.acceptedDriverId = newAcceptedDriverId;

      await FireStoreUtils.setOrder(orderModel);

      // Notifica passageiro
      await FireStoreUtils.getCustomer(orderModel.userId.toString()).then((value) async {
        if (value != null) {
          await SendNotification.sendOneNotification(
              token: value.fcmToken.toString(),
              title: 'Corrida aceita'.tr,
              body: 'Motorista aceitou sua corrida. 🚗'.tr,
              payload: {});
        }
      });

      // Cria registro de aceitação
      DriverIdAcceptReject driverIdAcceptReject = DriverIdAcceptReject(
          driverId: FireStoreUtils.getCurrentUid(),
          acceptedRejectTime: Timestamp.now(),
          offerAmount: orderModel.offerRate ?? "0");

      await FireStoreUtils.acceptRide(orderModel, driverIdAcceptReject);

      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Oferta enviada! Aguardando resposta...".tr);

      // Fecha modal e aguarda resposta do passageiro
      _clearModalOnly();
      _startPassengerResponseMonitoring(orderModel);

    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Erro ao aceitar corrida".tr);
      _clearCurrentAssignment();
    }
  }

  /// Rejeita corrida atribuída
  Future<void> rejectAssignedRide() async {
    if (currentAssignedRide.value == null) {
      return;
    }

    try {
      OrderModel ride = currentAssignedRide.value!;

      // Adiciona motorista na lista de rejeitados
      List<dynamic> rejectedList = ride.rejectedDriverId ?? [];
      if (!rejectedList.contains(FireStoreUtils.getCurrentUid())) {
        rejectedList.add(FireStoreUtils.getCurrentUid());
      }

      // CORREÇÃO CRÍTICA: Limpa a atribuição e volta status para ridePlaced
      Map<String, dynamic> updateData = {
        'rejectedDriverId': rejectedList,
      };

      // Se este motorista estava atribuído, limpa a atribuição
      if (ride.assignedDriverId == FireStoreUtils.getCurrentUid()) {
        updateData['assignedDriverId'] = null;
        updateData['assignedAt'] = null;

        // Se a corrida ainda não foi aceita pelo passageiro, volta para ridePlaced
        if (ride.status == Constant.ridePlaced || ride.status == null) {
          updateData['status'] = Constant.ridePlaced;
        }
      }

      // Remove da lista de aceitos se estava lá
      if (ride.acceptedDriverId != null &&
          ride.acceptedDriverId!.contains(FireStoreUtils.getCurrentUid())) {
        List<dynamic> acceptedList = List.from(ride.acceptedDriverId!);
        acceptedList.remove(FireStoreUtils.getCurrentUid());
        updateData['acceptedDriverId'] = acceptedList;
      }

      await FireStoreUtils.fireStore
          .collection(CollectionName.orders)
          .doc(ride.id)
          .update(updateData);

      ShowToastDialog.showToast("Corrida rejeitada".tr);

    } catch (e) {
      ShowToastDialog.showToast("Erro ao rejeitar corrida".tr);
    } finally {
      _clearCurrentAssignment();
    }
  }

  /// ====================================================================
  /// MONITORAMENTO DE RESPOSTA DO PASSAGEIRO
  /// ====================================================================

  /// Monitora resposta do passageiro após aceitação
  void _startPassengerResponseMonitoring(OrderModel order) {
    print('👂 MONITORANDO RESPOSTA DO PASSAGEIRO...');

    isWaitingPassengerResponse.value = true;

    // Timeout de 60 segundos
    passengerResponseTimeout = Timer(const Duration(seconds: 60), () {
      print('⏰ TIMEOUT - Passageiro não respondeu');
      _handlePassengerResponse('TIMEOUT', order, 'O passageiro não respondeu a tempo');
    });

    // Listener para mudanças na corrida
    passengerResponseListener = FireStoreUtils.fireStore
        .collection(CollectionName.orders)
        .doc(order.id)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;

      OrderModel updatedOrder = OrderModel.fromJson(snapshot.data()!);

      // Passageiro aceitou
      if (updatedOrder.status == Constant.rideActive) {
        print('✅ PASSAGEIRO ACEITOU!');
        _handlePassengerResponse('ACCEPTED', updatedOrder, 'Passageiro aceitou! Indo buscar...');
      }
      // Passageiro rejeitou
      else if (updatedOrder.rejectedDriverId != null &&
          updatedOrder.rejectedDriverId!.contains(FireStoreUtils.getCurrentUid())) {
        print('❌ PASSAGEIRO REJEITOU');
        _handlePassengerResponse('REJECTED', updatedOrder, 'Passageiro escolheu outro motorista');
      }
    });

    // Mostra dialog de aguardo
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 15),
                  Text('Aguardando resposta do passageiro...',
                      style: GoogleFonts.poppins(fontSize: 16)),
                  const SizedBox(height: 10),
                  Text('Aguarde...',
                      style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// Trata resposta do passageiro
  void _handlePassengerResponse(String responseType, OrderModel order, String message) {
    if (!isWaitingPassengerResponse.value) return;

    print('📱 RESPOSTA DO PASSAGEIRO: $responseType');

    passengerResponseListener?.cancel();
    passengerResponseTimeout?.cancel();
    isWaitingPassengerResponse.value = false;

    if (Get.isDialogOpen == true) {
      Get.back();
    }

    ShowToastDialog.showToast(message);

    if (responseType == 'ACCEPTED') {
      Get.to(() => const DashBoardScreen());
    }

    _clearCurrentAssignment();
  }

  /// ====================================================================
  /// CONTROLE DE STATUS ONLINE/OFFLINE
  /// ====================================================================

  /// Alterna status online/offline
  Future<void> toggleOnlineStatus() async {
    try {
      bool newStatus = !isOnline.value;

      // ⚠️ VERIFICAÇÃO CRÍTICA #5: Se tentando ficar online, verifica corrida ativa
      if (newStatus) {
        bool activeRide = await hasActiveRide();
        if (activeRide) {
          ShowToastDialog.showToast(
              "Complete sua corrida ativa antes de ficar online novamente"
          );
          return;
        }
      }

      await FireStoreUtils.fireStore
          .collection(CollectionName.driverUsers)
          .doc(FireStoreUtils.getCurrentUid())
          .update({'isOnline': newStatus});

      print('🔄 STATUS ALTERADO PARA: ${newStatus ? "ONLINE" : "OFFLINE"}');

      if (!newStatus) {
        forceCleanState();
      } else {
        // Inicia monitoramento ao ficar online
        startActiveRideMonitoring();
      }

    } catch (e) {
      print('❌ Erro ao alterar status: $e');
      ShowToastDialog.showToast("Erro ao alterar status");
    }
  }

  /// ====================================================================
  /// UTILITÁRIOS E LIMPEZA
  /// ====================================================================

  /// Limpa estado atual (modal + atribuição)
  void _clearCurrentAssignment() {
    print('🧹 Limpando atribuição atual');

    responseTimer?.cancel();

    if (Get.isDialogOpen == true) {
      Get.back();
    }

    currentAssignedRide.value = null;
    isShowingModal.value = false;
    isProcessingOrder.value = false;
  }

  /// Limpa apenas o modal (mantém atribuição)
  void _clearModalOnly() {
    print('🧹 Fechando modal (mantendo atribuição)');

    responseTimer?.cancel();

    if (Get.isDialogOpen == true) {
      Get.back();
    }

    isShowingModal.value = false;
    isProcessingOrder.value = false;
  }

  /// Timer de timeout da oferta
  void startResponseTimer() {
    responseTimer?.cancel();
    responseTimer = Timer(const Duration(seconds: ASSIGNMENT_TIMEOUT), () {
      print('⏰ TIMEOUT - rejeitando automaticamente');
      if (isShowingModal.value && currentAssignedRide.value != null) {
        rejectAssignedRide();
      }
    });
  }

  /// Calcula distância entre dois pontos (Haversine)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double radiusOfEarth = 6371.0;
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return radiusOfEarth * c;
  }

  double _toRadians(double degrees) => degrees * (pi / 180);

  /// ====================================================================
  /// MÉTODOS DE DEBUG E COMPATIBILIDADE
  /// ====================================================================

  /// Verifica corridas disponíveis manualmente
  void checkForAvailableRides() {
    print('🔍 VERIFICAÇÃO MANUAL SOLICITADA');
    // Stream já está ativo, não precisa fazer nada
  }

  /// Verifica se tem corrida atribuída no momento
  bool get hasCurrentRide => currentAssignedRide.value != null;

  /// Retorna a corrida atual se houver
  OrderModel? get getCurrentRide => currentAssignedRide.value;

  /// Limpa tudo e reseta o estado
  void forceCleanState() {
    print('🔧 LIMPEZA FORÇADA DE ESTADO');
    _clearCurrentAssignment();
    stopOrderListener();
    activeRideMonitoringSubscription?.cancel();
    passengerResponseListener?.cancel();
    passengerResponseTimeout?.cancel();
    isWaitingPassengerResponse.value = false;
  }

  /// Reinicia o sistema completamente
  void restartSystem() {
    print('🔄 REINICIANDO SISTEMA COMPLETO');
    forceCleanState();
    Future.delayed(const Duration(seconds: 2), () {
      if (isOnline.value && driverModel.value.location != null) {
        startActiveRideMonitoring();
        hasActiveRide().then((hasActive) {
          if (!hasActive) {
            startRealTimeOrderListener();
          }
        });
      }
    });
  }

  /// Retorna status completo do sistema
  Map<String, dynamic> getSystemStatus() {
    var status = {
      'isOnline': isOnline.value,
      'isShowingModal': isShowingModal.value,
      'isProcessingOrder': isProcessingOrder.value,
      'hasCurrentRide': hasCurrentRide,
      'currentRideId': currentAssignedRide.value?.id,
      'isWaitingPassengerResponse': isWaitingPassengerResponse.value,
      'hasActiveTimer': responseTimer?.isActive ?? false,
      'hasActiveListener': orderStreamSubscription != null,
      'hasActiveRideMonitor': activeRideMonitoringSubscription != null,
      'driverLocation': driverModel.value.location != null,
      'driverServiceId': driverModel.value.serviceId,
    };

    print('📊 STATUS DO SISTEMA: $status');
    return status;
  }

  /// Métodos de compatibilidade com código antigo
  void initDriver() => initializeDriver();
  void stopAutoAssignment() => stopOrderListener();
  void startAutoAssignment() {
    if (isOnline.value && driverModel.value.location != null) {
      startActiveRideMonitoring();
      hasActiveRide().then((hasActive) {
        if (!hasActive) {
          startRealTimeOrderListener();
        }
      });
    }
  }
  OrderModel? getCurrentAssignedRide() => currentAssignedRide.value;
}