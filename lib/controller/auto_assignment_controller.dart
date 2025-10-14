// lib/controller/auto_assignment_controller.dart - VERSÃO COM VALIDAÇÕES COMPLETAS
import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/constant/collection_name.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/send_notification.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/model/driver_document_model.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/model/document_model.dart';
import 'package:driver/model/order/driverId_accept_reject.dart';
import 'package:driver/model/order_model.dart';
import 'package:driver/model/user_model.dart';
import 'package:driver/ui/dashboard_screen.dart';
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
  RxBool isWaitingPassengerResponse = false.obs;

  // Listeners
  StreamSubscription? driverListener;
  StreamSubscription? orderStreamSubscription;
  StreamSubscription? activeRideListener;
  StreamSubscription? passengerResponseListener;

  // Timers
  Timer? autoRejectTimer;
  Timer? passengerResponseTimeout;

  // Constantes
  static const int AUTO_REJECT_SECONDS = 30;
  static const int PASSENGER_RESPONSE_TIMEOUT = 60;

  @override
  void onInit() {
    super.onInit();
    startDriverListener();
  }

  @override
  void onClose() {
    stopAllListeners();
    super.onClose();
  }

  /// ====================================================================
  /// VALIDAÇÕES DE DOCUMENTOS E VEÍCULO
  /// ====================================================================

  /// Verifica se o motorista pode ficar online
  Future<Map<String, dynamic>> canGoOnline() async {
    try {
      // 1. Busca dados atualizados do motorista
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

      // 2. Verifica se tem informações do veículo cadastradas
      if (driver.vehicleInformation == null) {
        return {
          'canGoOnline': false,
          'reason': 'Você precisa cadastrar as informações do seu veículo',
          'action': 'goto_vehicle_screen',
          'title': 'Cadastro Incompleto'
        };
      }

      // 3. Verifica se campos obrigatórios do veículo estão preenchidos
      if (driver.vehicleInformation!.vehicleNumber == null ||
          driver.vehicleInformation!.vehicleNumber!.isEmpty) {
        return {
          'canGoOnline': false,
          'reason': 'Complete o cadastro do veículo com placa, cor e modelo',
          'action': 'goto_vehicle_screen',
          'title': 'Informações do Veículo Incompletas'
        };
      }

      // 4. Busca lista de documentos obrigatórios
      List<DocumentModel> requiredDocuments = await FireStoreUtils.getDocumentList();

      if (requiredDocuments.isEmpty) {
        return {
          'canGoOnline': false,
          'reason': 'Não foi possível verificar os documentos necessários',
          'action': 'retry'
        };
      }

      // 5. Busca documentos enviados pelo motorista
      DriverDocumentModel? driverDocuments = await FireStoreUtils.getDocumentOfDriver();

      if (driverDocuments == null || driverDocuments.documents == null ||
          driverDocuments.documents!.isEmpty) {
        return {
          'canGoOnline': false,
          'reason': 'Você precisa enviar seus documentos obrigatórios',
          'action': 'goto_documents_screen',
          'title': 'Documentos Não Enviados',
          'missingCount': requiredDocuments.length
        };
      }

      // 6. Verifica quais documentos estão faltando ou não aprovados
      List<String> missingDocuments = [];
      List<String> pendingDocuments = [];

      for (DocumentModel requiredDoc in requiredDocuments) {
        // Procura o documento enviado
        var uploadedDoc = driverDocuments.documents!.firstWhereOrNull(
                (doc) => doc.documentId == requiredDoc.id
        );

        if (uploadedDoc == null) {
          // Documento não foi enviado
          missingDocuments.add(requiredDoc.title ?? 'Documento');
        } else if (uploadedDoc.verified != true) {
          // Documento foi enviado mas não está aprovado
          pendingDocuments.add(requiredDoc.title ?? 'Documento');
        }
      }

      // 7. Se tem documentos faltando
      if (missingDocuments.isNotEmpty) {
        String docList = missingDocuments.join(', ');
        return {
          'canGoOnline': false,
          'reason': 'Documentos não enviados: $docList',
          'action': 'goto_documents_screen',
          'title': 'Documentos Faltando',
          'missingDocs': missingDocuments
        };
      }

      // 8. Se tem documentos pendentes de aprovação
      if (pendingDocuments.isNotEmpty) {
        String docList = pendingDocuments.join(', ');
        return {
          'canGoOnline': false,
          'reason': 'Documentos aguardando aprovação: $docList\n\nSeus documentos estão em análise. Aguarde a aprovação do administrador.',
          'action': 'none',
          'title': 'Documentos em Análise',
          'pendingDocs': pendingDocuments
        };
      }

      // 9. Tudo OK! Pode ficar online
      return {
        'canGoOnline': true,
        'reason': 'Motorista habilitado',
      };

    } catch (e) {
      log('Erro ao verificar se pode ficar online: $e');
      return {
        'canGoOnline': false,
        'reason': 'Erro ao verificar requisitos: $e',
        'action': 'retry'
      };
    }
  }

  /// Mostra diálogo explicativo com botões de ação
  void showValidationDialog(Map<String, dynamic> validation) {
    Get.dialog(
      WillPopScope(
        onWillPop: () async => true,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 30,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  validation['title'] ?? 'Atenção',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                validation['reason'] ?? '',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              // Se tem documentos específicos faltando, lista eles
              if (validation['missingDocs'] != null) ...[
                SizedBox(height: 15),
                Text(
                  'Documentos necessários:',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 5),
                ...((validation['missingDocs'] as List<String>).map(
                      (doc) => Padding(
                    padding: EdgeInsets.only(left: 10, top: 3),
                    child: Row(
                      children: [
                        Icon(Icons.circle, size: 6, color: Colors.grey),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            doc,
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
              ],

              // Se tem documentos pendentes, lista eles
              if (validation['pendingDocs'] != null) ...[
                SizedBox(height: 15),
                Text(
                  'Documentos em análise:',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 5),
                ...((validation['pendingDocs'] as List<String>).map(
                      (doc) => Padding(
                    padding: EdgeInsets.only(left: 10, top: 3),
                    child: Row(
                      children: [
                        Icon(Icons.schedule, size: 14, color: Colors.orange),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            doc,
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
              ],
            ],
          ),
          actions: [
            // Botão Fechar
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                'Fechar',
                style: GoogleFonts.poppins(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Botão de Ação
            if (validation['action'] == 'goto_documents_screen')
              ElevatedButton(
                onPressed: () {
                  Get.back();
                  Get.to(() => const OnlineRegistrationScreen());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Enviar Documentos',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Cadastrar Veículo',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
      barrierDismissible: true,
    );
  }

  /// ====================================================================
  /// CONTROLE DE STATUS ONLINE/OFFLINE (COM VALIDAÇÕES)
  /// ====================================================================

  /// Alterna status online/offline
  Future<void> toggleOnlineStatus() async {
    try {
      bool newStatus = !isOnline.value;

      // Se tentando ficar ONLINE, valida requisitos
      if (newStatus) {
        // 1. Verifica se tem corrida ativa
        bool activeRide = await hasActiveRide();
        if (activeRide) {
          ShowToastDialog.showToast(
              "Complete sua corrida ativa antes de ficar online novamente"
          );
          return;
        }

        // 2. Verifica documentos e veículo
        Map<String, dynamic> validation = await canGoOnline();

        if (!validation['canGoOnline']) {
          // Não pode ficar online - mostra o motivo
          log('❌ NÃO PODE FICAR ONLINE: ${validation['reason']}');
          showValidationDialog(validation);
          return;
        }

        log('✅ VALIDAÇÃO OK - Motorista pode ficar online');
      }

      // Atualiza o status no Firebase
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

  /// ====================================================================
  /// LISTENER DO MOTORISTA
  /// ====================================================================

  void startDriverListener() {
    log('👀 INICIANDO LISTENER DO MOTORISTA');

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

        print('🔧 Status motorista: ${isOnline.value ? "ONLINE" : "OFFLINE"}');

        if (isOnline.value && !wasOnline) {
          print('🟢 MOTORISTA FICOU ONLINE');
          startActiveRideMonitoring();

          hasActiveRide().then((hasActive) {
            if (!hasActive && driverModel.value.location != null) {
              startRealTimeOrderListener();
            } else if (hasActive) {
              print('🚫 Não iniciando listener: motorista já tem corrida ativa');
            }
          });

        } else if (!isOnline.value && wasOnline) {
          print('🔴 MOTORISTA FICOU OFFLINE');
          stopOrderListener();
          forceCleanState();
        }
      }
    });
  }

  // ... [RESTO DO CÓDIGO DO CONTROLLER PERMANECE IGUAL]
  // Mantenha todos os outros métodos existentes como:
  // - startRealTimeOrderListener()
  // - processNewOrder()
  // - acceptRide()
  // - rejectRide()
  // - hasActiveRide()
  // - etc.

  void stopAllListeners() {
    driverListener?.cancel();
    orderStreamSubscription?.cancel();
    activeRideListener?.cancel();
    passengerResponseListener?.cancel();
    autoRejectTimer?.cancel();
    passengerResponseTimeout?.cancel();
  }

  void forceCleanState() {
    isProcessingOrder.value = false;
    isShowingModal.value = false;
    isWaitingPassengerResponse.value = false;
    currentAssignedRide.value = null;
    autoRejectTimer?.cancel();
    passengerResponseTimeout?.cancel();

    if (Get.isDialogOpen == true) {
      Get.back();
    }
  }

  // Placeholder para hasActiveRide - mantenha a implementação existente
  Future<bool> hasActiveRide() async {
    try {
      var snapshot = await FireStoreUtils.fireStore
          .collection(CollectionName.orders)
          .where('driverId', isEqualTo: FireStoreUtils.getCurrentUid())
          .where('status', whereIn: [Constant.rideActive, Constant.rideInProgress])
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Erro ao verificar corrida ativa: $e');
      return false;
    }
  }

  void startActiveRideMonitoring() {
    // Implementação existente
  }

  void startRealTimeOrderListener() {
    // Implementação existente
  }

  void stopOrderListener() {
    orderStreamSubscription?.cancel();
    orderStreamSubscription = null;
  }

  void checkForAvailableRides() {
    // Implementação existente
  }
}