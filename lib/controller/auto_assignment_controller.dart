// lib/controller/auto_assignment_controller.dart - VERSÃO COMPLETA COM POPUP
import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/constant/collection_name.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/model/driver_document_model.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/model/document_model.dart';
import 'package:driver/model/order_model.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/ui/online_registration/online_registartion_screen.dart';
import 'package:driver/ui/vehicle_information/vehicle_information_screen.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:driver/widget/ride_assignment_modal.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class AutoAssignmentController extends GetxController {
  static AutoAssignmentController get instance => Get.find<AutoAssignmentController>();

  // Status e observáveis
  RxBool isOnline = false.obs;
  Rx<DriverUserModel> driverModel = DriverUserModel().obs;
  Rx<OrderModel?> currentAssignedRide = Rx<OrderModel?>(null);

  // Controles de processamento
  RxBool isProcessingOrder = false.obs;
  RxBool isShowingModal = false.obs;

  // Listeners
  StreamSubscription? driverListener;
  StreamSubscription? orderStreamSubscription;
  StreamSubscription? activeRideListener;

  // Timers
  Timer? autoRejectTimer;

  // Constantes
  static const int AUTO_REJECT_SECONDS = 60;

  @override
  void onInit() {
    super.onInit();
    print('🚀 AutoAssignmentController iniciado');
    startDriverListener();
  }

  @override
  void onClose() {
    print('🔴 AutoAssignmentController fechado');
    stopAllListeners();
    super.onClose();
  }

  // ========================================================================
  // VALIDAÇÕES
  // ========================================================================

  Future<Map<String, dynamic>> canGoOnline() async {
    try {
      DriverUserModel? driver = await FireStoreUtils.getDriverProfile(
          FireStoreUtils.getCurrentUid()
      );

      if (driver == null) {
        return {
          'canGoOnline': false,
          'reason': 'Erro ao carregar dados do motorista',
          'action': 'retry'
        };
      }

      // Verifica veículo
      if (driver.vehicleInformation == null) {
        return {
          'canGoOnline': false,
          'reason': 'Você precisa cadastrar as informações do seu veículo',
          'action': 'goto_vehicle_screen',
          'title': 'Cadastro Incompleto'
        };
      }

      // Verifica documentos
      List<DocumentModel> requiredDocuments = await FireStoreUtils.getDocumentList();
      DriverDocumentModel? driverDocuments = await FireStoreUtils.getDocumentOfDriver();

      if (driverDocuments == null || driverDocuments.documents == null) {
        return {
          'canGoOnline': false,
          'reason': 'Você precisa enviar seus documentos obrigatórios',
          'action': 'goto_documents_screen',
          'title': 'Documentos Não Enviados'
        };
      }

      // Verifica documentos pendentes
      for (var requiredDoc in requiredDocuments) {
        var uploadedDoc = driverDocuments.documents!.firstWhereOrNull(
                (doc) => doc.documentId == requiredDoc.id
        );

        if (uploadedDoc == null) {
          return {
            'canGoOnline': false,
            'reason': 'Documento "${requiredDoc.title}" não enviado',
            'action': 'goto_documents_screen',
            'title': 'Documentos Faltando'
          };
        }

        if (uploadedDoc.verified != true) {
          return {
            'canGoOnline': false,
            'reason': 'Seus documentos estão em análise. Aguarde aprovação do administrador.',
            'action': 'none',
            'title': 'Documentos em Análise'
          };
        }
      }

      return {
        'canGoOnline': true,
        'reason': 'Motorista qualificado',
      };

    } catch (e) {
      log('Erro ao verificar requisitos: $e');
      return {
        'canGoOnline': false,
        'reason': 'Erro ao verificar requisitos: $e',
        'action': 'retry'
      };
    }
  }

  // ========================================================================
  // TOGGLE ONLINE/OFFLINE
  // ========================================================================

  Future<void> toggleOnlineStatus() async {
    try {
      bool newStatus = !isOnline.value;

      if (newStatus) {
        // Verifica se tem corrida ativa
        bool activeRide = await hasActiveRide();
        if (activeRide) {
          ShowToastDialog.showToast(
              "Complete sua corrida ativa antes de ficar online novamente"
          );
          return;
        }

        // Valida requisitos
        Map<String, dynamic> validation = await canGoOnline();

        if (!validation['canGoOnline']) {
          log('❌ NÃO PODE FICAR ONLINE: ${validation['reason']}');
          showValidationDialog(validation);
          return;
        }

        log('✅ VALIDAÇÃO OK - Motorista pode ficar online');
      }

      // Atualiza status no Firebase
      await FireStoreUtils.fireStore
          .collection(CollectionName.driverUsers)
          .doc(FireStoreUtils.getCurrentUid())
          .update({'isOnline': newStatus});

      log('🔄 STATUS ALTERADO PARA: ${newStatus ? "ONLINE" : "OFFLINE"}');

      String message = newStatus
          ? "Você está ONLINE e receberá corridas"
          : "Você está OFFLINE e não receberá corridas";

      ShowToastDialog.showToast(message);

    } catch (e) {
      log('Erro ao alternar status: $e');
      ShowToastDialog.showToast("Erro ao alterar status: $e");
    }
  }

  void showValidationDialog(Map<String, dynamic> validation) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.darkContainerBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 30),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                validation['title'] ?? 'Atenção',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          validation['reason'] ?? '',
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Fechar', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          if (validation['action'] == 'goto_documents_screen')
            ElevatedButton(
              onPressed: () {
                Get.back();
                Get.to(() => const OnlineRegistrationScreen());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'Enviar Documentos',
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            )
          else if (validation['action'] == 'goto_vehicle_screen')
            ElevatedButton(
              onPressed: () {
                Get.back();
                Get.to(() => const VehicleInformationScreen());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'Cadastrar Veículo',
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  // ========================================================================
  // LISTENER DO MOTORISTA
  // ========================================================================

  void startDriverListener() {
    log('👀 ========================================');
    log('👀 INICIANDO LISTENER DO MOTORISTA');
    log('👀 ========================================');

    driverListener?.cancel();

    driverListener = FireStoreUtils.fireStore
        .collection(CollectionName.driverUsers)
        .doc(FireStoreUtils.getCurrentUid())
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        driverModel.value = DriverUserModel.fromJson(snapshot.data()!);
        bool wasOnline = isOnline.value;
        isOnline.value = driverModel.value.isOnline ?? false;

        log('🔧 Status motorista: ${isOnline.value ? "ONLINE" : "OFFLINE"}');

        if (isOnline.value && !wasOnline) {
          log('🟢 ========================================');
          log('🟢 MOTORISTA FICOU ONLINE');
          log('🟢 ========================================');

          startActiveRideMonitoring();

          hasActiveRide().then((hasActive) {
            if (!hasActive && driverModel.value.location != null) {
              log('🔄 Iniciando listener de corridas disponíveis...');
              startRealTimeOrderListener();
            } else if (hasActive) {
              log('🚫 Não iniciando listener: motorista já tem corrida ativa');
            } else {
              log('⚠️ Localização do motorista não disponível');
            }
          });

        } else if (!isOnline.value && wasOnline) {
          log('🔴 ========================================');
          log('🔴 MOTORISTA FICOU OFFLINE');
          log('🔴 ========================================');
          stopOrderListener();
          forceCleanState();
        }
      }
    });
  }

  // ========================================================================
  // LISTENER DE CORRIDAS DISPONÍVEIS
  // ========================================================================

  void startRealTimeOrderListener() {
    log('🎯 ========================================');
    log('🎯 INICIANDO LISTENER DE CORRIDAS');
    log('🎯 ========================================');

    stopOrderListener();

    if (driverModel.value.serviceId == null) {
      log('❌ ServiceId não definido - não pode buscar corridas');
      return;
    }

    // Stream de corridas atribuídas ao motorista
    orderStreamSubscription = FireStoreUtils.fireStore
        .collection(CollectionName.orders)
        .where('assignedDriverId', isEqualTo: FireStoreUtils.getCurrentUid())
        .where('status', isEqualTo: Constant.ridePlaced)
        .snapshots()
        .listen(
          (snapshot) {
        log('📨 Snapshot recebido: ${snapshot.docs.length} corridas atribuídas');

        for (var doc in snapshot.docs) {
          try {
            OrderModel order = OrderModel.fromJson(doc.data());

            log('🔔 Nova corrida atribuída detectada:');
            log('   ID: ${order.id}');
            log('   De: ${order.sourceLocationName}');
            log('   Para: ${order.destinationLocationName}');
            log('   Valor: R\$ ${order.offerRate}');

            // Verifica se já não está processando
            if (!isProcessingOrder.value && !isShowingModal.value) {
              processNewOrder(order);
            } else {
              log('⏭️ Já processando outra corrida, ignorando esta');
            }
          } catch (e) {
            log('❌ Erro ao processar documento: $e');
          }
        }
      },
      onError: (error) {
        log('❌ Erro no listener de corridas: $error');
      },
    );

    log('✅ Listener de corridas iniciado com sucesso');
  }

  void stopOrderListener() {
    log('🔒 Parando listener de corridas');
    orderStreamSubscription?.cancel();
    orderStreamSubscription = null;
  }

  // ========================================================================
  // PROCESSAMENTO DE NOVA CORRIDA
  // ========================================================================

  void processNewOrder(OrderModel order) {
    log('');
    log('⚡ ========================================');
    log('⚡ PROCESSANDO NOVA CORRIDA');
    log('⚡ ========================================');
    log('⚡ ID: ${order.id}');
    log('⚡ De: ${order.sourceLocationName}');
    log('⚡ Para: ${order.destinationLocationName}');
    log('⚡ Valor: R\$ ${order.offerRate}');
    log('⚡ ========================================');
    log('');

    isProcessingOrder.value = true;
    currentAssignedRide.value = order;

    // Mostra o modal
    showRideAssignmentModal(order);

    // Timer de auto-rejeição
    startAutoRejectTimer(order.id!);
  }

  // ========================================================================
  // MODAL DE ATRIBUIÇÃO
  // ========================================================================

  void showRideAssignmentModal(OrderModel order) {
    if (isShowingModal.value) {
      log('⏭️ Já existe um modal aberto, não abrindo outro');
      return;
    }

    log('🎨 ========================================');
    log('🎨 MOSTRANDO MODAL DE ATRIBUIÇÃO');
    log('🎨 ========================================');

    isShowingModal.value = true;

    Get.dialog(
      RideAssignmentModal(
        orderModel: order,
        onAccept: () => acceptRide(order.id!),
        onReject: () => rejectRide(order.id!),
      ),
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.8),
    ).then((_) {
      log('🎨 Modal fechado');
      isShowingModal.value = false;
      isProcessingOrder.value = false;
      currentAssignedRide.value = null;
      autoRejectTimer?.cancel();
    });
  }

  // ========================================================================
  // TIMER DE AUTO-REJEIÇÃO
  // ========================================================================

  void startAutoRejectTimer(String orderId) {
    log('⏰ Timer de auto-rejeição iniciado (${AUTO_REJECT_SECONDS}s)');

    autoRejectTimer?.cancel();

    autoRejectTimer = Timer(Duration(seconds: AUTO_REJECT_SECONDS), () {
      log('⏰ TEMPO ESGOTADO - Rejeitando automaticamente');

      if (isShowingModal.value) {
        rejectRide(orderId);
      }
    });
  }

  // ========================================================================
  // ACEITAR CORRIDA
  // ========================================================================

  Future<void> acceptRide(String orderId) async {
    log('');
    log('✅ ========================================');
    log('✅ ACEITANDO CORRIDA');
    log('✅ ========================================');
    log('✅ Order ID: $orderId');

    try {
      autoRejectTimer?.cancel();

      if (Get.isDialogOpen == true) {
        Get.back();
      }

      ShowToastDialog.showLoader("Aceitando corrida...");

      // Aceita a corrida no Firebase
      bool success = await FireStoreUtils.acceptAssignedRide(
        orderId,
        FireStoreUtils.getCurrentUid(),
      );

      ShowToastDialog.closeLoader();

      if (success) {
        log('✅ Corrida aceita com sucesso!');
        ShowToastDialog.showToast("Corrida aceita com sucesso!");

        forceCleanState();

        // Navega para tela da corrida ativa (opcional)
        // Get.to(() => LiveTrackingScreen(), arguments: {'orderId': orderId});
      } else {
        log('❌ Falha ao aceitar corrida');
        ShowToastDialog.showToast("Erro ao aceitar corrida");
        forceCleanState();
      }

    } catch (e) {
      log('❌ Erro ao aceitar corrida: $e');
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Erro ao aceitar corrida: $e");
      forceCleanState();
    }

    log('✅ ========================================');
    log('');
  }

  // ========================================================================
  // REJEITAR CORRIDA
  // ========================================================================

  Future<void> rejectRide(String orderId) async {
    log('');
    log('❌ ========================================');
    log('❌ REJEITANDO CORRIDA');
    log('❌ ========================================');
    log('❌ Order ID: $orderId');

    try {
      autoRejectTimer?.cancel();

      if (Get.isDialogOpen == true) {
        Get.back();
      }

      ShowToastDialog.showLoader("Rejeitando corrida...");

      // Rejeita a corrida no Firebase
      bool success = await FireStoreUtils.rejectAssignedRide(
        orderId,
        FireStoreUtils.getCurrentUid(),
      );

      ShowToastDialog.closeLoader();

      if (success) {
        log('✅ Corrida rejeitada com sucesso!');
        ShowToastDialog.showToast("Corrida rejeitada");
        forceCleanState();
      } else {
        log('❌ Falha ao rejeitar corrida');
        ShowToastDialog.showToast("Erro ao rejeitar corrida");
        forceCleanState();
      }

    } catch (e) {
      log('❌ Erro ao rejeitar corrida: $e');
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Erro ao rejeitar corrida: $e");
      forceCleanState();
    }

    log('❌ ========================================');
    log('');
  }

  // ========================================================================
  // VERIFICAR CORRIDA ATIVA
  // ========================================================================

  Future<bool> hasActiveRide() async {
    try {
      var snapshot = await FireStoreUtils.fireStore
          .collection(CollectionName.orders)
          .where('driverId', isEqualTo: FireStoreUtils.getCurrentUid())
          .where('status', whereIn: [Constant.rideActive, Constant.rideInProgress])
          .limit(1)
          .get();

      bool hasActive = snapshot.docs.isNotEmpty;
      log('🔍 Tem corrida ativa? $hasActive');
      return hasActive;
    } catch (e) {
      log('❌ Erro ao verificar corrida ativa: $e');
      return false;
    }
  }

  // ========================================================================
  // MONITORAMENTO DE CORRIDA ATIVA
  // ========================================================================

  void startActiveRideMonitoring() {
    log('👁️ Iniciando monitoramento de corrida ativa');

    activeRideListener?.cancel();

    activeRideListener = FireStoreUtils.fireStore
        .collection(CollectionName.orders)
        .where('driverId', isEqualTo: FireStoreUtils.getCurrentUid())
        .where('status', whereIn: [Constant.rideActive, Constant.rideInProgress])
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        log('🚗 Motorista tem corrida ativa - parando listener de novas corridas');
        stopOrderListener();
      } else {
        log('🆓 Motorista livre - pode receber novas corridas');
        if (isOnline.value && orderStreamSubscription == null) {
          startRealTimeOrderListener();
        }
      }
    });
  }

  // ========================================================================
  // LIMPEZA E UTILITÁRIOS
  // ========================================================================

  void stopAllListeners() {
    log('🧹 Parando todos os listeners');
    driverListener?.cancel();
    orderStreamSubscription?.cancel();
    activeRideListener?.cancel();
    autoRejectTimer?.cancel();
  }

  void forceCleanState() {
    log('🧹 Limpando estado do controller');
    isProcessingOrder.value = false;
    isShowingModal.value = false;
    currentAssignedRide.value = null;
    autoRejectTimer?.cancel();

    if (Get.isDialogOpen == true) {
      Get.back();
    }
  }

  void checkForAvailableRides() {
    log('🔄 Verificando corridas disponíveis manualmente');

    if (!isOnline.value) {
      log('⚠️ Motorista offline, não verificando corridas');
      return;
    }

    hasActiveRide().then((hasActive) {
      if (!hasActive) {
        log('✅ Sem corrida ativa, reiniciando listener');
        startRealTimeOrderListener();
      } else {
        log('⚠️ Tem corrida ativa, não verificando novas');
      }
    });
  }
}