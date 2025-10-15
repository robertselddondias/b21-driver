// lib/utils/fire_store_utils.dart - VERSÃO COMPLETA CORRIGIDA
import 'dart:async';
import 'dart:developer';
import 'dart:math' hide log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/constant/collection_name.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/model/bank_details_model.dart';
import 'package:driver/model/conversation_model.dart';
import 'package:driver/model/currency_model.dart';
import 'package:driver/model/document_model.dart';
import 'package:driver/model/driver_document_model.dart';
import 'package:driver/model/driver_rules_model.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/model/inbox_model.dart';
import 'package:driver/model/intercity_order_model.dart';
import 'package:driver/model/language_model.dart';
import 'package:driver/model/on_boarding_model.dart';
import 'package:driver/model/order/driverId_accept_reject.dart';
import 'package:driver/model/order_model.dart';
import 'package:driver/model/payment_model.dart';
import 'package:driver/model/referral_model.dart';
import 'package:driver/model/review_model.dart';
import 'package:driver/model/service_model.dart';
import 'package:driver/model/user_model.dart';
import 'package:driver/model/vehicle_type_model.dart';
import 'package:driver/model/wallet_transaction_model.dart';
import 'package:driver/model/withdraw_model.dart';
import 'package:driver/model/zone_model.dart';
import 'package:driver/widget/geoflutterfire/src/geoflutterfire.dart';
import 'package:driver/widget/geoflutterfire/src/models/point.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class FireStoreUtils {
  static FirebaseFirestore fireStore = FirebaseFirestore.instance;

  // ============================================================================
  // AUTENTICAÇÃO E VALIDAÇÃO
  // ============================================================================

  static Future<bool> isLogin() async {
    bool isLogin = false;
    if (FirebaseAuth.instance.currentUser != null) {
      isLogin = await userExitOrNot(FirebaseAuth.instance.currentUser!.uid);
    } else {
      isLogin = false;
    }
    return isLogin;
  }

  static String getCurrentUid() {
    return FirebaseAuth.instance.currentUser!.uid;
  }

  static Future<bool> userExitOrNot(String uid) async {
    bool isExit = false;
    await fireStore.collection(CollectionName.driverUsers).doc(uid).get().then(
          (value) {
        if (value.exists) {
          isExit = true;
        } else {
          isExit = false;
        }
      },
    ).catchError((error) {
      log("Failed to update user: $error");
      isExit = false;
    });
    return isExit;
  }

  // ============================================================================
  // CONFIGURAÇÕES GLOBAIS
  // ============================================================================

  getGoogleAPIKey() async {
    await fireStore.collection(CollectionName.settings).doc("globalKey").get().then((value) {
      if (value.exists) {
        Constant.mapAPIKey = value.data()!["googleMapKey"];
      }
    });

    await fireStore.collection(CollectionName.settings).doc("notification_setting").get().then((value) {
      if (value.exists) {
        if (value.data() != null) {
          Constant.senderId = value.data()!['senderId'].toString();
          Constant.jsonNotificationFileURL = value.data()!['serviceJson'].toString();
        }
      }
    });

    await fireStore.collection(CollectionName.settings).doc("globalValue").get().then((value) {
      if (value.exists) {
        Constant.distanceType = value.data()!["distanceType"];
        Constant.radius = value.data()!["radius"];
        Constant.minimumAmountToWithdrawal = value.data()!["minimumAmountToWithdrawal"];
        Constant.minimumDepositToRideAccept = value.data()!["minimumDepositToRideAccept"];
        Constant.mapType = value.data()!["mapType"];
        Constant.selectedMapType = value.data()!["selectedMapType"];
        Constant.driverLocationUpdate = value.data()!["driverLocationUpdate"];
      }
    });

    await fireStore.collection(CollectionName.settings).doc("referral").get().then((value) {
      if (value.exists) {
        Constant.referralAmount = value.data()!["referralAmount"];
      }
    });

    await fireStore.collection(CollectionName.settings).doc("global").get().then((value) {
      if (value.exists) {
        Constant.termsAndConditions = value.data()!["termsAndConditions"];
        Constant.privacyPolicy = value.data()!["privacyPolicy"];
        Constant.appVersion = value.data()!["appVersion"];
      }
    });

    await fireStore.collection(CollectionName.settings).doc("contact_us").get().then((value) {
      if (value.exists) {
        Constant.supportURL = value.data()!["supportURL"];
      }
    });
  }

  Future<CurrencyModel?> getCurrency() async {
    CurrencyModel? currencyModel;
    await fireStore.collection(CollectionName.currency).where("enable", isEqualTo: true).get().then((value) {
      if (value.docs.isNotEmpty) {
        currencyModel = CurrencyModel.fromJson(value.docs.first.data());
      }
    });
    return currencyModel;
  }

  Future<PaymentModel?> getPayment() async {
    PaymentModel? paymentModel;
    await fireStore.collection(CollectionName.settings).doc("payment").get().then((value) {
      paymentModel = PaymentModel.fromJson(value.data()!);
    });
    return paymentModel;
  }

  // ============================================================================
  // GERENCIAMENTO DE MOTORISTAS
  // ============================================================================

  static Future<DriverUserModel?> getDriverProfile(String uuid) async {
    DriverUserModel? driverModel;
    await fireStore.collection(CollectionName.driverUsers).doc(uuid).get().then((value) {
      if (value.exists) {
        driverModel = DriverUserModel.fromJson(value.data()!);
      }
    }).catchError((error) {
      log("Failed to update user: $error");
      driverModel = null;
    });
    return driverModel;
  }

  static Future<bool> updateDriverUser(DriverUserModel userModel) async {
    bool isUpdate = false;
    await fireStore.collection(CollectionName.driverUsers).doc(userModel.id).set(userModel.toJson()).whenComplete(() {
      isUpdate = true;
    }).catchError((error) {
      log("Failed to update user: $error");
      isUpdate = false;
    });
    return isUpdate;
  }

  static Future<bool?> deleteUser() async {
    bool? isDelete;
    try {
      await fireStore.collection(CollectionName.driverUsers).doc(FireStoreUtils.getCurrentUid()).delete();
      await FirebaseAuth.instance.currentUser!.delete().then((value) {
        isDelete = true;
      });
    } catch (e, s) {
      log('FireStoreUtils.firebaseCreateNewUser $e $s');
      return false;
    }
    return isDelete;
  }

  // ============================================================================
  // GERENCIAMENTO DE CLIENTES/USUÁRIOS
  // ============================================================================

  static Future<UserModel?> getCustomer(String uuid) async {
    UserModel? userModel;
    await fireStore.collection(CollectionName.users).doc(uuid).get().then((value) {
      if (value.exists) {
        userModel = UserModel.fromJson(value.data()!);
      }
    }).catchError((error) {
      log("Failed to update user: $error");
      userModel = null;
    });
    return userModel;
  }

  static Future<bool> updateUser(UserModel userModel) async {
    bool isUpdate = false;
    await fireStore.collection(CollectionName.users).doc(userModel.id).set(userModel.toJson()).whenComplete(() {
      isUpdate = true;
    }).catchError((error) {
      log("Failed to update user: $error");
      isUpdate = false;
    });
    return isUpdate;
  }

  // ============================================================================
  // BUSCA DE CORRIDAS - CORRIGIDA
  // ============================================================================

  StreamController<List<OrderModel>>? getNearestOrderRequestController;

  Stream<List<OrderModel>> getOrders(
      DriverUserModel driverUserModel,
      double? latitude,
      double? longitude
      ) async* {

    print('🔍 ========================================');
    print('🔍 INICIANDO getOrders()');
    print('🔍 ========================================');
    print('📍 Latitude: $latitude, Longitude: $longitude');
    print('🚗 ServiceId: ${driverUserModel.serviceId}');
    print('📍 ZoneIds: ${driverUserModel.zoneIds}');
    print('🌍 Raio de busca: ${Constant.radius}km');
    print('🔍 ========================================');

    // Fecha stream anterior se existir
    if (getNearestOrderRequestController != null) {
      getNearestOrderRequestController!.close();
      getNearestOrderRequestController = null;
    }

    getNearestOrderRequestController = StreamController<List<OrderModel>>.broadcast();

    try {
      // ========================================================================
      // VALIDAÇÕES INICIAIS
      // ========================================================================

      // Validação de localização
      if (latitude == null || longitude == null || latitude == 0.0 || longitude == 0.0) {
        print('❌ ERRO: Localização inválida!');
        print('   Latitude: $latitude, Longitude: $longitude');
        getNearestOrderRequestController!.sink.add([]);
        yield* getNearestOrderRequestController!.stream;
        return;
      }

      // Validação de serviceId
      if (driverUserModel.serviceId == null || driverUserModel.serviceId!.isEmpty) {
        print('❌ ERRO: ServiceId não definido!');
        getNearestOrderRequestController!.sink.add([]);
        yield* getNearestOrderRequestController!.stream;
        return;
      }

      // ========================================================================
      // CONSTRUÇÃO DA QUERY
      // ========================================================================

      Query<Map<String, dynamic>> query = fireStore
          .collection(CollectionName.orders)
          .where('serviceId', isEqualTo: driverUserModel.serviceId)
          .where('status', isEqualTo: Constant.ridePlaced);

      // Adiciona filtro de zona APENAS se o motorista tiver zonas definidas
      if (driverUserModel.zoneIds != null && driverUserModel.zoneIds!.isNotEmpty) {
        print('🗺️ Aplicando filtro de zonas: ${driverUserModel.zoneIds}');
        query = query.where('zoneId', whereIn: driverUserModel.zoneIds);
      } else {
        print('⚠️ Motorista sem zonas definidas - buscando todas as corridas do serviço');
      }

      // ========================================================================
      // CONFIGURAÇÃO DO GEOFLUTTERFIRE
      // ========================================================================

      GeoFirePoint center = Geoflutterfire().point(
          latitude: latitude,
          longitude: longitude
      );

      print('📍 Centro de busca configurado: lat=$latitude, lng=$longitude');
      print('🔄 Iniciando stream GeoFlutterFire...');

      // Stream de corridas próximas
      Stream<List<DocumentSnapshot>> stream = Geoflutterfire()
          .collection(collectionRef: query)
          .within(
          center: center,
          radius: double.parse(Constant.radius),
          field: 'position',
          strictMode: false  // IMPORTANTE: false para não perder corridas nas bordas
      );

      // ========================================================================
      // LISTENER DO STREAM COM LÓGICA CORRIGIDA
      // ========================================================================

      stream.listen(
            (List<DocumentSnapshot> documentList) {
          print('');
          print('📦 ========================================');
          print('📦 DOCUMENTOS RECEBIDOS DO FIREBASE');
          print('📦 ========================================');
          print('📦 Total de documentos: ${documentList.length}');

          List<OrderModel> ordersList = [];
          String currentDriverId = FireStoreUtils.getCurrentUid();

          for (int i = 0; i < documentList.length; i++) {
            try {
              var document = documentList[i];
              final data = document.data() as Map<String, dynamic>;
              OrderModel orderModel = OrderModel.fromJson(data);

              print('');
              print('📋 ----------------------------------------');
              print('📋 ANALISANDO CORRIDA ${i + 1}/${documentList.length}');
              print('📋 ----------------------------------------');
              print('   ID: ${orderModel.id}');
              print('   Status: ${orderModel.status}');
              print('   ServiceId: ${orderModel.serviceId}');
              print('   ZoneId: ${orderModel.zoneId}');
              print('   DriverId atual: ${orderModel.driverId ?? "null"}');
              print('   AssignedDriverId: ${orderModel.assignedDriverId ?? "null"}');
              print('   RejectedDriverIds: ${orderModel.rejectedDriverIds ?? []}');
              print('   Origem: ${orderModel.sourceLocationName}');
              print('   Destino: ${orderModel.destinationLocationName}');

              // Calcula distância
              if (orderModel.sourceLocationLAtLng != null) {
                double distance = Geolocator.distanceBetween(
                  latitude,
                  longitude,
                  orderModel.sourceLocationLAtLng!.latitude ?? 0.0,
                  orderModel.sourceLocationLAtLng!.longitude ?? 0.0,
                ) / 1000; // Converte para km

                print('   Distância: ${distance.toStringAsFixed(2)}km');
              }

              // ================================================================
              // LÓGICA CORRIGIDA DE FILTRAGEM
              // ================================================================

              // FILTRO 1: Se já tem motorista atribuído E não sou eu, pular
              if (orderModel.driverId != null &&
                  orderModel.driverId!.isNotEmpty &&
                  orderModel.driverId != currentDriverId) {
                print('   ⏭️ REJEITADA: Já tem outro motorista atribuído (${orderModel.driverId})');
                continue;
              }

              // FILTRO 2: Se estou na lista de rejeitados, pular
              if (orderModel.rejectedDriverIds != null &&
                  orderModel.rejectedDriverIds!.contains(currentDriverId)) {
                print('   ⏭️ REJEITADA: Você já rejeitou esta corrida anteriormente');
                continue;
              }

              // FILTRO 3: Se o status não é "Ride Placed", pular
              if (orderModel.status != Constant.ridePlaced) {
                print('   ⏭️ REJEITADA: Status inválido (${orderModel.status})');
                continue;
              }

              // CORREÇÃO PRINCIPAL: 
              // NÃO filtrar por acceptedDriverId!
              // acceptedDriverId é uma LISTA de motoristas que OFERECERAM, 
              // não que aceitaram a corrida

              // ================================================================
              // CORRIDA VÁLIDA - ADICIONAR À LISTA
              // ================================================================

              print('   ✅ CORRIDA VÁLIDA - Adicionando à lista');
              ordersList.add(orderModel);

            } catch (e, stackTrace) {
              print('❌ ERRO ao processar documento: $e');
              print('Stack trace: $stackTrace');
            }
          }

          print('');
          print('✅ ========================================');
          print('✅ RESULTADO FINAL DA FILTRAGEM');
          print('✅ ========================================');
          print('✅ Total de corridas válidas: ${ordersList.length}');
          print('✅ ========================================');
          print('');

          // ====================================================================
          // ORDENAÇÃO POR DISTÂNCIA (MAIS PRÓXIMAS PRIMEIRO)
          // ====================================================================

          if (ordersList.isNotEmpty) {
            print('🔄 Ordenando corridas por distância...');

            ordersList.sort((a, b) {
              if (a.sourceLocationLAtLng == null || b.sourceLocationLAtLng == null) {
                return 0;
              }

              double distA = Geolocator.distanceBetween(
                  latitude,
                  longitude,
                  a.sourceLocationLAtLng!.latitude ?? 0.0,
                  a.sourceLocationLAtLng!.longitude ?? 0.0
              );

              double distB = Geolocator.distanceBetween(
                  latitude,
                  longitude,
                  b.sourceLocationLAtLng!.latitude ?? 0.0,
                  b.sourceLocationLAtLng!.longitude ?? 0.0
              );

              return distA.compareTo(distB);
            });

            print('✅ Corridas ordenadas por distância');

            // Log das corridas finais
            for (int i = 0; i < ordersList.length; i++) {
              var order = ordersList[i];
              if (order.sourceLocationLAtLng != null) {
                double dist = Geolocator.distanceBetween(
                  latitude,
                  longitude,
                  order.sourceLocationLAtLng!.latitude ?? 0.0,
                  order.sourceLocationLAtLng!.longitude ?? 0.0,
                ) / 1000;
                print('   ${i + 1}. ${order.sourceLocationName} → ${order.destinationLocationName} (${dist.toStringAsFixed(2)}km)');
              }
            }
          }

          // Envia lista para o stream
          getNearestOrderRequestController!.sink.add(ordersList);
        },
        onError: (error) {
          print('');
          print('❌ ========================================');
          print('❌ ERRO NO STREAM');
          print('❌ ========================================');
          print('❌ $error');
          print('❌ ========================================');
          print('');
          getNearestOrderRequestController!.sink.addError(error);
        },
        onDone: () {
          print('✅ Stream finalizado normalmente');
        },
        cancelOnError: false,
      );

    } catch (e, stackTrace) {
      print('');
      print('❌ ========================================');
      print('❌ ERRO CRÍTICO em getOrders');
      print('❌ ========================================');
      print('❌ Erro: $e');
      print('❌ Stack trace: $stackTrace');
      print('❌ ========================================');
      print('');
      getNearestOrderRequestController!.sink.addError(e);
    }

    yield* getNearestOrderRequestController!.stream;
  }

  // ============================================================================
  // MÉTODO AUXILIAR: Fechar o stream
  // ============================================================================

  void closeStream() {
    print('🔒 Fechando stream de corridas');
    if (getNearestOrderRequestController != null) {
      getNearestOrderRequestController!.close();
      getNearestOrderRequestController = null;
    }
  }

  // ============================================================================
  // BUSCA DE CORRIDAS INTERCITY/FREIGHT
  // ============================================================================

  StreamController<List<InterCityOrderModel>>? getNearestFreightOrderRequestController;

  Stream<List<InterCityOrderModel>> getFreightOrders(double? latitude, double? longitude) async* {
    getNearestFreightOrderRequestController = StreamController<List<InterCityOrderModel>>.broadcast();
    List<InterCityOrderModel> ordersList = [];

    Query<Map<String, dynamic>> query = fireStore
        .collection(CollectionName.ordersIntercity)
        .where('intercityServiceId', isEqualTo: "Kn2VEnPI3ikF58uK8YqY")
        .where('status', isEqualTo: Constant.ridePlaced);

    GeoFirePoint center = Geoflutterfire().point(latitude: latitude ?? 0.0, longitude: longitude ?? 0.0);

    Stream<List<DocumentSnapshot>> stream = Geoflutterfire()
        .collection(collectionRef: query)
        .within(center: center, radius: double.parse(Constant.radius), field: 'position', strictMode: false);

    stream.listen((List<DocumentSnapshot> documentList) {
      ordersList.clear();
      for (var document in documentList) {
        final data = document.data() as Map<String, dynamic>;
        InterCityOrderModel orderModel = InterCityOrderModel.fromJson(data);

        if (orderModel.acceptedDriverId != null && orderModel.acceptedDriverId!.isNotEmpty) {
          if (!orderModel.acceptedDriverId!.contains(FireStoreUtils.getCurrentUid())) {
            ordersList.add(orderModel);
          }
        } else {
          ordersList.add(orderModel);
        }
      }
      getNearestFreightOrderRequestController!.sink.add(ordersList);
    });

    yield* getNearestFreightOrderRequestController!.stream;
  }

  void closeFreightStream() {
    if (getNearestFreightOrderRequestController != null) {
      getNearestFreightOrderRequestController!.close();
      getNearestFreightOrderRequestController = null;
    }
  }

  // ============================================================================
  // GERENCIAMENTO DE PEDIDOS/CORRIDAS
  // ============================================================================

  static Future<OrderModel?> getOrder(String orderId) async {
    OrderModel? orderModel;
    await fireStore.collection(CollectionName.orders).doc(orderId).get().then((value) {
      if (value.data() != null) {
        orderModel = OrderModel.fromJson(value.data()!);
      }
    });
    return orderModel;
  }

  static Future<InterCityOrderModel?> getInterCityOrder(String orderId) async {
    InterCityOrderModel? orderModel;
    await fireStore.collection(CollectionName.ordersIntercity).doc(orderId).get().then((value) {
      if (value.data() != null) {
        orderModel = InterCityOrderModel.fromJson(value.data()!);
      }
    });
    return orderModel;
  }

  static Future<bool?> setOrder(OrderModel orderModel) async {
    bool isAdded = false;
    await fireStore.collection(CollectionName.orders).doc(orderModel.id).update(orderModel.toJson()).then((value) {
      isAdded = true;
    }).catchError((error) {
      log("Failed to update order: $error");
      isAdded = false;
    });
    return isAdded;
  }

  static Future<bool?> setInterCityOrder(InterCityOrderModel orderModel) async {
    bool isAdded = false;
    await fireStore.collection(CollectionName.ordersIntercity).doc(orderModel.id).set(orderModel.toJson()).then((value) {
      isAdded = true;
    }).catchError((error) {
      log("Failed to update order: $error");
      isAdded = false;
    });
    return isAdded;
  }

  // ============================================================================
  // DRIVER ACCEPT/REJECT
  // ============================================================================

  static Future<DriverIdAcceptReject?> getAcceptedOrders(String orderId, String driverId) async {
    DriverIdAcceptReject? driverIdAcceptReject;
    await fireStore
        .collection(CollectionName.orders)
        .doc(orderId)
        .collection("acceptedDriver")
        .doc(driverId)
        .get()
        .then((value) async {
      if (value.exists) {
        driverIdAcceptReject = DriverIdAcceptReject.fromJson(value.data()!);
      }
    }).catchError((error) {
      log("Failed to get accepted orders: $error");
      driverIdAcceptReject = null;
    });
    return driverIdAcceptReject;
  }

  static Future<DriverIdAcceptReject?> getInterCityAcceptedOrders(String orderId, String driverId) async {
    DriverIdAcceptReject? driverIdAcceptReject;
    await fireStore
        .collection(CollectionName.ordersIntercity)
        .doc(orderId)
        .collection("acceptedDriver")
        .doc(driverId)
        .get()
        .then((value) async {
      if (value.exists) {
        driverIdAcceptReject = DriverIdAcceptReject.fromJson(value.data()!);
      }
    }).catchError((error) {
      log("Failed to get accepted orders: $error");
      driverIdAcceptReject = null;
    });
    return driverIdAcceptReject;
  }

  // ============================================================================
  // DOCUMENTOS
  // ============================================================================

  static Future<List<DocumentModel>> getDocumentList() async {
    List<DocumentModel> documentList = [];
    await fireStore
        .collection(CollectionName.documents)
        .where('enable', isEqualTo: true)
        .where('isDeleted', isEqualTo: false)
        .get()
        .then((value) {
      for (var element in value.docs) {
        DocumentModel documentModel = DocumentModel.fromJson(element.data());
        documentList.add(documentModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return documentList;
  }

  static Future<DriverDocumentModel?> getDocumentOfDriver() async {
    DriverDocumentModel? driverDocumentModel;
    await fireStore
        .collection(CollectionName.driverDocument)
        .doc(getCurrentUid())
        .get()
        .then((value) async {
      if (value.exists) {
        driverDocumentModel = DriverDocumentModel.fromJson(value.data()!);
      }
    });
    return driverDocumentModel;
  }

  static Future<bool> uploadDriverDocument(Documents documents) async {
    bool isAdded = false;
    DriverDocumentModel driverDocumentModel = DriverDocumentModel();
    List<Documents> documentsList = [];

    await fireStore
        .collection(CollectionName.driverDocument)
        .doc(getCurrentUid())
        .get()
        .then((value) async {
      if (value.exists) {
        DriverDocumentModel newDriverDocumentModel = DriverDocumentModel.fromJson(value.data()!);
        documentsList = newDriverDocumentModel.documents!;

        var contain = newDriverDocumentModel.documents!.where((element) =>
        element.documentId == documents.documentId
        );

        if (contain.isEmpty) {
          documentsList.add(documents);
          driverDocumentModel.id = getCurrentUid();
          driverDocumentModel.documents = documentsList;
        } else {
          var index = newDriverDocumentModel.documents!.indexWhere((element) =>
          element.documentId == documents.documentId
          );

          driverDocumentModel.id = getCurrentUid();
          documentsList.removeAt(index);
          documentsList.insert(index, documents);
          driverDocumentModel.documents = documentsList;
          isAdded = false;
          ShowToastDialog.showToast("Document is under verification");
        }
      } else {
        documentsList.add(documents);
        driverDocumentModel.id = getCurrentUid();
        driverDocumentModel.documents = documentsList;
      }
    });

    await fireStore
        .collection(CollectionName.driverDocument)
        .doc(getCurrentUid())
        .set(driverDocumentModel.toJson())
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      isAdded = false;
      log(error.toString());
    });

    return isAdded;
  }

  // ============================================================================
  // SERVIÇOS, VEÍCULOS E REGRAS
  // ============================================================================

  static Future<List<ServiceModel>> getService() async {
    List<ServiceModel> serviceList = [];
    await fireStore
        .collection(CollectionName.service)
        .where('enable', isEqualTo: true)
        .get()
        .then((value) {
      for (var element in value.docs) {
        ServiceModel documentModel = ServiceModel.fromJson(element.data());
        serviceList.add(documentModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return serviceList;
  }

  static Future<List<VehicleTypeModel>?> getVehicleType() async {
    List<VehicleTypeModel> vehicleList = [];
    await fireStore
        .collection(CollectionName.vehicleType)
        .where('enable', isEqualTo: true)
        .get()
        .then((value) async {
      for (var element in value.docs) {
        VehicleTypeModel vehicleModel = VehicleTypeModel.fromJson(element.data());
        vehicleList.add(vehicleModel);
      }
    });
    return vehicleList;
  }

  static Future<List<DriverRulesModel>?> getDriverRules() async {
    List<DriverRulesModel> driverRulesModel = [];
    await fireStore
        .collection(CollectionName.driverRules)
        .where('enable', isEqualTo: true)
        .where('isDeleted', isEqualTo: false)
        .get()
        .then((value) async {
      for (var element in value.docs) {
        DriverRulesModel vehicleModel = DriverRulesModel.fromJson(element.data());
        driverRulesModel.add(vehicleModel);
      }
    });
    return driverRulesModel;
  }

  // ============================================================================
  // ZONAS
  // ============================================================================

  static Future<List<ZoneModel>?> getZone() async {
    List<ZoneModel> zoneList = [];
    await fireStore
        .collection(CollectionName.zone)
        .where('publish', isEqualTo: true)
        .get()
        .then((value) {
      for (var element in value.docs) {
        ZoneModel zoneModel = ZoneModel.fromJson(element.data());
        zoneList.add(zoneModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return zoneList;
  }

  // ============================================================================
  // CARTEIRA E TRANSAÇÕES
  // ============================================================================

  static Future<List<WalletTransactionModel>?> getWalletTransaction() async {
    List<WalletTransactionModel> walletTransactionModel = [];
    await fireStore
        .collection(CollectionName.walletTransaction)
        .where('userId', isEqualTo: getCurrentUid())
        .orderBy('createdDate', descending: true)
        .get()
        .then((value) {
      for (var element in value.docs) {
        WalletTransactionModel taxModel = WalletTransactionModel.fromJson(element.data());
        walletTransactionModel.add(taxModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return walletTransactionModel;
  }

  static Future<bool?> setWalletTransaction(WalletTransactionModel walletTransactionModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.walletTransaction)
        .doc(walletTransactionModel.id)
        .set(walletTransactionModel.toJson())
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      log("Failed to set wallet transaction: $error");
      isAdded = false;
    });
    return isAdded;
  }

  static Future<bool?> updatedDriverWallet({required String amount}) async {
    bool isAdded = false;
    await getDriverProfile(FireStoreUtils.getCurrentUid()).then((value) async {
      if (value != null) {
        DriverUserModel userModel = value;
        userModel.walletAmount = (double.parse(userModel.walletAmount.toString()) + double.parse(amount)).toString();
        await FireStoreUtils.updateDriverUser(userModel).then((value) {
          isAdded = value;
        });
      }
    });
    return isAdded;
  }

  // ============================================================================
  // DADOS BANCÁRIOS
  // ============================================================================

  static Future<BankDetailsModel?> getBankDetails() async {
    BankDetailsModel? bankDetailsModel;
    await fireStore
        .collection(CollectionName.bankDetails)
        .doc(FireStoreUtils.getCurrentUid())
        .get()
        .then((value) {
      if (value.data() != null) {
        bankDetailsModel = BankDetailsModel.fromJson(value.data()!);
      }
    });
    return bankDetailsModel;
  }

  static Future<bool?> updateBankDetails(BankDetailsModel bankDetailsModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.bankDetails)
        .doc(bankDetailsModel.userId)
        .set(bankDetailsModel.toJson())
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      log("Failed to update bank details: $error");
      isAdded = false;
    });
    return isAdded;
  }

  static Future<bool?> bankDetailsIsAvailable() async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.bankDetails)
        .doc(FireStoreUtils.getCurrentUid())
        .get()
        .then((value) {
      if (value.exists) {
        isAdded = true;
      } else {
        isAdded = false;
      }
    }).catchError((error) {
      log("Failed to check bank details: $error");
      isAdded = false;
    });
    return isAdded;
  }

  // ============================================================================
  // SAQUES
  // ============================================================================

  static Future<bool?> setWithdrawRequest(WithdrawModel withdrawModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.withdrawalHistory)
        .doc(withdrawModel.id)
        .set(withdrawModel.toJson())
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      log("Failed to set withdraw request: $error");
      isAdded = false;
    });
    return isAdded;
  }

  static Future<List<WithdrawModel>> getWithDrawRequest() async {
    List<WithdrawModel> withdrawalList = [];
    await fireStore
        .collection(CollectionName.withdrawalHistory)
        .where('userId', isEqualTo: getCurrentUid())
        .orderBy('createdDate', descending: true)
        .get()
        .then((value) {
      for (var element in value.docs) {
        WithdrawModel documentModel = WithdrawModel.fromJson(element.data());
        withdrawalList.add(documentModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return withdrawalList;
  }

  // ============================================================================
  // AVALIAÇÕES
  // ============================================================================

  static Future<ReviewModel?> getReview(String orderId) async {
    ReviewModel? reviewModel;
    await fireStore
        .collection(CollectionName.reviewCustomer)
        .where('id', isEqualTo: orderId)
        .get()
        .then((value) {
      if (value.docs.isNotEmpty) {
        reviewModel = ReviewModel.fromJson(value.docs.first.data());
      }
    });
    return reviewModel;
  }

  static Future<bool?> setReview(ReviewModel reviewModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.reviewCustomer)
        .doc(reviewModel.id)
        .set(reviewModel.toJson())
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      log("Failed to set review: $error");
      isAdded = false;
    });
    return isAdded;
  }

  // ============================================================================
  // CHAT E MENSAGENS
  // ============================================================================

  static Future addInBox(InboxModel inboxModel) async {
    return await fireStore
        .collection(CollectionName.chat)
        .doc(inboxModel.orderId)
        .set(inboxModel.toJson())
        .then((document) {
      return inboxModel;
    });
  }

  static Future addChat(ConversationModel conversationModel) async {
    return await fireStore
        .collection(CollectionName.chat)
        .doc(conversationModel.orderId)
        .collection("thread")
        .doc(conversationModel.id)
        .set(conversationModel.toJson())
        .then((document) {
      return conversationModel;
    });
  }

  // ============================================================================
  // IDIOMAS E ONBOARDING
  // ============================================================================

  static Future<List<LanguageModel>?> getLanguage() async {
    List<LanguageModel> languageList = [];
    await fireStore
        .collection(CollectionName.languages)
        .get()
        .then((value) {
      for (var element in value.docs) {
        LanguageModel languageModel = LanguageModel.fromJson(element.data());
        languageList.add(languageModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return languageList;
  }

  static Future<List<OnBoardingModel>> getOnBoardingList() async {
    List<OnBoardingModel> onBoardingModel = [];
    await fireStore
        .collection(CollectionName.onBoarding)
        .where("type", isEqualTo: "driverApp")
        .get()
        .then((value) {
      for (var element in value.docs) {
        OnBoardingModel documentModel = OnBoardingModel.fromJson(element.data());
        onBoardingModel.add(documentModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return onBoardingModel;
  }

  // ============================================================================
  // REFERRAL E PRIMEIRA CORRIDA
  // ============================================================================

  static Future<bool> getFirestOrderOrNOt(OrderModel orderModel) async {
    bool isFirst = true;
    await fireStore
        .collection(CollectionName.orders)
        .where('userId', isEqualTo: orderModel.userId)
        .get()
        .then((value) {
      if (value.size == 1) {
        isFirst = true;
      } else {
        isFirst = false;
      }
    });
    return isFirst;
  }

  static Future updateReferralAmount(OrderModel orderModel) async {
    ReferralModel? referralModel;
    await fireStore
        .collection(CollectionName.referral)
        .doc(orderModel.userId)
        .get()
        .then((value) {
      if (value.data() != null) {
        referralModel = ReferralModel.fromJson(value.data()!);
      } else {
        return;
      }
    });

    if (referralModel != null) {
      if (referralModel!.referralBy != null && referralModel!.referralBy!.isNotEmpty) {
        await fireStore
            .collection(CollectionName.users)
            .doc(referralModel!.referralBy)
            .get()
            .then((value) async {
          DocumentSnapshot<Map<String, dynamic>> userDocument = value;
          if (userDocument.data() != null && userDocument.exists) {
            try {
              UserModel user = UserModel.fromJson(userDocument.data()!);
              user.walletAmount = (double.parse(user.walletAmount.toString()) +
                  double.parse(Constant.referralAmount.toString())).toString();
              updateUser(user);

              WalletTransactionModel transactionModel = WalletTransactionModel(
                id: Constant.getUuid(),
                amount: Constant.referralAmount.toString(),
                createdDate: Timestamp.now(),
                paymentType: "Wallet",
                transactionId: orderModel.id,
                userId: orderModel.driverId.toString(),
                orderType: "city",
                userType: "customer",
                note: "Referral Amount",
              );

              await FireStoreUtils.setWalletTransaction(transactionModel);
            } catch (error) {
              print(error);
            }
          }
        });
      } else {
        return;
      }
    }
  }

  static Future<bool> getIntercityFirstOrderOrNOt(InterCityOrderModel orderModel) async {
    bool isFirst = true;
    await fireStore
        .collection(CollectionName.ordersIntercity)
        .where('userId', isEqualTo: orderModel.userId)
        .get()
        .then((value) {
      if (value.size == 1) {
        isFirst = true;
      } else {
        isFirst = false;
      }
    });
    return isFirst;
  }

  static Future updateIntercityReferralAmount(InterCityOrderModel orderModel) async {
    ReferralModel? referralModel;
    await fireStore
        .collection(CollectionName.referral)
        .doc(orderModel.userId)
        .get()
        .then((value) {
      if (value.data() != null) {
        referralModel = ReferralModel.fromJson(value.data()!);
      } else {
        return;
      }
    });

    if (referralModel != null) {
      if (referralModel!.referralBy != null && referralModel!.referralBy!.isNotEmpty) {
        await fireStore
            .collection(CollectionName.users)
            .doc(referralModel!.referralBy)
            .get()
            .then((value) async {
          DocumentSnapshot<Map<String, dynamic>> userDocument = value;
          if (userDocument.data() != null && userDocument.exists) {
            try {
              UserModel user = UserModel.fromJson(userDocument.data()!);
              user.walletAmount = (double.parse(user.walletAmount.toString()) +
                  double.parse(Constant.referralAmount.toString())).toString();
              updateUser(user);

              WalletTransactionModel transactionModel = WalletTransactionModel(
                id: Constant.getUuid(),
                amount: Constant.referralAmount.toString(),
                createdDate: Timestamp.now(),
                paymentType: "Wallet",
                transactionId: orderModel.id,
                userId: orderModel.driverId.toString(),
                orderType: "intercity",
                userType: "customer",
                note: "Referral Amount",
              );

              await FireStoreUtils.setWalletTransaction(transactionModel);
            } catch (error) {
              print(error);
            }
          }
        });
      } else {
        return;
      }
    }
  }

  // ============================================================================
  // SISTEMA DE ATRIBUIÇÃO AUTOMÁTICA
  // ============================================================================

  /// Atribui corrida para um motorista específico
  static Future<bool> assignRideToDriver(String orderId, String driverId) async {
    try {
      await fireStore.collection(CollectionName.orders).doc(orderId).update({
        'assignedDriverId': driverId,
        'assignedAt': Timestamp.now(),
      });

      print('✅ Corrida $orderId atribuída ao motorista $driverId');
      return true;
    } catch (e) {
      print('❌ Erro ao atribuir corrida: $e');
      return false;
    }
  }

  /// Aceita corrida atribuída automaticamente
  static Future<bool> acceptAssignedRide(String orderId, String driverId) async {
    try {
      await fireStore.collection(CollectionName.orders).doc(orderId).update({
        'driverId': driverId,
        'acceptedAt': Timestamp.now(),
        'status': Constant.rideActive,
      });

      print('✅ Corrida $orderId aceita pelo motorista $driverId');
      return true;
    } catch (e) {
      print('❌ Erro ao aceitar corrida atribuída: $e');
      return false;
    }
  }

  /// Rejeita corrida atribuída
  static Future<bool> rejectAssignedRide(String orderId, String driverId) async {
    try {
      DocumentSnapshot orderDoc = await fireStore
          .collection(CollectionName.orders)
          .doc(orderId)
          .get();

      if (!orderDoc.exists) return false;

      Map<String, dynamic> data = orderDoc.data() as Map<String, dynamic>;
      List<dynamic> rejectedIds = data['rejectedDriverIds'] ?? [];

      if (!rejectedIds.contains(driverId)) {
        rejectedIds.add(driverId);
      }

      await fireStore.collection(CollectionName.orders).doc(orderId).update({
        'assignedDriverId': FieldValue.delete(),
        'assignedAt': FieldValue.delete(),
        'rejectedDriverIds': rejectedIds,
      });

      print('✅ Corrida $orderId rejeitada pelo motorista $driverId');
      return true;
    } catch (e) {
      print('❌ Erro ao rejeitar corrida: $e');
      return false;
    }
  }

  /// Busca corridas atribuídas para um motorista
  static Stream<List<OrderModel>> getAssignedRidesForDriver(String driverId) {
    return fireStore
        .collection(CollectionName.orders)
        .where('assignedDriverId', isEqualTo: driverId)
        .where('status', isEqualTo: Constant.ridePlaced)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => OrderModel.fromJson(doc.data()))
        .toList());
  }

  /// Verifica se motorista tem corrida atribuída pendente
  static Future<OrderModel?> getDriverPendingAssignment(String driverId) async {
    try {
      QuerySnapshot query = await fireStore
          .collection(CollectionName.orders)
          .where('assignedDriverId', isEqualTo: driverId)
          .where('status', isEqualTo: Constant.ridePlaced)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return OrderModel.fromJson(query.docs.first.data() as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      print('❌ Erro ao buscar atribuição pendente: $e');
      return null;
    }
  }

  /// Limpa atribuições expiradas (corridas atribuídas há mais de 15 minutos)
  static Future<void> cleanExpiredAssignments() async {
    try {
      DateTime cutoffTime = DateTime.now().subtract(const Duration(minutes: 15));
      Timestamp cutoffTimestamp = Timestamp.fromDate(cutoffTime);

      QuerySnapshot expiredAssignments = await fireStore
          .collection(CollectionName.orders)
          .where('assignedAt', isLessThan: cutoffTimestamp)
          .where('assignedDriverId', isNull: false)
          .where('status', isEqualTo: Constant.ridePlaced)
          .get();

      WriteBatch batch = fireStore.batch();

      for (var doc in expiredAssignments.docs) {
        batch.update(doc.reference, {
          'assignedDriverId': FieldValue.delete(),
          'assignedAt': FieldValue.delete(),
        });
      }

      await batch.commit();
      print('🧹 Limpas ${expiredAssignments.docs.length} atribuições expiradas');
    } catch (e) {
      print('❌ Erro ao limpar atribuições expiradas: $e');
    }
  }

  /// Calcula distância entre dois pontos em km
  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371;

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  /// Busca motoristas online próximos
  static Future<List<String>> getNearbyOnlineDrivers({
    required double lat,
    required double lng,
    required String serviceId,
    double radiusKm = 10.0,
    int limit = 10,
  }) async {
    try {
      QuerySnapshot driversQuery = await fireStore
          .collection(CollectionName.driverUsers)
          .where('isOnline', isEqualTo: true)
          .where('serviceId', isEqualTo: serviceId)
          .where('documentVerification', isEqualTo: true)
          .limit(50)
          .get();

      List<String> nearbyDrivers = [];

      for (var doc in driversQuery.docs) {
        try {
          Map<String, dynamic> driverData = doc.data() as Map<String, dynamic>;

          if (driverData['location'] != null) {
            double driverLat = driverData['location']['latitude'] ?? 0.0;
            double driverLng = driverData['location']['longitude'] ?? 0.0;

            double distance = _calculateDistance(lat, lng, driverLat, driverLng);

            if (distance <= radiusKm) {
              nearbyDrivers.add(doc.id);
            }
          }
        } catch (e) {
          print('❌ Erro ao processar motorista ${doc.id}: $e');
        }
      }

      return nearbyDrivers.take(limit).toList();
    } catch (e) {
      print('❌ Erro ao buscar motoristas próximos: $e');
      return [];
    }
  }

  /// Encontra o melhor motorista para uma corrida
  static Future<String?> findBestDriverForRide(OrderModel order) async {
    if (order.sourceLocationLAtLng == null) return null;

    try {
      List<String> nearbyDrivers = await getNearbyOnlineDrivers(
        lat: order.sourceLocationLAtLng!.latitude!,
        lng: order.sourceLocationLAtLng!.longitude!,
        serviceId: order.serviceId ?? '',
        radiusKm: 15.0,
      );

      if (nearbyDrivers.isEmpty) return null;

      // Remove motoristas que já rejeitaram
      List<String> rejectedIds = List.from(order.rejectedDriverIds ?? []);
      nearbyDrivers.removeWhere((driverId) => rejectedIds.contains(driverId));

      if (nearbyDrivers.isEmpty) return null;

      // Retorna o primeiro disponível
      return nearbyDrivers.first;
    } catch (e) {
      print('❌ Erro ao encontrar melhor motorista: $e');
      return null;
    }
  }

  /// Atribui corrida automaticamente
  static Future<bool> autoAssignRide(String orderId) async {
    try {
      DocumentSnapshot orderDoc = await fireStore
          .collection(CollectionName.orders)
          .doc(orderId)
          .get();

      if (!orderDoc.exists) return false;

      OrderModel order = OrderModel.fromJson(orderDoc.data() as Map<String, dynamic>);

      if (order.assignedDriverId != null) return false;

      String? bestDriverId = await findBestDriverForRide(order);

      if (bestDriverId == null) return false;

      return await assignRideToDriver(orderId, bestDriverId);
    } catch (e) {
      print('❌ Erro na atribuição automática: $e');
      return false;
    }
  }
}