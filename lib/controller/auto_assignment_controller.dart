// lib/controller/auto_assignment_controller.dart - VERSÃO DEBUG SIMPLIFICADA
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
  static const double MAX_ASSIGNMENT_RADIUS = 50.0; // AUMENTADO para debug

  @override
  void onInit() {
    super.onInit();
    print('🔧 AutoAssignmentController iniciado');
    initializeDriver();
  }

  @override
  void onClose() {
    assignmentTimer?.cancel();
    responseTimer?.cancel();
    orderStreamSubscription?.cancel();
    passengerResponseListener?.cancel();
    passengerResponseTimeout?.cancel();
    super.onClose();
  }

  /// Inicializa informações do motorista
  void initializeDriver() async {
    String currentUserId = FireStoreUtils.getCurrentUid();
    print('🔧 Inicializando motorista: $currentUserId');

    FireStoreUtils.fireStore
        .collection(CollectionName.driverUsers)
        .doc(currentUserId)
        .snapshots()
        .listen((event) {
      if (event.exists) {
        driverModel.value = DriverUserModel.fromJson(event.data()!);
        bool wasOnline = isOnline.value;
        isOnline.value = driverModel.value.isOnline ?? false;

        print('🔧 Status motorista: ${isOnline.value ? "ONLINE" : "OFFLINE"}');
        print('🔧 Localização disponível: ${driverModel.value.location != null}');
        print('🔧 Service ID: ${driverModel.value.serviceId}');

        if (!wasOnline && isOnline.value && driverModel.value.location != null) {
          print('🟢 Motorista ficou ONLINE - iniciando listener');
          startRealTimeOrderListener();
        } else if (!isOnline.value) {
          print('🔴 Motorista ficou OFFLINE - parando listener');
          stopOrderListener();
        }
      } else {
        print('❌ Documento do motorista não encontrado');
      }
    });
  }

  /// Para o listener de corridas
  void stopOrderListener() {
    orderStreamSubscription?.cancel();
    orderStreamSubscription = null;
    print('🛑 Listener de corridas PARADO');
  }

  /// VERSÃO SUPER SIMPLIFICADA - SEM MUITAS VERIFICAÇÕES
  void startRealTimeOrderListener() {
    print('🔄 Iniciando listener SIMPLIFICADO...');

    if (driverModel.value.location == null) {
      print('❌ Sem localização - não pode iniciar listener');
      return;
    }

    // Cancela listener anterior
    stopOrderListener();

    // VERSÃO SIMPLIFICADA: MENOS FILTROS, MAIS LOGS
    orderStreamSubscription = FireStoreUtils.fireStore
        .collection(CollectionName.orders)
        .where('status', isEqualTo: Constant.ridePlaced)
    // REMOVIDO: .where('serviceId', isEqualTo: driverModel.value.serviceId) // PARA DEBUG
        .snapshots()
        .listen((snapshot) {

      print('📦 Snapshot recebido com ${snapshot.docs.length} documentos');

      // LOGS DETALHADOS
      for (var doc in snapshot.docs) {
        var data = doc.data();
        print('📄 Corrida: ${doc.id}');
        print('   Status: ${data['status']}');
        print('   ServiceId: ${data['serviceId']}');
        print('   AssignedDriverId: ${data['assignedDriverId']}');
      }

      // VERIFICAÇÕES BÁSICAS APENAS
      if (!isOnline.value) {
        print('📴 OFFLINE - ignorando');
        return;
      }

      // PROCESSA TODAS AS CORRIDAS (PARA DEBUG)
      for (var docChange in snapshot.docChanges) {
        if (docChange.type == DocumentChangeType.added) {
          try {
            var data = docChange.doc.data() as Map<String, dynamic>;
            OrderModel newOrder = OrderModel.fromJson(data);

            print('🆕 Nova corrida adicionada: ${newOrder.id}');
            print('   Status: ${newOrder.status}');
            print('   AssignedDriverId: ${newOrder.assignedDriverId}');
            print('   ServiceId: ${newOrder.serviceId}');
            print('   SourceLocation: ${newOrder.sourceLocationName}');
            print('   Distance: ${newOrder.distance}');

            // VERIFICA SE É ELEGÍVEL COM LOGS DETALHADOS
            if (_isOrderEligibleForDriverDebug(newOrder)) {
              print('✅ CORRIDA ELEGÍVEL - Processando: ${newOrder.id}');
              _processNewOrderSimplified(newOrder);
              break;
            } else {
              print('❌ CORRIDA NÃO ELEGÍVEL: ${newOrder.id}');
            }
          } catch (e) {
            print('❌ Erro ao processar corrida: $e');
          }
        }
      }
    });

    print('✅ Listener iniciado com sucesso');
  }

  /// VERSÃO DEBUG: Verifica elegibilidade com logs detalhados
  bool _isOrderEligibleForDriverDebug(OrderModel order) {
    print('🔍 Verificando elegibilidade para corrida: ${order.id}');

    // 1. Verifica se já foi atribuída
    if (order.assignedDriverId != null) {
      print('   ❌ Já atribuída para: ${order.assignedDriverId}');
      return false;
    }
    print('   ✅ Não está atribuída');

    // 2. Verifica se o motorista já rejeitou
    String currentDriverId = FireStoreUtils.getCurrentUid();
    if (order.rejectedDriverIds?.contains(currentDriverId) ?? false) {
      print('   ❌ Motorista já rejeitou esta corrida');
      return false;
    }
    print('   ✅ Motorista não rejeitou');

    // 3. Verifica ServiceId (OPCIONAL PARA DEBUG)
    if (order.serviceId != driverModel.value.serviceId) {
      print('   ⚠️ ServiceId diferente: ${order.serviceId} vs ${driverModel.value.serviceId}');
      // return false; // COMENTADO PARA DEBUG
    }
    print('   ✅ ServiceId OK (ou ignorado)');

    // 4. Verifica localização
    if (order.sourceLocationLAtLng == null) {
      print('   ❌ Sem localização de origem');
      return false;
    }

    if (driverModel.value.location == null) {
      print('   ❌ Motorista sem localização');
      return false;
    }
    print('   ✅ Ambos têm localização');

    // 5. Calcula distância
    try {
      double distance = _calculateDistance(
        driverModel.value.location!.latitude!,
        driverModel.value.location!.longitude!,
        order.sourceLocationLAtLng!.latitude!,
        order.sourceLocationLAtLng!.longitude!,
      );

      print('   📏 Distância calculada: ${distance.toStringAsFixed(2)}km');
      print('   📏 Máximo permitido: ${MAX_ASSIGNMENT_RADIUS}km');

      if (distance > MAX_ASSIGNMENT_RADIUS) {
        print('   ❌ Muito distante');
        return false;
      }
      print('   ✅ Distância OK');

    } catch (e) {
      print('   ❌ Erro ao calcular distância: $e');
      return false;
    }

    // 6. Verifica estados do controller
    if (isShowingModal.value) {
      print('   ❌ Modal já sendo exibido');
      return false;
    }

    if (currentAssignedRide.value != null) {
      print('   ❌ Já tem corrida atual');
      return false;
    }

    if (isProcessingOrder.value) {
      print('   ❌ Já processando outra corrida');
      return false;
    }

    print('   🎯 CORRIDA TOTALMENTE ELEGÍVEL!');
    return true;
  }

  /// VERSÃO SIMPLIFICADA: Processa corrida
  Future<void> _processNewOrderSimplified(OrderModel order) async {
    print('⚙️ PROCESSANDO CORRIDA: ${order.id}');

    if (isProcessingOrder.value) {
      print('   ⚠️ Já processando outra - cancelando');
      return;
    }

    isProcessingOrder.value = true;

    try {
      // Pequeno delay
      await Future.delayed(const Duration(milliseconds: 100));

      // MOSTRA O DIALOG DIRETAMENTE (SEM MUITAS VERIFICAÇÕES)
      print('   📱 Chamando showRideAssignmentModal...');
      showRideAssignmentModalSimplified(order);

    } catch (e) {
      print('   ❌ Erro: $e');
    } finally {
      // Não libera imediatamente para evitar conflitos
      Future.delayed(const Duration(seconds: 1), () {
        if (isProcessingOrder.value && currentAssignedRide.value == null) {
          isProcessingOrder.value = false;
          print('   🔓 Processamento liberado');
        }
      });
    }
  }

  /// VERSÃO SUPER SIMPLIFICADA: Mostra modal
  void showRideAssignmentModalSimplified(OrderModel ride) {
    print('📱 TENTANDO MOSTRAR MODAL para: ${ride.id}');

    // Verificações mínimas
    if (Get.isDialogOpen == true) {
      print('   ❌ Já existe dialog aberto');
      return;
    }

    if (isShowingModal.value) {
      print('   ❌ isShowingModal já é true');
      return;
    }

    // Define estados
    currentAssignedRide.value = ride;
    isShowingModal.value = true;

    print('   ✅ Estados definidos, abrindo dialog...');

    // ABRE O DIALOG
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: RideAssignmentModal(
          orderModel: ride,
          onAccept: () {
            print('🟢 ACCEPT pressionado');
            acceptAssignedRide();
          },
          onReject: () {
            print('🔴 REJECT pressionado');
            rejectAssignedRide();
          },
        ),
      ),
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.8),
    ).then((_) {
      print('📱 Dialog fechado para corrida ${ride.id}');
      isShowingModal.value = false;
      if (currentAssignedRide.value == null) {
        isProcessingOrder.value = false;
      }
    });

    // Timer de timeout
    startResponseTimer();
    print('   ✅ MODAL ABERTO COM SUCESSO!');
  }

  /// Timer de timeout
  void startResponseTimer() {
    responseTimer?.cancel();
    responseTimer = Timer(const Duration(seconds: ASSIGNMENT_TIMEOUT), () {
      print('⏰ TIMEOUT - rejeitando automaticamente');
      if (isShowingModal.value && currentAssignedRide.value != null) {
        rejectAssignedRide();
      }
    });
  }

  /// Aceita corrida
  Future<void> acceptAssignedRide() async {
    print('✅ ACEITANDO CORRIDA...');

    if (currentAssignedRide.value == null) {
      print('   ❌ Nenhuma corrida para aceitar');
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

      // Cria registro
      DriverIdAcceptReject driverIdAcceptReject = DriverIdAcceptReject(
          driverId: FireStoreUtils.getCurrentUid(),
          acceptedRejectTime: Timestamp.now(),
          offerAmount: orderModel.offerRate ?? "0");

      await FireStoreUtils.acceptRide(orderModel, driverIdAcceptReject);

      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Oferta enviada! Aguardando resposta...".tr);

      print('✅ CORRIDA ACEITA COM SUCESSO');

      // Fecha modal e aguarda resposta do passageiro
      _clearModalOnly();
      _startPassengerResponseMonitoring(orderModel);

    } catch (e) {
      print('❌ Erro ao aceitar: $e');
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Erro ao aceitar corrida".tr);
      _clearCurrentAssignment();
    }
  }

  /// Rejeita corrida
  Future<void> rejectAssignedRide() async {
    print('❌ REJEITANDO CORRIDA...');

    if (currentAssignedRide.value == null) {
      print('   ❌ Nenhuma corrida para rejeitar');
      return;
    }

    try {
      OrderModel ride = currentAssignedRide.value!;

      await FireStoreUtils.fireStore
          .collection(CollectionName.orders)
          .doc(ride.id)
          .update({
        'assignedDriverId': FieldValue.delete(),
        'rejectedDriverIds': FieldValue.arrayUnion([FireStoreUtils.getCurrentUid()]),
      });

      print('✅ CORRIDA REJEITADA COM SUCESSO');
      _clearCurrentAssignment();

    } catch (e) {
      print('❌ Erro ao rejeitar: $e');
      _clearCurrentAssignment();
    }
  }

  /// Limpa estado atual
  void _clearCurrentAssignment() {
    print('🧹 LIMPANDO ESTADO ATUAL');

    responseTimer?.cancel();
    passengerResponseTimeout?.cancel();
    passengerResponseListener?.cancel();

    currentAssignedRide.value = null;
    isWaitingPassengerResponse.value = false;
    isShowingModal.value = false;

    if (Get.isDialogOpen == true) {
      try {
        Get.back();
      } catch (e) {
        print('⚠️ Erro ao fechar dialog: $e');
      }
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      isProcessingOrder.value = false;
      print('🧹 ESTADO LIMPO - PRONTO PARA NOVA CORRIDA');
    });
  }

  /// Limpa apenas modal
  void _clearModalOnly() {
    print('📱 FECHANDO MODAL');

    responseTimer?.cancel();
    isShowingModal.value = false;

    if (Get.isDialogOpen == true) {
      try {
        Get.back();
      } catch (e) {
        print('⚠️ Erro ao fechar dialog: $e');
      }
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      isProcessingOrder.value = false;
    });
  }

  /// Monitoramento de resposta do passageiro
  void _startPassengerResponseMonitoring(OrderModel order) {
    print('👀 INICIANDO MONITORAMENTO DE RESPOSTA');

    isWaitingPassengerResponse.value = true;
    _showWaitingPassengerDialog(order);

    passengerResponseListener = FireStoreUtils.fireStore
        .collection(CollectionName.orders)
        .doc(order.id)
        .snapshots()
        .listen((snapshot) {

      if (!snapshot.exists) {
        _handlePassengerResponse('CANCELLED', order, 'Corrida cancelada');
        return;
      }

      OrderModel updatedOrder = OrderModel.fromJson(snapshot.data()!);

      if (updatedOrder.driverId == FireStoreUtils.getCurrentUid()) {
        _handlePassengerResponse('ACCEPTED', updatedOrder, 'Passageiro aceitou!');
      } else if (updatedOrder.acceptedDriverId?.contains(FireStoreUtils.getCurrentUid()) == false) {
        _handlePassengerResponse('REJECTED', updatedOrder, 'Passageiro rejeitou');
      } else if (updatedOrder.driverId != null && updatedOrder.driverId != FireStoreUtils.getCurrentUid()) {
        _handlePassengerResponse('REJECTED', updatedOrder, 'Passageiro escolheu outro motorista');
      }
    });

    passengerResponseTimeout = Timer(const Duration(minutes: 5), () {
      if (isWaitingPassengerResponse.value) {
        _handlePassengerResponse('TIMEOUT', order, 'Tempo esgotado');
      }
    });
  }

  /// Dialog de espera
  void _showWaitingPassengerDialog(OrderModel order) {
    if (Get.isDialogOpen == true) return;

    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  'Aguardando Pagamento',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Finalizando o pagamento do passageiro.', style: GoogleFonts.poppins()),
              const SizedBox(height: 10),
              Text('Aguarde...', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14)),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// Resposta do passageiro
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

  /// Calcula distância
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

  /// MÉTODOS DE DEBUG E COMPATIBILIDADE
  void checkForAvailableRides() {
    print('🔍 VERIFICAÇÃO MANUAL SOLICITADA');
    // Stream já está ativo
  }

  bool get hasCurrentRide => currentAssignedRide.value != null;
  OrderModel? get getCurrentRide => currentAssignedRide.value;

  void forceCleanState() {
    print('🔧 LIMPEZA FORÇADA');
    _clearCurrentAssignment();
    stopOrderListener();
  }

  void restartSystem() {
    print('🔄 REINICIANDO SISTEMA');
    forceCleanState();
    Future.delayed(const Duration(seconds: 2), () {
      if (isOnline.value && driverModel.value.location != null) {
        startRealTimeOrderListener();
      }
    });
  }

  Map<String, dynamic> getSystemStatus() {
    var status = {
      'isOnline': isOnline.value,
      'isShowingModal': isShowingModal.value,
      'isProcessingOrder': isProcessingOrder.value,
      'hasCurrentRide': hasCurrentRide,
      'currentRideId': currentAssignedRide.value?.id,
      'hasActiveTimer': responseTimer?.isActive ?? false,
      'hasActiveListener': orderStreamSubscription != null,
      'driverLocation': driverModel.value.location != null,
      'driverServiceId': driverModel.value.serviceId,
    };

    print('📊 STATUS DO SISTEMA: $status');
    return status;
  }

  // Métodos de compatibilidade
  void initDriver() => initializeDriver();
  void stopAutoAssignment() => stopOrderListener();
  void startAutoAssignment() {
    if (isOnline.value && driverModel.value.location != null) {
      startRealTimeOrderListener();
    }
  }
  OrderModel? getCurrentAssignedRide() => currentAssignedRide.value;

  Future<void> toggleOnlineStatus() async {
    try {
      bool newStatus = !isOnline.value;

      await FireStoreUtils.fireStore
          .collection(CollectionName.driverUsers)
          .doc(FireStoreUtils.getCurrentUid())
          .update({'isOnline': newStatus});

      print('🔄 STATUS ALTERADO PARA: ${newStatus ? "ONLINE" : "OFFLINE"}');

      if (!newStatus) {
        forceCleanState();
      }

    } catch (e) {
      print('❌ Erro ao alterar status: $e');
      ShowToastDialog.showToast("Erro ao alterar status");
    }
  }
}