import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/controller/wallet_controller.dart';
import 'package:driver/model/intercity_order_model.dart';
import 'package:driver/model/order_model.dart';
import 'package:driver/model/wallet_transaction_model.dart';
import 'package:driver/model/withdraw_model.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/button_them.dart';
import 'package:driver/themes/responsive.dart';
import 'package:driver/themes/text_field_them.dart';
import 'package:driver/ui/order_screen/complete_order_screen.dart';
import 'package:driver/ui/withdraw_history/withdraw_history_screen.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  // Função para tratar valores nulos de double
  static double safeParseDouble(String? value, {double defaultValue = 0.0}) {
    if (value == null || value.isEmpty || value == 'null') {
      return defaultValue;
    }
    try {
      return double.parse(value);
    } catch (e) {
      return defaultValue;
    }
  }

  // Função para tratar valores nulos de string
  static String safeString(dynamic value, {String defaultValue = "0"}) {
    if (value == null || value.toString() == 'null') {
      return defaultValue;
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return GetX<WalletController>(
        init: WalletController(),
        builder: (controller) {
          return Scaffold(
            backgroundColor: AppColors.primary,
            body: controller.isLoading.value
                ? Constant.loader(context)
                : Column(
              children: [
                Container(
                  height: Responsive.height(24, context),
                  width: Responsive.width(100, context),
                  color: AppColors.primary,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: Responsive.width(2.5, context)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Total Balance".tr,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: Responsive.width(4, context),
                                ),
                              ),
                              Text(
                                Constant.amountShow(amount: safeString(controller.driverUserModel.value.walletAmount, defaultValue: "0")),
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: Responsive.width(6, context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                        color: themeChange.getThem() ? AppColors.darkBackground : AppColors.background,
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25))
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: Responsive.width(2.5, context)),
                      child: controller.transactionList.isEmpty
                          ? Center(
                        child: Text(
                          "No transaction found".tr,
                          style: GoogleFonts.poppins(
                            color: themeChange.getThem() ? Colors.white : Colors.black,
                            fontSize: Responsive.width(4, context),
                          ),
                        ),
                      )
                          : ListView.builder(
                        itemCount: controller.transactionList.length,
                        itemBuilder: (context, index) {
                          WalletTransactionModel walletTransactionModel = controller.transactionList[index];
                          return InkWell(
                            onTap: () async {
                              if (walletTransactionModel.orderType == "city") {
                                await FireStoreUtils.getOrder(walletTransactionModel.transactionId.toString()).then((value) {
                                  if (value != null) {
                                    OrderModel orderModel = value;
                                    Get.to(const CompleteOrderScreen(), arguments: {
                                      "orderModel": orderModel,
                                    });
                                  }
                                });
                              } else if (walletTransactionModel.orderType == "intercity") {
                                await FireStoreUtils.getInterCityOrder(walletTransactionModel.transactionId.toString()).then((value) {
                                  if (value != null) {
                                    InterCityOrderModel orderModel = value;
                                    // Get.to(const CompleteIntercityOrderScreen(), arguments: {
                                    //   "orderModel": orderModel,
                                    // });
                                  }
                                });
                              } else {
                                showTransactionDetails(context: context, walletTransactionModel: walletTransactionModel);
                              }
                            },
                            child: Padding(
                              padding: EdgeInsets.all(Responsive.width(2, context)),
                              child: Container(
                                  decoration: BoxDecoration(
                                    color: themeChange.getThem() ? AppColors.darkContainerBackground : AppColors.containerBackground,
                                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                                    border: Border.all(color: themeChange.getThem() ? AppColors.darkContainerBorder : AppColors.containerBorder, width: 0.5),
                                    boxShadow: themeChange.getThem()
                                        ? null
                                        : [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.5),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(Responsive.width(2, context)),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                            decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(50)),
                                            child: Padding(
                                              padding: EdgeInsets.all(Responsive.width(3, context)),
                                              child: SvgPicture.asset(
                                                'assets/icons/ic_wallet.svg',
                                                width: Responsive.width(6, context),
                                                color: Colors.black,
                                              ),
                                            )),
                                        SizedBox(
                                          width: Responsive.width(2.5, context),
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      Constant.dateFormatTimestamp(walletTransactionModel.createdDate),
                                                      style: GoogleFonts.poppins(
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: Responsive.width(3.5, context),
                                                        color: themeChange.getThem() ? Colors.white : Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    "${safeParseDouble(walletTransactionModel.amount?.toString()) < 0 ? "(-" : "+"}${Constant.amountShow(amount: safeString(walletTransactionModel.amount?.toString().replaceAll("-", ""), defaultValue: "0"))}${safeParseDouble(walletTransactionModel.amount?.toString()) < 0 ? ")" : ""}",
                                                    style: GoogleFonts.poppins(
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: Responsive.width(3.5, context),
                                                        color: safeParseDouble(walletTransactionModel.amount?.toString()) < 0 ? Colors.red : Colors.green),
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                safeString(walletTransactionModel.note, defaultValue: ""),
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w400,
                                                  fontSize: Responsive.width(3.2, context),
                                                  color: themeChange.getThem() ? Colors.white70 : Colors.black54,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: Padding(
              padding: EdgeInsets.symmetric(horizontal: Responsive.width(2.5, context), vertical: Responsive.height(5, context)),
              child: Row(
                children: [
                  Expanded(
                    child: ButtonThem.buildBorderButton(
                      context,
                      title: "withdraw".tr,
                      onPress: () async {
                        double currentBalance = safeParseDouble(controller.driverUserModel.value.walletAmount?.toString());

                        if (currentBalance <= 0) {
                          ShowToastDialog.showToast("Insufficient balance".tr);
                        } else {
                          ShowToastDialog.showLoader("Aguarde...".tr);
                          await FireStoreUtils.bankDetailsIsAvailable().then((value) {
                            ShowToastDialog.closeLoader();
                            if (value == true) {
                              withdrawAmountBottomSheet(context, controller);
                            } else {
                              ShowToastDialog.showToast("Your bank details is not available.Please add bank details".tr);
                            }
                          });
                        }
                      },
                    ),
                  ),
                  SizedBox(
                    width: Responsive.width(2.5, context),
                  ),
                  Expanded(
                    child: ButtonThem.buildButton(
                      context,
                      title: "Withdrawal history".tr,
                      onPress: () {
                        Get.to(const WithDrawHistoryScreen());
                      },
                    ),
                  )
                ],
              ),
            ),
          );
        });
  }

  paymentMethodDialog(BuildContext context, WalletController controller) {
    return showModalBottomSheet(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topRight: Radius.circular(30), topLeft: Radius.circular(30))),
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        builder: (context1) {
          final themeChange = Provider.of<DarkThemeProvider>(context1);

          return FractionallySizedBox(
            heightFactor: 0.9,
            child: Container(
              decoration: BoxDecoration(
                color: themeChange.getThem() ? AppColors.darkBackground : AppColors.background,
                borderRadius: const BorderRadius.only(topRight: Radius.circular(30), topLeft: Radius.circular(30)),
              ),
              child: StatefulBuilder(builder: (context1, setState) {
                return Obx(
                      () => Padding(
                    padding: EdgeInsets.symmetric(horizontal: Responsive.width(2.5, context), vertical: Responsive.height(1.2, context)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: EdgeInsets.all(Responsive.width(2, context)),
                          child: Row(
                            children: [
                              InkWell(
                                  onTap: () {
                                    Get.back();
                                  },
                                  child: Icon(
                                    Icons.arrow_back_ios,
                                    color: themeChange.getThem() ? Colors.white : Colors.black,
                                  )),
                              Expanded(
                                  child: Center(
                                      child: Text(
                                        "Topup Wallet".tr,
                                        style: GoogleFonts.poppins(
                                          fontSize: Responsive.width(4.5, context),
                                          fontWeight: FontWeight.w600,
                                          color: themeChange.getThem() ? Colors.white : Colors.black,
                                        ),
                                      ))),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: EdgeInsets.all(Responsive.width(2, context)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Add Topup Amount".tr,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: Responsive.width(4, context),
                                      color: themeChange.getThem() ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  SizedBox(
                                    height: Responsive.height(0.6, context),
                                  ),
                                  TextFieldThem.buildTextFiled(context, hintText: 'Enter Amount'.tr, controller: controller.amountController.value, keyBoardType: TextInputType.number),
                                  SizedBox(
                                    height: Responsive.height(1.2, context),
                                  ),
                                  Text(
                                    "Select Payment Option".tr,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: Responsive.width(4, context),
                                      color: themeChange.getThem() ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  Visibility(
                                    visible: controller.paymentModel.value.strip?.enable == true,
                                    child: Obx(
                                          () => Column(
                                        children: [
                                          SizedBox(
                                            height: Responsive.height(1.2, context),
                                          ),
                                          InkWell(
                                            onTap: () {
                                              controller.selectedPaymentMethod.value = safeString(controller.paymentModel.value.strip?.name, defaultValue: "");
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius: const BorderRadius.all(Radius.circular(10)),
                                                border: Border.all(
                                                    color: controller.selectedPaymentMethod.value == safeString(controller.paymentModel.value.strip?.name, defaultValue: "")
                                                        ? themeChange.getThem()
                                                        ? AppColors.darkModePrimary
                                                        : AppColors.primary
                                                        : themeChange.getThem()
                                                        ? AppColors.darkTextFieldBorder
                                                        : AppColors.textFieldBorder,
                                                    width: 1),
                                              ),
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(horizontal: Responsive.width(2.5, context), vertical: Responsive.height(1.2, context)),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      height: Responsive.height(5, context),
                                                      width: Responsive.width(20, context),
                                                      decoration: const BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.all(Radius.circular(5))),
                                                      child: Padding(
                                                        padding: EdgeInsets.all(Responsive.width(2, context)),
                                                        child: Image.asset('assets/images/stripe.png'),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: Responsive.width(2.5, context),
                                                    ),
                                                    Expanded(
                                                      child: Text(
                                                        safeString(controller.paymentModel.value.strip?.name, defaultValue: "Stripe"),
                                                        style: GoogleFonts.poppins(
                                                          fontSize: Responsive.width(3.8, context),
                                                          color: themeChange.getThem() ? Colors.white : Colors.black,
                                                        ),
                                                      ),
                                                    ),
                                                    Radio(
                                                      value: safeString(controller.paymentModel.value.strip?.name, defaultValue: ""),
                                                      groupValue: controller.selectedPaymentMethod.value,
                                                      activeColor: themeChange.getThem() ? AppColors.darkModePrimary : AppColors.primary,
                                                      onChanged: (value) {
                                                        controller.selectedPaymentMethod.value = safeString(controller.paymentModel.value.strip?.name, defaultValue: "");
                                                      },
                                                    )
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Adicione outros métodos de pagamento aqui se necessário
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: Responsive.height(1.2, context),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: Responsive.width(5, context)),
                          child: ButtonThem.buildButton(
                            context,
                            title: "Add Amount".tr,
                            onPress: () {
                              if (controller.amountController.value.text.isEmpty) {
                                ShowToastDialog.showToast("Please enter amount".tr);
                              } else if (controller.selectedPaymentMethod.value.isEmpty) {
                                ShowToastDialog.showToast("Please select payment method".tr);
                              } else {
                                controller.walletTopUp();
                                Get.back();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          );
        });
  }

  showTransactionDetails({required BuildContext context, required WalletTransactionModel walletTransactionModel}) {
    return showModalBottomSheet(
        elevation: 5,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15))),
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            final themeChange = Provider.of<DarkThemeProvider>(context);

            return Container(
              decoration: BoxDecoration(
                color: themeChange.getThem() ? AppColors.darkBackground : AppColors.background,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: Responsive.width(2.5, context)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: Responsive.height(1.2, context)),
                        child: Text(
                          "Transaction Details".tr,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: Responsive.width(4, context),
                            color: themeChange.getThem() ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: themeChange.getThem() ? AppColors.darkContainerBackground : AppColors.containerBackground,
                          borderRadius: const BorderRadius.all(Radius.circular(10)),
                          border: Border.all(color: themeChange.getThem() ? AppColors.darkContainerBorder : AppColors.containerBorder, width: 0.5),
                          boxShadow: themeChange.getThem()
                              ? null
                              : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.10),
                              blurRadius: 5,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(Responsive.width(2, context)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Transaction ID".tr,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: Responsive.width(3.8, context),
                                  color: themeChange.getThem() ? Colors.white : Colors.black,
                                ),
                              ),
                              SizedBox(
                                height: Responsive.height(0.6, context),
                              ),
                              Text(
                                "#${safeString(walletTransactionModel.transactionId, defaultValue: "N/A").toUpperCase()}",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w400,
                                  fontSize: Responsive.width(3.5, context),
                                  color: themeChange.getThem() ? Colors.white70 : Colors.black54,
                                ),
                              ),
                              SizedBox(
                                height: Responsive.height(1.2, context),
                              ),
                              Text(
                                "Amount".tr,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: Responsive.width(3.8, context),
                                  color: themeChange.getThem() ? Colors.white : Colors.black,
                                ),
                              ),
                              SizedBox(
                                height: Responsive.height(0.6, context),
                              ),
                              Text(
                                "${safeParseDouble(walletTransactionModel.amount?.toString()) < 0 ? "(-" : "+"}${Constant.amountShow(amount: safeString(walletTransactionModel.amount?.toString().replaceAll("-", ""), defaultValue: "0"))}${safeParseDouble(walletTransactionModel.amount?.toString()) < 0 ? ")" : ""}",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: Responsive.width(3.8, context),
                                  color: safeParseDouble(walletTransactionModel.amount?.toString()) < 0 ? Colors.red : Colors.green,
                                ),
                              ),
                              SizedBox(
                                height: Responsive.height(1.2, context),
                              ),
                              Text(
                                "Note".tr,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: Responsive.width(3.8, context),
                                  color: themeChange.getThem() ? Colors.white : Colors.black,
                                ),
                              ),
                              SizedBox(
                                height: Responsive.height(0.6, context),
                              ),
                              Text(
                                safeString(walletTransactionModel.note, defaultValue: "No note available"),
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w400,
                                  fontSize: Responsive.width(3.5, context),
                                  color: themeChange.getThem() ? Colors.white70 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        height: Responsive.height(2.5, context),
                      )
                    ],
                  ),
                ),
              ),
            );
          });
        });
  }

  withdrawAmountBottomSheet(BuildContext context, WalletController controller) {
    return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
        ),
        builder: (context) {
          final themeChange = Provider.of<DarkThemeProvider>(context);

          return StatefulBuilder(builder: (context, setState) {
            return Container(
              decoration: BoxDecoration(
                color: themeChange.getThem() ? AppColors.darkBackground : AppColors.background,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: Responsive.width(2.5, context)),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: Responsive.height(3, context), bottom: Responsive.height(1.2, context)),
                        child: Text(
                          "Withdraw".tr,
                          style: GoogleFonts.poppins(
                            fontSize: Responsive.width(4.5, context),
                            fontWeight: FontWeight.w600,
                            color: themeChange.getThem() ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      Container(
                          decoration: BoxDecoration(
                            color: themeChange.getThem() ? AppColors.darkContainerBackground : AppColors.containerBackground,
                            borderRadius: const BorderRadius.all(Radius.circular(10)),
                            border: Border.all(color: themeChange.getThem() ? AppColors.darkContainerBorder : AppColors.containerBorder, width: 0.5),
                            boxShadow: themeChange.getThem()
                                ? null
                                : [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(Responsive.width(2, context)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        safeString(controller.bankDetailsModel.value.bankName, defaultValue: "Bank Name"),
                                        style: GoogleFonts.poppins(
                                          fontSize: Responsive.width(5.5, context),
                                          fontWeight: FontWeight.bold,
                                          color: themeChange.getThem() ? Colors.white : Colors.black,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.account_balance,
                                      size: Responsive.width(10, context),
                                      color: themeChange.getThem() ? Colors.white70 : Colors.black54,
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: Responsive.height(0.2, context),
                                ),
                                Text(
                                  safeString(controller.bankDetailsModel.value.accountNumber, defaultValue: "Account Number"),
                                  style: GoogleFonts.poppins(
                                    fontSize: Responsive.width(5, context),
                                    fontWeight: FontWeight.w600,
                                    color: themeChange.getThem() ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                                SizedBox(
                                  height: Responsive.height(0.6, context),
                                ),
                                Text(
                                  safeString(controller.bankDetailsModel.value.holderName, defaultValue: "Holder Name"),
                                  style: GoogleFonts.poppins(
                                    fontSize: Responsive.width(4.5, context),
                                    fontWeight: FontWeight.bold,
                                    color: themeChange.getThem() ? Colors.white : Colors.black,
                                  ),
                                ),
                                SizedBox(
                                  height: Responsive.height(0.4, context),
                                ),
                                Text(
                                  safeString(controller.bankDetailsModel.value.branchName, defaultValue: "Branch Name"),
                                  style: GoogleFonts.poppins(
                                    fontSize: Responsive.width(4.5, context),
                                    color: themeChange.getThem() ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                                Text(
                                  safeString(controller.bankDetailsModel.value.otherInformation, defaultValue: "Other Information"),
                                  style: GoogleFonts.poppins(
                                    fontSize: Responsive.width(3.8, context),
                                    color: themeChange.getThem() ? Colors.white60 : Colors.black54,
                                  ),
                                ),
                                SizedBox(
                                  height: Responsive.height(1.2, context),
                                ),
                              ],
                            ),
                          )),
                      SizedBox(
                        height: Responsive.height(2.5, context),
                      ),
                      RichText(
                        text: TextSpan(
                          text: "Amount to Withdraw".tr,
                          style: GoogleFonts.poppins(
                            fontSize: Responsive.width(4, context),
                            color: themeChange.getThem() ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: Responsive.height(1.2, context),
                      ),
                      TextFieldThem.buildTextFiled(context, hintText: 'Enter Amount'.tr, controller: controller.withdrawalAmountController.value),
                      SizedBox(
                        height: Responsive.height(1.2, context),
                      ),
                      TextFieldThem.buildTextFiled(context, hintText: 'Notes'.tr, maxLine: 3, controller: controller.noteController.value),
                      SizedBox(
                        height: Responsive.height(1.2, context),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ButtonThem.buildButton(
                            context,
                            title: "Withdrawal".tr,
                            onPress: () async {
                              double currentBalance = safeParseDouble(controller.driverUserModel.value.walletAmount?.toString());
                              double withdrawAmount = safeParseDouble(controller.withdrawalAmountController.value.text);
                              double minimumAmount = safeParseDouble(Constant.minimumAmountToWithdrawal);

                              if (currentBalance < withdrawAmount) {
                                ShowToastDialog.showToast("Insufficient balance".tr);
                              } else if (minimumAmount > withdrawAmount) {
                                ShowToastDialog.showToast(
                                    "Withdraw amount must be greater or equal to ${Constant.amountShow(amount: Constant.minimumAmountToWithdrawal.toString())}".tr);
                              } else {
                                ShowToastDialog.showLoader("Aguarde...".tr);
                                WithdrawModel withdrawModel = WithdrawModel();
                                withdrawModel.id = Constant.getUuid();
                                withdrawModel.userId = FireStoreUtils.getCurrentUid();
                                withdrawModel.paymentStatus = "pending";
                                withdrawModel.amount = controller.withdrawalAmountController.value.text;
                                withdrawModel.note = controller.noteController.value.text;
                                withdrawModel.createdDate = Timestamp.now();

                                await FireStoreUtils.updatedDriverWallet(amount: "-${controller.withdrawalAmountController.value.text}");

                                await FireStoreUtils.setWithdrawRequest(withdrawModel).then((value) {
                                  controller.getUser();
                                  ShowToastDialog.closeLoader();
                                  ShowToastDialog.showToast("Request sent to admin".tr);
                                  Get.back();
                                });
                              }
                            },
                          )
                        ],
                      ),
                      SizedBox(
                        height: Responsive.height(2.5, context),
                      ),
                    ],
                  ),
                ),
              ),
            );
          });
        });
  }
}