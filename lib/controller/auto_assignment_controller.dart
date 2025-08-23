// lib/controller/auto_assignment_controller.dart
import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/constant/collection_name.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/send_notification.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/controller/home_controller.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/model/order_model.dart';
import 'package:driver/model/order/driverId_accept_reject.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/ui/dashboard_screen.dart';
import 'package:driver/ui/home_screens/live_tracking_screen.dart';
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
  RxBool isProcessingOrder = false.obs; // Nova variável para controlar processamento

  // NOVAS variáveis para monitoramento de resposta
  RxBool isWaitingPassengerResponse = false.obs;
  StreamSubscription? passengerResponseListener;
  Timer? passengerResponseTimeout;

  // Configurações
  static const int ASSIGNMENT_TIMEOUT = 15; // 15 segundos para responder
  static const double MAX_ASSIGNMENT_RADIUS = 10.0; // 10km máximo

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
        bool wasOnline = isOnline.value;
        isOnline.value = driverModel.value.isOnline ?? false;

        // Só inicia o listener se ficou online agora
        if (!wasOnline && isOnline.value && driverModel.value.location != null) {
          startRealTimeOrderListener();
        } else if (!isOnline.value) {
          // Se ficou offline, para o listener
          stopOrderListener();
        }
      }
    });
  }

  /// Para o listener de corridas
  void stopOrderListener() {
    orderStreamSubscription?.cancel();
    orderStreamSubscription = null;
    print('🛑 Listener de corridas parado');
  }

  /// Listener em tempo real para novas corridas
  void startRealTimeOrderListener() {
    if (driverModel.value.location == null) {
      print('⚠️ Localização do motorista não disponível');
      return;
    }

    // Cancela listener anterior se existir
    stopOrderListener();

    print('🔄 Iniciando listener em tempo real para corridas...');

    // Stream listener em tempo real para novas corridas
    orderStreamSubscription = FireStoreUtils.fireStore
        .collection(CollectionName.orders)
        .where('status', isEqualTo: Constant.ridePlaced)
        .where('serviceId', isEqualTo: driverModel.value.serviceId)
        .snapshots()
        .listen((snapshot) {

      // Verificações de estado mais rigorosas
      if (!isOnline.value) {
        print('📴 Motorista offline - ignorando corridas');
        return;
      }

      if (isShowingModal.value) {
        print('📱 Modal já sendo exibido - ignorando novas corridas');
        return;
      }

      if (currentAssignedRide.value != null) {
        print('🚗 Já tem corrida atribuída - ignorando novas corridas');
        return;
      }

      if (isProcessingOrder.value) {
        print('⚙️ Já processando uma corrida - ignorando novas corridas');
        return;
      }

      // Processa apenas documentos novos
      for (var docChange in snapshot.docChanges) {
        if (docChange.type == DocumentChangeType.added) {
          try {
            OrderModel newOrder = OrderModel.fromJson(docChange.doc.data() as Map<String, dynamic>);

            // Verificações de elegibilidade mais rigorosas
            if (_isOrderEligibleForDriver(newOrder)) {
              print('🚗 Nova corrida detectada: ${newOrder.id}');

              // Verifica novamente o estado antes de processar
              if (!isShowingModal.value &&
                  currentAssignedRide.value == null &&
                  !isProcessingOrder.value &&
                  isOnline.value) {
                _processNewOrder(newOrder);
                break; // Processa apenas uma corrida por vez
              }
            }
          } catch (e) {
            print('❌ Erro ao processar nova corrida: $e');
          }
        }
      }
    });
  }

  /// Verifica se a corrida é elegível para este motorista
  bool _isOrderEligibleForDriver(OrderModel order) {
    // Verifica se já foi atribuída
    if (order.assignedDriverId != null) {
      print('❌ Corrida ${order.id} já atribuída para ${order.assignedDriverId}');
      return false;
    }

    // Verifica se o motorista já rejeitou esta corrida
    if (order.rejectedDriverIds?.contains(FireStoreUtils.getCurrentUid()) ?? false) {
      print('❌ Motorista já rejeitou a corrida ${order.id}');
      return false;
    }

    // Verifica distância
    if (order.sourceLocationLAtLng == null || driverModel.value.location == null) {
      print('❌ Localização não disponível para corrida ${order.id}');
      return false;
    }

    double distance = _calculateDistance(
      driverModel.value.location!.latitude!,
      driverModel.value.location!.longitude!,
      order.sourceLocationLAtLng!.latitude!,
      order.sourceLocationLAtLng!.longitude!,
    );

    if (distance > MAX_ASSIGNMENT_RADIUS) {
      print('❌ Corrida ${order.id} muito distante: ${distance.toStringAsFixed(2)}km');
      return false;
    }

    print('✅ Corrida ${order.id} elegível - distância: ${distance.toStringAsFixed(2)}km');
    return true;
  }

  /// Processa nova corrida
  Future<void> _processNewOrder(OrderModel order) async {
    // Marca como processando para evitar duplicatas
    isProcessingOrder.value = true;

    try {
      print('⚙️ Processando corrida: ${order.id}');

      // Espera um pouco para evitar condições de corrida
      await Future.delayed(const Duration(milliseconds: 200));

      // Verifica novamente o estado
      if (isShowingModal.value || currentAssignedRide.value != null) {
        print('⚠️ Estado mudou durante processamento - cancelando');
        return;
      }

      await assignRideToDriver(order);

    } catch (e) {
      print('❌ Erro ao processar corrida: $e');
    } finally {
      // Libera o processamento após um delay
      Future.delayed(const Duration(milliseconds: 500), () {
        isProcessingOrder.value = false;
      });
    }
  }

  /// Atribui corrida ao motorista e mostra modal
  Future<void> assignRideToDriver(OrderModel ride) async {
    try {
      print('🎯 Atribuindo corrida ${ride.id} ao motorista');

      // Verifica estado final antes de atribuir
      if (isShowingModal.value || currentAssignedRide.value != null) {
        print('⚠️ Estado inválido para atribuição - cancelando');
        return;
      }

      // Marca corrida como atribuída no Firestore primeiro
      await FireStoreUtils.fireStore
          .collection(CollectionName.orders)
          .doc(ride.id)
          .update({
        'assignedDriverId': FireStoreUtils.getCurrentUid(),
        'assignedAt': Timestamp.now(),
      });

      // Define corrida atual
      currentAssignedRide.value = ride;

      // Mostra modal de atribuição
      showRideAssignmentModal(ride);

      // Inicia timer de timeout
      startResponseTimer();

      print('✅ Corrida ${ride.id} atribuída com sucesso');

    } catch (e) {
      print('❌ Erro ao atribuir corrida: $e');
      // Se houve erro, limpa o estado
      _clearCurrentAssignment();
    }
  }

  /// Mostra modal de atribuição de corrida
  void showRideAssignmentModal(OrderModel ride) {
    // Verificação dupla para evitar múltiplos modais
    if (isShowingModal.value) {
      print('⚠️ Modal já está sendo exibido, ignorando nova solicitação');
      return;
    }

    isShowingModal.value = true;
    print('📱 Exibindo modal para corrida ${ride.id}');

    Get.dialog(
      WillPopScope(
        onWillPop: () async => false, // Impede fechar com botão voltar
        child: RideAssignmentModal(
          orderModel: ride,
          onAccept: () => acceptAssignedRide(),
          onReject: () => rejectAssignedRide(),
        ),
      ),
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.8),
    ).then((_) {
      print('📱 Modal fechado para corrida ${ride.id}');
      // Quando o modal for fechado, garante que o estado seja limpo
      if (isShowingModal.value) {
        _clearCurrentAssignment();
      }
    });
  }

  /// Inicia timer para timeout de resposta
  void startResponseTimer() {
    responseTimer?.cancel();

    responseTimer = Timer(const Duration(seconds: ASSIGNMENT_TIMEOUT), () {
      if (isShowingModal.value && currentAssignedRide.value != null) {
        print('⏰ Timeout - rejeitando automaticamente corrida ${currentAssignedRide.value!.id}');
        rejectAssignedRide();
      }
    });
  }

  /// Aceita a corrida atribuída (usando o fluxo original do sistema)
  Future<void> acceptAssignedRide() async {
    if (currentAssignedRide.value == null || !isShowingModal.value) {
      print('⚠️ Não há corrida para aceitar');
      return;
    }

    try {
      print('✅ Aceitando corrida ${currentAssignedRide.value!.id}');
      ShowToastDialog.showLoader("Aceitando corrida...".tr);

      OrderModel orderModel = currentAssignedRide.value!;

      // FLUXO ORIGINAL: Atualiza lista de acceptedDriverId
      List<dynamic> newAcceptedDriverId = [];
      if (orderModel.acceptedDriverId != null) {
        newAcceptedDriverId = orderModel.acceptedDriverId!;
      } else {
        newAcceptedDriverId = [];
      }
      newAcceptedDriverId.add(FireStoreUtils.getCurrentUid());
      orderModel.acceptedDriverId = newAcceptedDriverId;

      // FLUXO ORIGINAL: Salva o pedido atualizado
      await FireStoreUtils.setOrder(orderModel);

      // FLUXO ORIGINAL: Notifica passageiro
      await FireStoreUtils.getCustomer(orderModel.userId.toString()).then((value) async {
        if (value != null) {
          await SendNotification.sendOneNotification(
              token: value.fcmToken.toString(),
              title: 'Corrida aceita'.tr,
              body: 'Motorista aceitou sua corrida. 🚗'.tr,
              payload: {});
        }
      });

      // FLUXO ORIGINAL: Cria registro de aceitação
      DriverIdAcceptReject driverIdAcceptReject = DriverIdAcceptReject(
          driverId: FireStoreUtils.getCurrentUid(),
          acceptedRejectTime: Timestamp.now(),
          offerAmount: orderModel.offerRate ?? "0");

      // FLUXO ORIGINAL: Aceita a corrida usando o método original
      await FireStoreUtils.acceptRide(orderModel, driverIdAcceptReject);

      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Oferta enviada! Aguardando resposta do passageiro...".tr);

      print('✅ Oferta de corrida ${orderModel.id} enviada com sucesso');

      // NOVA FUNCIONALIDADE: Inicia monitoramento da resposta do passageiro
      _startPassengerResponseMonitoring(orderModel);

      // Limpa o modal atual mas mantém estado para monitoramento
      _clearModalOnly();

    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Erro ao aceitar corrida".tr);
      print('❌ Erro ao aceitar corrida: $e');
      _clearCurrentAssignment();
    }
  }

  /// Rejeita a corrida atribuída
  Future<void> rejectAssignedRide() async {
    if (currentAssignedRide.value == null) {
      print('⚠️ Não há corrida para rejeitar');
      return;
    }

    try {
      print('❌ Rejeitando corrida ${currentAssignedRide.value!.id}');
      OrderModel ride = currentAssignedRide.value!;

      // Remove atribuição da corrida
      await FireStoreUtils.fireStore
          .collection(CollectionName.orders)
          .doc(ride.id)
          .update({
        'assignedDriverId': FieldValue.delete(),
        'rejectedDriverIds': FieldValue.arrayUnion([FireStoreUtils.getCurrentUid()]),
      });

      print('✅ Corrida ${ride.id} rejeitada com sucesso');

      // Limpa estado
      _clearCurrentAssignment();

    } catch (e) {
      print('❌ Erro ao rejeitar corrida: $e');
      _clearCurrentAssignment();
    }
  }

  /// Limpa atribuição atual
  void _clearCurrentAssignment() {
    print('🧹 Limpando estado da corrida atual');

    // Cancela timer primeiro
    responseTimer?.cancel();
    passengerResponseTimeout?.cancel();
    passengerResponseListener?.cancel();

    // Limpa variáveis de estado
    currentAssignedRide.value = null;
    isWaitingPassengerResponse.value = false;

    // Fecha modal se estiver aberto
    if (isShowingModal.value) {
      isShowingModal.value = false;

      // Só tenta fechar o dialog se realmente estiver aberto
      if (Get.isDialogOpen == true) {
        try {
          Get.back();
        } catch (e) {
          print('⚠️ Erro ao fechar dialog: $e');
        }
      }
    }

    // Libera processamento
    isProcessingOrder.value = false;

    print('🧹 Estado limpo - pronto para nova corrida');
  }

  /// Limpa apenas o modal mantendo o monitoramento ativo
  void _clearModalOnly() {
    print('📱 Fechando modal mas mantendo monitoramento');

    // Cancela apenas timers do modal
    responseTimer?.cancel();

    // Fecha modal
    if (isShowingModal.value) {
      isShowingModal.value = false;

      if (Get.isDialogOpen == true) {
        try {
          Get.back();
        } catch (e) {
          print('⚠️ Erro ao fechar dialog: $e');
        }
      }
    }

    // Libera processamento de novas corridas
    isProcessingOrder.value = false;
  }

  /// Inicia monitoramento da resposta do passageiro
  void _startPassengerResponseMonitoring(OrderModel order) {
    if (isWaitingPassengerResponse.value) {
      print('⚠️ Já está aguardando resposta de passageiro');
      return;
    }

    isWaitingPassengerResponse.value = true;
    print('👀 Iniciando monitoramento de resposta para corrida ${order.id}');

    // Mostra loading de espera
    _showWaitingPassengerDialog(order);

    // Monitora mudanças na corrida
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

      // Verifica se passageiro aceitou (driverId definido)
      if (updatedOrder.driverId == FireStoreUtils.getCurrentUid()) {
        _handlePassengerResponse('ACCEPTED', updatedOrder, 'Passageiro aceitou sua oferta!');
      }
      // Verifica se passageiro rejeitou (motorista removido da lista)
      else if (updatedOrder.acceptedDriverId?.contains(FireStoreUtils.getCurrentUid()) == false) {
        _handlePassengerResponse('REJECTED', updatedOrder, 'Passageiro rejeitou sua oferta');
      }
      // Verifica se outro motorista foi escolhido
      else if (updatedOrder.driverId != null && updatedOrder.driverId != FireStoreUtils.getCurrentUid()) {
        _handlePassengerResponse('REJECTED', updatedOrder, 'Passageiro escolheu outro motorista');
      }
    });

    // Timeout de 5 minutos para resposta do passageiro
    passengerResponseTimeout = Timer(const Duration(minutes: 5), () {
      if (isWaitingPassengerResponse.value) {
        _handlePassengerResponse('TIMEOUT', order, 'Tempo limite para resposta do passageiro esgotado');
      }
    });
  }

  /// Mostra dialog de espera da resposta do passageiro
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
                  'Aguardando Passageiro',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sua oferta foi enviada para o passageiro.',
                style: GoogleFonts.poppins(),
              ),
              const SizedBox(height: 10),
              Text(
                'Aguardando confirmação...',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 15),
              LinearProgressIndicator(
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => _cancelWaitingForPassenger(order),
              child: Text(
                'Cancelar',
                style: GoogleFonts.poppins(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// Processa resposta do passageiro
  void _handlePassengerResponse(String responseType, OrderModel order, String message) {
    print('📨 Resposta do passageiro: $responseType para corrida ${order.id}');

    // Para o monitoramento
    passengerResponseListener?.cancel();
    passengerResponseTimeout?.cancel();
    isWaitingPassengerResponse.value = false;

    // Fecha dialog de espera se estiver aberto
    if (Get.isDialogOpen == true) {
      Get.back();
    }

    // Processa baseado na resposta
    switch (responseType) {
      case 'ACCEPTED':
        ShowToastDialog.showToast('✅ $message'.tr);
        // Navega para corrida ativa ou atualiza interface
        _onRideAcceptedByPassenger(order);
        break;

      case 'REJECTED':
      case 'TIMEOUT':
      case 'CANCELLED':
        ShowToastDialog.showToast('❌ $message'.tr);
        break;
    }

    // Limpa estado completamente
    _clearCurrentAssignment();
  }

  /// Cancela espera pela resposta do passageiro
  void _cancelWaitingForPassenger(OrderModel order) {
    try {
      // Remove motorista da lista de aceitos
      List<dynamic> acceptedDrivers = List.from(order.acceptedDriverId ?? []);
      acceptedDrivers.remove(FireStoreUtils.getCurrentUid());

      FireStoreUtils.fireStore
          .collection(CollectionName.orders)
          .doc(order.id)
          .update({
        'acceptedDriverId': acceptedDrivers,
      });

      _handlePassengerResponse('CANCELLED', order, 'Oferta cancelada pelo motorista');

    } catch (e) {
      print('❌ Erro ao cancelar oferta: $e');
      _clearCurrentAssignment();
    }
  }

  /// Chamado quando passageiro aceita a corrida
  void _onRideAcceptedByPassenger(OrderModel order) {
    // Aqui pode implementar navegação específica ou atualização de estado
    print('🎉 Corrida ${order.id} confirmada pelo passageiro!');

    // Exemplo: navegar para tela de corrida ativa
    // Get.to(() => ActiveRideScreen(order: order));
  }

  /// Navega para a tela da corrida ativa
  void _navigateToActiveRide(OrderModel ride) {
    try {
      // Primeiro, vai para o dashboard principal
      if (Get.currentRoute != '/DashBoardScreen') {
        Get.offAll(() => const DashBoardScreen());
      }

      // Aguarda um momento para garantir que a navegação foi concluída
      Future.delayed(const Duration(milliseconds: 800), () {
        // Navega para a aba de corridas ativas (índice 0)
        if (Get.isRegistered<HomeController>()) {
          HomeController homeController = Get.find<HomeController>();
          homeController.selectedIndex.value = 0; // Aba "Active Orders"
          print('🏠 Navegou para aba de corridas ativas');
        }

        // Se estiver usando mapas in-app, navega diretamente para LiveTracking
        if (Constant.mapType == "inappmap") {
          Future.delayed(const Duration(milliseconds: 500), () {
            Get.to(() => const LiveTrackingScreen(), arguments: {
              "orderModel": ride,
              "type": "orderModel",
            });
            print('🗺️ Navegou para LiveTrackingScreen');
          });
        } else {
          // Para mapas externos, apenas mostra toast
          ShowToastDialog.showToast("Corrida aceita! Verifique a aba 'Ativo'".tr);
        }
      });

      print('🧭 Navegação para corrida ativa configurada');
    } catch (e) {
      print('❌ Erro na navegação: $e');
      // Fallback: apenas navega para dashboard
      Get.offAll(() => const DashBoardScreen());
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

  /// Alterna status online/offline do motorista (método principal)
  Future<void> toggleOnlineStatus() async {
    try {
      bool newStatus = !isOnline.value;

      // Atualiza no Firestore
      await FireStoreUtils.fireStore
          .collection(CollectionName.driverUsers)
          .doc(FireStoreUtils.getCurrentUid())
          .update({
        'isOnline': newStatus,
      });

      // Atualiza localmente
      isOnline.value = newStatus;
      driverModel.value.isOnline = newStatus;

      if (newStatus && driverModel.value.location != null) {
        // Ficou online - inicia listeners
        startRealTimeOrderListener();
        print('✅ Motorista ficou ONLINE');
      } else {
        // Ficou offline - para sistema
        stopOrderListener();
        _clearCurrentAssignment();
        print('❌ Motorista ficou OFFLINE');
      }

    } catch (e) {
      print('❌ Erro ao alterar status online: $e');
    }
  }

  /// Método para controle programático do status (compatibilidade)
  Future<void> setOnlineStatus(bool online) async {
    if (online != isOnline.value) {
      await toggleOnlineStatus();
    }
  }

  /// Método para verificar corridas disponíveis manualmente (compatibilidade)
  Future<void> checkForAvailableRides() async {
    if (!isOnline.value || isShowingModal.value || currentAssignedRide.value != null) {
      print('⚠️ Não é possível verificar corridas agora');
      return;
    }

    try {
      print('🔍 Verificando corridas disponíveis manualmente...');

      QuerySnapshot snapshot = await FireStoreUtils.fireStore
          .collection(CollectionName.orders)
          .where('status', isEqualTo: Constant.ridePlaced)
          .where('serviceId', isEqualTo: driverModel.value.serviceId)
          .get();

      List<OrderModel> availableRides = [];

      for (var doc in snapshot.docs) {
        try {
          OrderModel order = OrderModel.fromJson(doc.data() as Map<String, dynamic>);
          if (_isOrderEligibleForDriver(order)) {
            availableRides.add(order);
          }
        } catch (e) {
          print('❌ Erro ao processar corrida: $e');
        }
      }

      if (availableRides.isNotEmpty) {
        // Seleciona a melhor corrida
        OrderModel? selectedRide = selectBestRideForDriver(availableRides);
        if (selectedRide != null) {
          await _processNewOrder(selectedRide);
        }
      } else {
        print('📭 Nenhuma corrida disponível encontrada');
      }

    } catch (e) {
      print('❌ Erro ao verificar corridas disponíveis: $e');
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

  /// Inicia o listener para atribuição automática (compatibilidade)
  void startAutoAssignmentListener() {
    startRealTimeOrderListener();
  }

  /// Para o sistema de atribuição automática
  void stopAutoAssignmentListener() {
    stopOrderListener();
    _clearCurrentAssignment();
  }

  /// Getter para compatibilidade com código existente
  bool get hasCurrentRide => currentAssignedRide.value != null;

  /// Getter para obter corrida atual
  OrderModel? get getCurrentRide => currentAssignedRide.value;

  /// Método para forçar limpeza (para debug)
  void forceCleanState() {
    print('🔧 Forçando limpeza de estado...');
    _clearCurrentAssignment();
    stopOrderListener();
    isProcessingOrder.value = false;
  }

  /// Método para reiniciar o sistema
  void restartSystem() {
    print('🔄 Reiniciando sistema de atribuição...');
    forceCleanState();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (isOnline.value && driverModel.value.location != null) {
        startRealTimeOrderListener();
      }
    });
  }

  /// Método para verificar status do sistema
  Map<String, dynamic> getSystemStatus() {
    return {
      'isOnline': isOnline.value,
      'isShowingModal': isShowingModal.value,
      'isProcessingOrder': isProcessingOrder.value,
      'hasCurrentRide': hasCurrentRide,
      'currentRideId': currentAssignedRide.value?.id,
      'hasActiveTimer': responseTimer?.isActive ?? false,
      'hasActiveListener': orderStreamSubscription != null,
      'driverLocation': driverModel.value.location != null,
    };
  }

  /// Inicializa dados do motorista (compatibilidade)
  void initDriver() {
    initializeDriver();
  }

  /// Para o listener de atribuição automática (compatibilidade)
  void stopAutoAssignment() {
    stopOrderListener();
    _clearCurrentAssignment();
  }

  /// Inicia o listener de atribuição automática (compatibilidade)
  void startAutoAssignment() {
    if (isOnline.value && driverModel.value.location != null) {
      startRealTimeOrderListener();
    }
  }

  /// Obtém a corrida atual atribuída
  OrderModel? getCurrentAssignedRide() {
    return currentAssignedRide.value;
  }

  /// Verifica se há uma corrida atribuída atualmente
  bool hasAssignedRide() {
    return currentAssignedRide.value != null;
  }

  /// Verifica se o modal está sendo exibido
  bool isModalShowing() {
    return isShowingModal.value;
  }

  /// Obtém o status online do motorista
  bool get driverOnlineStatus => isOnline.value;

  /// Define o status online do motorista (usado externamente)
  set driverOnlineStatus(bool status) {
    if (status != isOnline.value) {
      toggleOnlineStatus();
    }
  }

  /// Limpa o estado atual (usado para debug)
  void clearCurrentState() {
    _clearCurrentAssignment();
  }

  /// Força a verificação de novas corridas
  void forceCheckRides() {
    checkForAvailableRides();
  }

  /// Método para aceitar uma corrida externamente (se necessário)
  Future<void> acceptRide() async {
    await acceptAssignedRide();
  }

  /// Método para rejeitar uma corrida externamente (se necessário)
  Future<void> rejectRide() async {
    await rejectAssignedRide();
  }

  /// Obtém informações do motorista
  DriverUserModel get driver => driverModel.value;

  /// Verifica se o sistema está ativo
  bool get isSystemActive =>
      isOnline.value &&
          driverModel.value.location != null &&
          orderStreamSubscription != null;

  /// Obtém tempo restante do timer (em segundos)
  int get remainingTime {
    if (responseTimer?.isActive ?? false) {
      return ASSIGNMENT_TIMEOUT; // Simplificado - retorna o timeout padrão
    }
    return 0;
  }
}