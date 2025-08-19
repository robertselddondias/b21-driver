// lib/controller/auto_assignment_controller.dart
import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/constant/collection_name.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/send_notification.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/model/order_model.dart';
import 'package:driver/model/order/driverId_accept_reject.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:driver/widget/ride_assignment_modal.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AutoAssignmentController extends GetxController {
  static AutoAssignmentController get instance => Get.find();

  // Variáveis de controle
  RxBool isOnline = false.obs;
  Rx<DriverUserModel> driverModel = DriverUserModel().obs;
  Timer? assignmentTimer;
  Timer? responseTimer;

  // Variáveis da corrida atual
  Rx<OrderModel?> currentAssignedRide = Rx<OrderModel?>(null);
  RxBool isShowingModal = false.obs;

  // Configurações
  static const int ASSIGNMENT_TIMEOUT = 15; // 15 segundos para responder
  static const double MAX_ASSIGNMENT_RADIUS = 10.0; // 10km máximo

  @override
  void onInit() {
    super.onInit();
    initializeDriver();
    startAutoAssignmentListener();
  }

  @override
  void onClose() {
    assignmentTimer?.cancel();
    responseTimer?.cancel();
    // Não precisamos fechar stream listeners explicitamente pois o GetX faz isso automaticamente
    super.onClose();
  }

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
        isOnline.value = driverModel.value.isOnline ?? false;

        // Reinicia listener quando dados do motorista mudam
        if (driverModel.value.location != null) {
          startRealTimeOrderListener();
        }
      }
    });
  }

  /// Inicia o listener para atribuição automática
  void startAutoAssignmentListener() {
    // Cancela timer anterior se existir
    assignmentTimer?.cancel();

    // Em vez de timer, agora usamos stream listener em tempo real
    startRealTimeOrderListener();
  }

  /// Listener em tempo real para novas corridas (como o sistema original)
  void startRealTimeOrderListener() {
    if (driverModel.value.location == null) return;

    // Stream listener em tempo real para novas corridas
    FireStoreUtils.fireStore
        .collection(CollectionName.orders)
        .where('status', isEqualTo: Constant.ridePlaced)
        .where('serviceId', isEqualTo: driverModel.value.serviceId)
        .snapshots()
        .listen((snapshot) {

      if (!isOnline.value || isShowingModal.value || currentAssignedRide.value != null) {
        return; // Não processa se offline, já mostrando modal, ou já tem corrida atribuída
      }

      // Processa apenas documentos novos ou modificados
      for (var docChange in snapshot.docChanges) {
        if (docChange.type == DocumentChangeType.added) {
          try {
            OrderModel newOrder = OrderModel.fromJson(docChange.doc.data() as Map<String, dynamic>);

            // Verifica se a corrida é elegível para este motorista
            if (_isOrderEligibleForDriver(newOrder)) {
              print('🚗 Nova corrida detectada: ${newOrder.id}');

              // IMPORTANTE: Marca que está processando para evitar duplicatas
              if (!isShowingModal.value && currentAssignedRide.value == null) {
                _processNewOrder(newOrder);
                break; // Processa apenas uma corrida por vez
              }
            }
          } catch (e) {
            print('Erro ao processar nova corrida: $e');
          }
        }
      }
    });
  }

  /// Verifica se a corrida é elegível para este motorista
  bool _isOrderEligibleForDriver(OrderModel order) {
    // Verifica se já foi atribuída
    if (order.assignedDriverId != null) return false;

    // Verifica se o motorista já rejeitou esta corrida
    if (order.rejectedDriverIds?.contains(FireStoreUtils.getCurrentUid()) ?? false) return false;

    // Verifica se está dentro do raio permitido
    if (order.sourceLocationLAtLng != null && driverModel.value.location != null) {
      double distance = _calculateDistance(
        driverModel.value.location!.latitude!,
        driverModel.value.location!.longitude!,
        order.sourceLocationLAtLng!.latitude!,
        order.sourceLocationLAtLng!.longitude!,
      );

      if (distance > MAX_ASSIGNMENT_RADIUS) return false;
    }

    // Verifica se é do mesmo serviço
    if (order.serviceId != driverModel.value.serviceId) return false;

    // Verifica se está na zona do motorista
    if (driverModel.value.zoneIds != null && order.zoneId != null) {
      if (!driverModel.value.zoneIds!.contains(order.zoneId)) return false;
    }

    return true;
  }

  /// Processa nova corrida detectada
  void _processNewOrder(OrderModel order) async {
    try {
      print('🔄 Processando nova corrida: ${order.id}');

      // Aplica algoritmo de seleção (verifica se é a melhor corrida)
      OrderModel? selectedRide = selectBestRideForDriver([order]);

      if (selectedRide != null) {
        // Atribui a corrida automaticamente
        await assignRideToDriver(selectedRide);
        print('✅ Corrida ${order.id} atribuída com sucesso');
      } else {
        print('❌ Corrida ${order.id} não selecionada pelo algoritmo');
      }
    } catch (e) {
      print('Erro ao processar nova corrida: $e');
    }
  }

  /// Verifica se há corridas disponíveis para atribuir
  void checkForAvailableRides() async {
    if (driverModel.value.location == null) return;

    try {
      // Busca corridas pendentes próximas
      QuerySnapshot ordersSnapshot = await FireStoreUtils.fireStore
          .collection(CollectionName.orders)
          .where('status', isEqualTo: Constant.ridePlaced)
          .where('assignedDriverId', isNull: true)
          .orderBy('createdDate', descending: false)
          .limit(20)
          .get();

      if (ordersSnapshot.docs.isNotEmpty) {
        List<OrderModel> availableRides = ordersSnapshot.docs
            .map((doc) => OrderModel.fromJson(doc.data() as Map<String, dynamic>))
            .toList();

        // Aplica algoritmo de seleção
        OrderModel? selectedRide = selectBestRideForDriver(availableRides);

        if (selectedRide != null) {
          await assignRideToDriver(selectedRide);
        }
      }
    } catch (e) {
      print('Erro ao verificar corridas disponíveis: $e');
    }
  }

  /// Algoritmo para selecionar a melhor corrida para o motorista
  OrderModel? selectBestRideForDriver(List<OrderModel> availableRides) {
    if (availableRides.isEmpty) return null;

    OrderModel? bestRide;
    double shortestDistance = double.infinity;

    for (OrderModel ride in availableRides) {
      if (ride.sourceLocationLAtLng == null) continue;

      // Calcula distância entre motorista e origem da corrida
      double distance = _calculateDistance(
        driverModel.value.location!.latitude!,
        driverModel.value.location!.longitude!,
        ride.sourceLocationLAtLng!.latitude!,
        ride.sourceLocationLAtLng!.longitude!,
      );

      // Verifica se está dentro do raio permitido
      if (distance <= MAX_ASSIGNMENT_RADIUS) {
        // Aplica critérios de seleção (pode ser expandido)
        double score = _calculateRideScore(ride, distance);

        if (score < shortestDistance) {
          shortestDistance = score;
          bestRide = ride;
        }
      }
    }

    return bestRide;
  }

  /// Calcula score da corrida (menor é melhor)
  double _calculateRideScore(OrderModel ride, double distance) {
    double score = distance; // Base: distância

    // Fatores que podem influenciar o score:
    // - Tempo de espera da corrida
    // - Valor da corrida
    // - Avaliação do passageiro (se disponível)

    if (ride.createdDate != null) {
      int waitingTimeMinutes = DateTime.now().difference(ride.createdDate!.toDate()).inMinutes;
      score += waitingTimeMinutes * 0.1; // Prioriza corridas que estão esperando há mais tempo
    }

    return score;
  }

  /// Atribui corrida ao motorista e mostra modal
  Future<void> assignRideToDriver(OrderModel ride) async {
    try {
      // Verifica novamente se pode processar (evita condições de corrida)
      if (isShowingModal.value || currentAssignedRide.value != null) {
        print('⚠️ Já há uma corrida sendo processada, ignorando');
        return;
      }

      // Marca corrida como atribuída no Firestore
      await FireStoreUtils.fireStore
          .collection(CollectionName.orders)
          .doc(ride.id)
          .update({
        'assignedDriverId': FireStoreUtils.getCurrentUid(),
        'assignedAt': Timestamp.now(),
      });

      // Define corrida atual ANTES de mostrar o modal
      currentAssignedRide.value = ride;

      // Mostra modal de atribuição
      showRideAssignmentModal(ride);

      // Inicia timer de timeout
      startResponseTimer();

    } catch (e) {
      print('Erro ao atribuir corrida: $e');
      // Se houve erro, limpa o estado
      _clearCurrentAssignment();
    }
  }

  /// Mostra modal de atribuição de corrida
  void showRideAssignmentModal(OrderModel ride) {
    // Evita mostrar múltiplos modais
    if (isShowingModal.value) {
      print('⚠️ Modal já está sendo exibido, ignorando nova solicitação');
      return;
    }

    isShowingModal.value = true;

    Get.dialog(
      RideAssignmentModal(
        orderModel: ride,
        onAccept: () => acceptAssignedRide(),
        onReject: () => rejectAssignedRide(),
      ),
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.8),
    ).then((_) {
      // Quando o modal for fechado (por qualquer motivo), limpa o estado
      if (isShowingModal.value) {
        _clearCurrentAssignment();
      }
    });
  }

  /// Inicia timer para timeout de resposta
  void startResponseTimer() {
    responseTimer?.cancel();

    responseTimer = Timer(const Duration(seconds: ASSIGNMENT_TIMEOUT), () {
      if (isShowingModal.value) {
        // Timeout - automaticamente rejeita
        rejectAssignedRide();
      }
    });
  }

  /// Aceita a corrida atribuída
  Future<void> acceptAssignedRide() async {
    if (currentAssignedRide.value == null) return;

    try {
      ShowToastDialog.showLoader("Aceitando corrida...".tr);

      OrderModel ride = currentAssignedRide.value!;

      // Atualiza status da corrida
      await FireStoreUtils.fireStore
          .collection(CollectionName.orders)
          .doc(ride.id)
          .update({
        'status': Constant.rideActive,
        'driverId': FireStoreUtils.getCurrentUid(),
        'acceptedAt': Timestamp.now(),
      });

      // Cria registro de aceitação
      DriverIdAcceptReject driverAcceptance = DriverIdAcceptReject(
        driverId: FireStoreUtils.getCurrentUid(),
        acceptedRejectTime: Timestamp.now(),
        offerAmount: ride.offerRate ?? "0",
      );

      await FireStoreUtils.acceptRide(ride, driverAcceptance);

      // Notifica passageiro
      await _notifyPassenger(ride, true);

      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Corrida aceita com sucesso!".tr);

      // Limpa estado DEPOIS de tudo processado
      _clearCurrentAssignment();

    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Erro ao aceitar corrida".tr);
      print('Erro ao aceitar corrida: $e');
      _clearCurrentAssignment();
    }
  }

  /// Rejeita a corrida atribuída
  Future<void> rejectAssignedRide() async {
    if (currentAssignedRide.value == null) return;

    try {
      OrderModel ride = currentAssignedRide.value!;

      // Remove atribuição da corrida
      await FireStoreUtils.fireStore
          .collection(CollectionName.orders)
          .doc(ride.id)
          .update({
        'assignedDriverId': FieldValue.delete(),
        'rejectedDriverIds': FieldValue.arrayUnion([FireStoreUtils.getCurrentUid()]),
      });

      // Limpa estado
      _clearCurrentAssignment();

      // Reinicia busca por novas corridas
      Future.delayed(const Duration(seconds: 2), () {
        checkForAvailableRides();
      });

    } catch (e) {
      print('Erro ao rejeitar corrida: $e');
    }
  }

  /// Limpa atribuição atual
  void _clearCurrentAssignment() {
    currentAssignedRide.value = null;
    isShowingModal.value = false;
    responseTimer?.cancel();

    // Só fecha o dialog se ainda estiver aberto
    if (Get.isDialogOpen == true) {
      Get.back();
    }

    print('🧹 Estado limpo - pronto para nova corrida');
  }

  /// Notifica passageiro sobre aceitação/rejeição
  Future<void> _notifyPassenger(OrderModel ride, bool accepted) async {
    try {
      var customer = await FireStoreUtils.getCustomer(ride.userId.toString());
      if (customer != null && customer.fcmToken != null) {
        await SendNotification.sendOneNotification(
          token: customer.fcmToken!,
          title: accepted ? 'Corrida Aceita'.tr : 'Motorista Rejeitou'.tr,
          body: accepted
              ? 'Motorista aceitou sua corrida. 🚗'.tr
              : 'Procurando outro motorista...'.tr,
          payload: {'orderId': ride.id ?? ''},
        );
      }
    } catch (e) {
      print('Erro ao notificar passageiro: $e');
    }
  }

  /// Calcula distância entre dois pontos em km
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Raio da Terra em km

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  /// Alterna status online/offline
  Future<void> toggleOnlineStatus() async {
    try {
      bool newStatus = !isOnline.value;

      await FireStoreUtils.fireStore
          .collection(CollectionName.driverUsers)
          .doc(FireStoreUtils.getCurrentUid())
          .update({'isOnline': newStatus});

      isOnline.value = newStatus;

      if (!newStatus) {
        // Se ficou offline, limpa atribuição atual
        if (currentAssignedRide.value != null) {
          await rejectAssignedRide();
        }
      }

      ShowToastDialog.showToast(
          newStatus ? 'Agora você está online'.tr : 'Agora você está offline'.tr
      );

    } catch (e) {
      ShowToastDialog.showToast('Erro ao alterar status'.tr);
    }
  }
}