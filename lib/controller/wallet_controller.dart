import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/model/bank_details_model.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/model/payment_model.dart';
import 'package:driver/model/wallet_transaction_model.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WalletController extends GetxController {
  Rx<TextEditingController> withdrawalAmountController = TextEditingController().obs;
  Rx<TextEditingController> noteController = TextEditingController().obs;

  Rx<TextEditingController> amountController = TextEditingController().obs;
  Rx<PaymentModel> paymentModel = PaymentModel().obs;
  Rx<DriverUserModel> driverUserModel = DriverUserModel().obs;
  Rx<BankDetailsModel> bankDetailsModel = BankDetailsModel().obs;
  RxString selectedPaymentMethod = "".obs;

  RxBool isLoading = true.obs;
  RxList transactionList = <WalletTransactionModel>[].obs;

  @override
  void onInit() {
    // TODO: implement onInit
    getPaymentData();
    super.onInit();
  }

  getPaymentData() async {
    getTraction();
    getUser();

    isLoading.value = false;
    update();
  }

  getUser() async {
    await FireStoreUtils.getDriverProfile(FireStoreUtils.getCurrentUid()).then((value) {
      if (value != null) {
        driverUserModel.value = value;
      }
    });

    await FireStoreUtils.getBankDetails().then((value) {
      if (value != null) {
        bankDetailsModel.value = value;
      }
    });
  }

  getTraction() async {
    await FireStoreUtils.getWalletTransaction().then((value) {
      if (value != null) {
        transactionList.value = value;
      }
    });
  }

  walletTopUp() async {
    WalletTransactionModel transactionModel = WalletTransactionModel(
        id: Constant.getUuid(),
        amount: amountController.value.text,
        createdDate: Timestamp.now(),
        paymentType: selectedPaymentMethod.value,
        transactionId: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: FireStoreUtils.getCurrentUid(),
        userType: "driver",
        note: "Wallet Topup");

    await FireStoreUtils.setWalletTransaction(transactionModel).then((value) async {
      if (value == true) {
        await FireStoreUtils.updatedDriverWallet(amount: amountController.value.text).then((value) {
          getUser();
          getTraction();
        });
      }
    });

    ShowToastDialog.showToast("Amount added in your wallet.");
  }

}
