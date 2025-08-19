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

class FireStoreUtils {
  static FirebaseFirestore fireStore = FirebaseFirestore.instance;

  static Future<bool> isLogin() async {
    bool isLogin = false;
    if (FirebaseAuth.instance.currentUser != null) {
      isLogin = await userExitOrNot(FirebaseAuth.instance.currentUser!.uid);
    } else {
      isLogin = false;
    }
    return isLogin;
  }

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

  static String getCurrentUid() {
    return FirebaseAuth.instance.currentUser!.uid;
  }

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

  Future<PaymentModel?> getPayment() async {
    PaymentModel? paymentModel;
    await fireStore.collection(CollectionName.settings).doc("payment").get().then((value) {
      paymentModel = PaymentModel.fromJson(value.data()!);
    });
    return paymentModel;
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

  static Future<DriverIdAcceptReject?> getAcceptedOrders(String orderId, String driverId) async {
    DriverIdAcceptReject? driverIdAcceptReject;
    await fireStore.collection(CollectionName.orders).doc(orderId).collection("acceptedDriver").doc(driverId).get().then((value) async {
      if (value.exists) {
        driverIdAcceptReject = DriverIdAcceptReject.fromJson(value.data()!);
      }
    }).catchError((error) {
      log("Failed to update user: $error");
      driverIdAcceptReject = null;
    });
    return driverIdAcceptReject;
  }

  static Future<DriverIdAcceptReject?> getInterCItyAcceptedOrders(String orderId, String driverId) async {
    DriverIdAcceptReject? driverIdAcceptReject;
    await fireStore.collection(CollectionName.ordersIntercity).doc(orderId).collection("acceptedDriver").doc(driverId).get().then((value) async {
      if (value.exists) {
        driverIdAcceptReject = DriverIdAcceptReject.fromJson(value.data()!);
      }
    }).catchError((error) {
      log("Failed to update user: $error");
      driverIdAcceptReject = null;
    });
    return driverIdAcceptReject;
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

  static Future<List<DocumentModel>> getDocumentList() async {
    List<DocumentModel> documentList = [];
    await fireStore.collection(CollectionName.documents).where('enable', isEqualTo: true).where('isDeleted', isEqualTo: false).get().then((value) {
      for (var element in value.docs) {
        DocumentModel documentModel = DocumentModel.fromJson(element.data());
        documentList.add(documentModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return documentList;
  }

  static Future<List<ServiceModel>> getService() async {
    List<ServiceModel> serviceList = [];
    await fireStore.collection(CollectionName.service).where('enable', isEqualTo: true).get().then((value) {
      for (var element in value.docs) {
        ServiceModel documentModel = ServiceModel.fromJson(element.data());
        serviceList.add(documentModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return serviceList;
  }

  static Future<DriverDocumentModel?> getDocumentOfDriver() async {
    DriverDocumentModel? driverDocumentModel;
    await fireStore.collection(CollectionName.driverDocument).doc(getCurrentUid()).get().then((value) async {
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
    await fireStore.collection(CollectionName.driverDocument).doc(getCurrentUid()).get().then((value) async {
      if (value.exists) {
        DriverDocumentModel newDriverDocumentModel = DriverDocumentModel.fromJson(value.data()!);
        documentsList = newDriverDocumentModel.documents!;
        var contain = newDriverDocumentModel.documents!.where((element) => element.documentId == documents.documentId);
        if (contain.isEmpty) {
          documentsList.add(documents);

          driverDocumentModel.id = getCurrentUid();
          driverDocumentModel.documents = documentsList;
        } else {
          var index = newDriverDocumentModel.documents!.indexWhere((element) => element.documentId == documents.documentId);

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

    await fireStore.collection(CollectionName.driverDocument).doc(getCurrentUid()).set(driverDocumentModel.toJson()).then((value) {
      isAdded = true;
    }).catchError((error) {
      isAdded = false;
      log(error.toString());
    });

    return isAdded;
  }

  static Future<List<VehicleTypeModel>?> getVehicleType() async {
    List<VehicleTypeModel> vehicleList = [];
    await fireStore.collection(CollectionName.vehicleType).where('enable', isEqualTo: true).get().then((value) async {
      for (var element in value.docs) {
        VehicleTypeModel vehicleModel = VehicleTypeModel.fromJson(element.data());
        vehicleList.add(vehicleModel);
      }
    });
    return vehicleList;
  }

  static Future<List<DriverRulesModel>?> getDriverRules() async {
    List<DriverRulesModel> driverRulesModel = [];
    await fireStore.collection(CollectionName.driverRules).where('enable', isEqualTo: true).where('isDeleted', isEqualTo: false).get().then((value) async {
      for (var element in value.docs) {
        DriverRulesModel vehicleModel = DriverRulesModel.fromJson(element.data());
        driverRulesModel.add(vehicleModel);
      }
    });
    return driverRulesModel;
  }

  StreamController<List<OrderModel>>? getNearestOrderRequestController;

  Stream<List<OrderModel>> getOrders(DriverUserModel driverUserModel, double? latitude, double? longLatitude) async* {
    getNearestOrderRequestController = StreamController<List<OrderModel>>.broadcast();
    List<OrderModel> ordersList = [];
    Query<Map<String, dynamic>> query = fireStore
        .collection(CollectionName.orders)
        .where('serviceId', isEqualTo: driverUserModel.serviceId)
        .where('zoneId', whereIn: driverUserModel.zoneIds)
        .where('status', isEqualTo: Constant.ridePlaced);
    GeoFirePoint center = Geoflutterfire().point(latitude: latitude ?? 0.0, longitude: longLatitude ?? 0.0);
    Stream<List<DocumentSnapshot>> stream =
        Geoflutterfire().collection(collectionRef: query).within(center: center, radius: double.parse(Constant.radius), field: 'position', strictMode: true);

    stream.listen((List<DocumentSnapshot> documentList) {
      ordersList.clear();
      for (var document in documentList) {
        final data = document.data() as Map<String, dynamic>;
        OrderModel orderModel = OrderModel.fromJson(data);
        if (orderModel.acceptedDriverId != null && orderModel.acceptedDriverId!.isNotEmpty) {
          if (!orderModel.acceptedDriverId!.contains(FireStoreUtils.getCurrentUid())) {
            ordersList.add(orderModel);
          }
        } else {
          ordersList.add(orderModel);
        }
      }
      getNearestOrderRequestController!.sink.add(ordersList);
    });

    yield* getNearestOrderRequestController!.stream;
  }

  StreamController<List<InterCityOrderModel>>? getNearestFreightOrderRequestController;

  Stream<List<InterCityOrderModel>> getFreightOrders(double? latitude, double? longLatitude) async* {
    getNearestFreightOrderRequestController = StreamController<List<InterCityOrderModel>>.broadcast();
    List<InterCityOrderModel> ordersList = [];
    Query<Map<String, dynamic>> query =
        fireStore.collection(CollectionName.ordersIntercity).where('intercityServiceId', isEqualTo: "Kn2VEnPI3ikF58uK8YqY").where('status', isEqualTo: Constant.ridePlaced);
    GeoFirePoint center = Geoflutterfire().point(latitude: latitude ?? 0.0, longitude: longLatitude ?? 0.0);
    Stream<List<DocumentSnapshot>> stream =
        Geoflutterfire().collection(collectionRef: query).within(center: center, radius: double.parse(Constant.radius), field: 'position', strictMode: true);

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

  closeStream() {
    if (getNearestOrderRequestController != null) {
      getNearestOrderRequestController!.close();
    }
  }

  closeFreightStream() {
    if (getNearestFreightOrderRequestController != null) {
      getNearestFreightOrderRequestController!.close();
    }
  }

  static Future<bool?> setOrder(OrderModel orderModel) async {
    bool isAdded = false;
    await fireStore.collection(CollectionName.orders).doc(orderModel.id).update(orderModel.toJson()).then((value) {
      isAdded = true;
    }).catchError((error) {
      log("Failed to update user: $error");
      isAdded = false;
    });
    return isAdded;
  }

  static Future<bool?> bankDetailsIsAvailable() async {
    bool isAdded = false;
    await fireStore.collection(CollectionName.bankDetails).doc(FireStoreUtils.getCurrentUid()).get().then((value) {
      if (value.exists) {
        isAdded = true;
      } else {
        isAdded = false;
      }
    }).catchError((error) {
      log("Failed to update user: $error");
      isAdded = false;
    });
    return isAdded;
  }

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

  static Future<bool?> acceptRide(OrderModel orderModel, DriverIdAcceptReject driverIdAcceptReject) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.orders)
        .doc(orderModel.id)
        .collection("acceptedDriver")
        .doc(driverIdAcceptReject.driverId)
        .set(driverIdAcceptReject.toJson())
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      log("Failed to update user: $error");
      isAdded = false;
    });
    return isAdded;
  }

  static Future<bool?> setReview(ReviewModel reviewModel) async {
    bool isAdded = false;
    await fireStore.collection(CollectionName.reviewCustomer).doc(reviewModel.id).set(reviewModel.toJson()).then((value) {
      isAdded = true;
    }).catchError((error) {
      log("Failed to update user: $error");
      isAdded = false;
    });
    return isAdded;
  }

  static Future<ReviewModel?> getReview(String orderId) async {
    ReviewModel? reviewModel;
    await fireStore.collection(CollectionName.reviewCustomer).doc(orderId).get().then((value) {
      if (value.data() != null) {
        reviewModel = ReviewModel.fromJson(value.data()!);
      }
    });
    return reviewModel;
  }

  static Future<bool?> setInterCityOrder(InterCityOrderModel orderModel) async {
    bool isAdded = false;
    await fireStore.collection(CollectionName.ordersIntercity).doc(orderModel.id).set(orderModel.toJson()).then((value) {
      isAdded = true;
    }).catchError((error) {
      log("Failed to update user: $error");
      isAdded = false;
    });
    return isAdded;
  }

  static Future<bool?> acceptInterCityRide(InterCityOrderModel orderModel, DriverIdAcceptReject driverIdAcceptReject) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.ordersIntercity)
        .doc(orderModel.id)
        .collection("acceptedDriver")
        .doc(driverIdAcceptReject.driverId)
        .set(driverIdAcceptReject.toJson())
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      log("Failed to update user: $error");
      isAdded = false;
    });
    return isAdded;
  }

  static Future<List<WalletTransactionModel>?> getWalletTransaction() async {
    List<WalletTransactionModel> walletTransactionModel = [];

    await fireStore
        .collection(CollectionName.walletTransaction)
        .where('userId', isEqualTo: FireStoreUtils.getCurrentUid())
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
    await fireStore.collection(CollectionName.walletTransaction).doc(walletTransactionModel.id).set(walletTransactionModel.toJson()).then((value) {
      isAdded = true;
    }).catchError((error) {
      log("Failed to update user: $error");
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

  static Future<List<LanguageModel>?> getLanguage() async {
    List<LanguageModel> languageList = [];

    await fireStore.collection(CollectionName.languages).get().then((value) {
      for (var element in value.docs) {
        LanguageModel taxModel = LanguageModel.fromJson(element.data());
        languageList.add(taxModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return languageList;
  }

  static Future<List<OnBoardingModel>> getOnBoardingList() async {
    List<OnBoardingModel> onBoardingModel = [];
    await fireStore.collection(CollectionName.onBoarding).where("type", isEqualTo: "driverApp").get().then((value) {
      for (var element in value.docs) {
        OnBoardingModel documentModel = OnBoardingModel.fromJson(element.data());
        onBoardingModel.add(documentModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return onBoardingModel;
  }

  static Future addInBox(InboxModel inboxModel) async {
    return await fireStore.collection(CollectionName.chat).doc(inboxModel.orderId).set(inboxModel.toJson()).then((document) {
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

  static Future<BankDetailsModel?> getBankDetails() async {
    BankDetailsModel? bankDetailsModel;
    await fireStore.collection(CollectionName.bankDetails).doc(FireStoreUtils.getCurrentUid()).get().then((value) {
      if (value.data() != null) {
        bankDetailsModel = BankDetailsModel.fromJson(value.data()!);
      }
    });
    return bankDetailsModel;
  }

  static Future<bool?> updateBankDetails(BankDetailsModel bankDetailsModel) async {
    bool isAdded = false;
    await fireStore.collection(CollectionName.bankDetails).doc(bankDetailsModel.userId).set(bankDetailsModel.toJson()).then((value) {
      isAdded = true;
    }).catchError((error) {
      log("Failed to update user: $error");
      isAdded = false;
    });
    return isAdded;
  }

  static Future<bool?> setWithdrawRequest(WithdrawModel withdrawModel) async {
    bool isAdded = false;
    await fireStore.collection(CollectionName.withdrawalHistory).doc(withdrawModel.id).set(withdrawModel.toJson()).then((value) {
      isAdded = true;
    }).catchError((error) {
      log("Failed to update user: $error");
      isAdded = false;
    });
    return isAdded;
  }

  static Future<List<WithdrawModel>> getWithDrawRequest() async {
    List<WithdrawModel> withdrawalList = [];
    await fireStore.collection(CollectionName.withdrawalHistory).where('userId', isEqualTo: getCurrentUid()).orderBy('createdDate', descending: true).get().then((value) {
      for (var element in value.docs) {
        WithdrawModel documentModel = WithdrawModel.fromJson(element.data());
        withdrawalList.add(documentModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return withdrawalList;
  }

  static Future<bool?> deleteUser() async {
    bool? isDelete;
    try {
      await fireStore.collection(CollectionName.driverUsers).doc(FireStoreUtils.getCurrentUid()).delete();

      // delete user  from firebase auth
      await FirebaseAuth.instance.currentUser!.delete().then((value) {
        isDelete = true;
      });
    } catch (e, s) {
      log('FireStoreUtils.firebaseCreateNewUser $e $s');
      return false;
    }
    return isDelete;
  }

  static Future<bool> getIntercityFirstOrderOrNOt(InterCityOrderModel orderModel) async {
    bool isFirst = true;
    await fireStore.collection(CollectionName.ordersIntercity).where('userId', isEqualTo: orderModel.userId).get().then((value) {
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
    await fireStore.collection(CollectionName.referral).doc(orderModel.userId).get().then((value) {
      if (value.data() != null) {
        referralModel = ReferralModel.fromJson(value.data()!);
      } else {
        return;
      }
    });
    if (referralModel != null) {
      if (referralModel!.referralBy != null && referralModel!.referralBy!.isNotEmpty) {
        await fireStore.collection(CollectionName.users).doc(referralModel!.referralBy).get().then((value) async {
          DocumentSnapshot<Map<String, dynamic>> userDocument = value;
          if (userDocument.data() != null && userDocument.exists) {
            try {
              UserModel user = UserModel.fromJson(userDocument.data()!);
              user.walletAmount = (double.parse(user.walletAmount.toString()) + double.parse(Constant.referralAmount.toString())).toString();
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
                  note: "Referral Amount");

              await FireStoreUtils.setWalletTransaction(transactionModel);
            } catch (error) {}
          }
        });
      } else {
        return;
      }
    }
  }

  static Future<bool> getFirestOrderOrNOt(OrderModel orderModel) async {
    bool isFirst = true;
    await fireStore.collection(CollectionName.orders).where('userId', isEqualTo: orderModel.userId).get().then((value) {
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
    await fireStore.collection(CollectionName.referral).doc(orderModel.userId).get().then((value) {
      if (value.data() != null) {
        referralModel = ReferralModel.fromJson(value.data()!);
      } else {
        return;
      }
    });
    if (referralModel != null) {
      if (referralModel!.referralBy != null && referralModel!.referralBy!.isNotEmpty) {
        await fireStore.collection(CollectionName.users).doc(referralModel!.referralBy).get().then((value) async {
          DocumentSnapshot<Map<String, dynamic>> userDocument = value;
          if (userDocument.data() != null && userDocument.exists) {
            try {
              UserModel user = UserModel.fromJson(userDocument.data()!);
              user.walletAmount = (double.parse(user.walletAmount.toString()) + double.parse(Constant.referralAmount.toString())).toString();
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
                  note: "Referral Amount");

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

  static Future<List<ZoneModel>?> getZone() async {
    List<ZoneModel> airPortList = [];
    await fireStore.collection(CollectionName.zone).where('publish', isEqualTo: true).get().then((value) {
      for (var element in value.docs) {
        ZoneModel ariPortModel = ZoneModel.fromJson(element.data());
        airPortList.add(ariPortModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return airPortList;
  }


  static Stream<List<OrderModel>> getAvailableRidesForAutoAssignment({
    required double driverLat,
    required double driverLng,
    double radiusKm = 10.0,
  }) {
    return fireStore
        .collection(CollectionName.orders)
        .where('status', isEqualTo: Constant.ridePlaced)
        .where('assignedDriverId', isNull: true)
        .orderBy('createdDate', descending: false)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      List<OrderModel> rides = [];

      for (var doc in snapshot.docs) {
        try {
          OrderModel order = OrderModel.fromJson(doc.data());

          // Filtra por distância se tiver localização
          if (order.sourceLocationLAtLng != null) {
            double distance = _calculateDistance(
              driverLat,
              driverLng,
              order.sourceLocationLAtLng!.latitude!,
              order.sourceLocationLAtLng!.longitude!,
            );

            if (distance <= radiusKm) {
              rides.add(order);
            }
          }
        } catch (e) {
          print('Erro ao processar corrida: $e');
        }
      }

      return rides;
    });
  }

  /// Atribui corrida automaticamente a um motorista
  static Future<bool> assignRideToDriver(String orderId, String driverId) async {
    try {
      DocumentReference orderRef = fireStore.collection(CollectionName.orders).doc(orderId);

      // Usa transação para evitar conflitos
      return await fireStore.runTransaction((transaction) async {
        DocumentSnapshot orderSnapshot = await transaction.get(orderRef);

        if (!orderSnapshot.exists) {
          throw Exception('Corrida não encontrada');
        }

        Map<String, dynamic> orderData = orderSnapshot.data() as Map<String, dynamic>;

        // Verifica se já foi atribuída
        if (orderData['assignedDriverId'] != null) {
          return false; // Já foi atribuída para outro motorista
        }

        // Atribui ao motorista
        transaction.update(orderRef, {
          'assignedDriverId': driverId,
          'assignedAt': Timestamp.now(),
          'status': Constant.ridePlaced, // Mantém o status
        });

        return true;
      });
    } catch (e) {
      print('Erro ao atribuir corrida: $e');
      return false;
    }
  }

  /// Remove atribuição e adiciona motorista à lista de rejeitados
  static Future<bool> rejectAssignedRide(String orderId, String driverId) async {
    try {
      DocumentReference orderRef = fireStore.collection(CollectionName.orders).doc(orderId);

      await fireStore.runTransaction((transaction) async {
        DocumentSnapshot orderSnapshot = await transaction.get(orderRef);

        if (!orderSnapshot.exists) {
          throw Exception('Corrida não encontrada');
        }

        Map<String, dynamic> orderData = orderSnapshot.data() as Map<String, dynamic>;
        List<dynamic> rejectedIds = List.from(orderData['rejectedDriverIds'] ?? []);

        // Adiciona à lista de rejeitados se não estiver lá
        if (!rejectedIds.contains(driverId)) {
          rejectedIds.add(driverId);
        }

        // Remove atribuição e atualiza rejeitados
        transaction.update(orderRef, {
          'assignedDriverId': FieldValue.delete(),
          'assignedAt': FieldValue.delete(),
          'rejectedDriverIds': rejectedIds,
        });
      });

      return true;
    } catch (e) {
      print('Erro ao rejeitar corrida: $e');
      return false;
    }
  }

  /// Aceita corrida atribuída automaticamente
  static Future<bool> acceptAssignedRide(OrderModel order, DriverIdAcceptReject driverAcceptance) async {
    try {
      DocumentReference orderRef = fireStore.collection(CollectionName.orders).doc(order.id);

      return await fireStore.runTransaction((transaction) async {
        DocumentSnapshot orderSnapshot = await transaction.get(orderRef);

        if (!orderSnapshot.exists) {
          throw Exception('Corrida não encontrada');
        }

        Map<String, dynamic> orderData = orderSnapshot.data() as Map<String, dynamic>;

        // Verifica se ainda está atribuída ao motorista correto
        if (orderData['assignedDriverId'] != driverAcceptance.driverId) {
          return false; // Não é mais atribuída a este motorista
        }

        // Atualiza para aceita
        transaction.update(orderRef, {
          'status': Constant.rideActive,
          'driverId': driverAcceptance.driverId,
          'acceptedAt': Timestamp.now(),
          'finalRate': driverAcceptance.offerAmount,
        });

        // Salva registro de aceitação
        transaction.set(
          fireStore
              .collection(CollectionName.orders)
              .doc(order.id)
              .collection('acceptedDrivers')
              .doc(driverAcceptance.driverId),
          driverAcceptance.toJson(),
        );

        return true;
      });
    } catch (e) {
      print('Erro ao aceitar corrida atribuída: $e');
      return false;
    }
  }

  /// Busca corridas atribuídas para um motorista específico
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
      print('Erro ao buscar atribuição pendente: $e');
      return null;
    }
  }

  /// Limpa atribuições expiradas (chamado periodicamente)
  static Future<void> cleanExpiredAssignments() async {
    try {
      // Busca corridas atribuídas há mais de 15 minutos
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
      print('Limpas ${expiredAssignments.docs.length} atribuições expiradas');

    } catch (e) {
      print('Erro ao limpar atribuições expiradas: $e');
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

  /// Busca motoristas online próximos para uma corrida
  static Future<List<String>> getNearbyOnlineDrivers({
    required double lat,
    required double lng,
    required String serviceId,
    double radiusKm = 10.0,
    int limit = 10,
  }) async {
    try {
      // Busca motoristas online do serviço específico
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
          print('Erro ao processar motorista ${doc.id}: $e');
        }
      }

      // Ordena por distância e retorna os mais próximos
      return nearbyDrivers.take(limit).toList();

    } catch (e) {
      print('Erro ao buscar motoristas próximos: $e');
      return [];
    }
  }

  /// Sistema inteligente de atribuição de corridas
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

      // Remove motoristas que já rejeitaram esta corrida
      List<String> rejectedIds = List.from(order.rejectedDriverIds ?? []);
      nearbyDrivers.removeWhere((driverId) => rejectedIds.contains(driverId));

      if (nearbyDrivers.isEmpty) return null;

      // Por enquanto, retorna o primeiro disponível
      // Pode ser expandido com algoritmo mais complexo (rating, tempo online, etc.)
      return nearbyDrivers.first;

    } catch (e) {
      print('Erro ao encontrar melhor motorista: $e');
      return null;
    }
  }

  /// Atribui corrida automaticamente para o melhor motorista disponível
  static Future<bool> autoAssignRide(String orderId) async {
    try {
      DocumentSnapshot orderDoc = await fireStore
          .collection(CollectionName.orders)
          .doc(orderId)
          .get();

      if (!orderDoc.exists) return false;

      OrderModel order = OrderModel.fromJson(orderDoc.data() as Map<String, dynamic>);

      // Verifica se já foi atribuída
      if (order.assignedDriverId != null) return false;

      // Encontra melhor motorista
      String? bestDriverId = await findBestDriverForRide(order);

      if (bestDriverId == null) return false;

      // Atribui ao motorista
      return await assignRideToDriver(orderId, bestDriverId);

    } catch (e) {
      print('Erro na atribuição automática: $e');
      return false;
    }
  }
}
