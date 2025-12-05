// lib/ui/bank_details/bank_details_screen.dart - Versão com temas e responsividade
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/controller/bank_details_controller.dart';
import 'package:driver/model/bank_details_model.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/button_them.dart';
import 'package:driver/themes/responsive.dart';
import 'package:driver/themes/text_field_them.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class BankDetailsScreen extends StatelessWidget {
  const BankDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return GetX<BankDetailsController>(
        init: BankDetailsController(),
        builder: (controller) {
          return Scaffold(
            backgroundColor: AppColors.primary,
            body: Column(
              children: [
                SizedBox(
                  height: Responsive.height(8, context),
                  width: Responsive.width(100, context),
                ),
                Expanded(
                  child: Container(
                    height: Responsive.height(100, context),
                    width: Responsive.width(100, context),
                    decoration: BoxDecoration(
                      color: themeChange.getThem()
                          ? AppColors.darkBackground
                          : AppColors.background,
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(25),
                          topRight: Radius.circular(25)),
                    ),
                    child: controller.isLoading.value
                        ? Center(child: Constant.loader(context))
                        : Column(
                            children: [
                              // Header
                              Container(
                                width: Responsive.width(100, context),
                                padding: EdgeInsets.all(
                                    Responsive.width(5, context)),
                                child: Text(
                                  'Detalhes Bancários',
                                  style: GoogleFonts.poppins(
                                    fontSize: Responsive.width(5, context),
                                    fontWeight: FontWeight.w600,
                                    color: themeChange.getThem()
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                              // Content
                              Expanded(
                                child: SingleChildScrollView(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: Responsive.width(5, context),
                                    vertical: Responsive.height(1.2, context),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Bank Name
                                      _buildFormField(
                                        context,
                                        themeChange,
                                        label: "Bank Name".tr,
                                        child: TextFieldThem.buildTextFiled(
                                          context,
                                          hintText: 'Bank Name'.tr,
                                          controller: controller
                                              .bankNameController.value,
                                        ),
                                      ),

                                      SizedBox(
                                          height:
                                              Responsive.height(2, context)),

                                      // Branch Name
                                      _buildFormField(
                                        context,
                                        themeChange,
                                        label: "Branch Name".tr,
                                        child: TextFieldThem.buildTextFiled(
                                          context,
                                          hintText: 'Branch Name'.tr,
                                          keyBoardType: TextInputType.text,
                                          controller: controller
                                              .branchNameController.value,
                                        ),
                                      ),

                                      SizedBox(
                                          height:
                                              Responsive.height(2, context)),

                                      // Holder Name
                                      _buildFormField(
                                        context,
                                        themeChange,
                                        label: "Holder Name".tr,
                                        child: TextFieldThem.buildTextFiled(
                                          context,
                                          hintText: 'Holder Name'.tr,
                                          controller: controller
                                              .holderNameController.value,
                                        ),
                                      ),

                                      SizedBox(
                                          height:
                                              Responsive.height(2, context)),

                                      // Account Number
                                      _buildFormField(
                                        context,
                                        themeChange,
                                        label: "Account Number".tr,
                                        child: TextFieldThem.buildTextFiled(
                                          context,
                                          hintText: 'Account Number'.tr,
                                          keyBoardType: TextInputType.number,
                                          controller: controller
                                              .accountNumberController.value,
                                        ),
                                      ),

                                      SizedBox(
                                          height:
                                              Responsive.height(2, context)),

                                      // Other Information
                                      _buildFormField(
                                        context,
                                        themeChange,
                                        label: "Other Information".tr,
                                        child: TextFieldThem.buildTextFiled(
                                          context,
                                          hintText: 'Other Information'.tr,
                                          controller: controller
                                              .otherInformationController.value,
                                          maxLine: 3,
                                        ),
                                      ),

                                      SizedBox(
                                          height:
                                              Responsive.height(4, context)),

                                      // Information Card
                                      Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.all(
                                            Responsive.width(4, context)),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.blue.withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.info_outline,
                                              color: Colors.blue,
                                              size:
                                                  Responsive.width(5, context),
                                            ),
                                            SizedBox(
                                                width: Responsive.width(
                                                    3, context)),
                                            Expanded(
                                              child: Text(
                                                'Certifique-se de que os detalhes bancários estão corretos. Eles serão usados para transferências.',
                                                style: GoogleFonts.poppins(
                                                  fontSize: Responsive.width(
                                                      3, context),
                                                  color: Colors.blue.shade700,
                                                  height: 1.4,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      SizedBox(
                                          height:
                                              Responsive.height(4, context)),

                                      // Save Button
                                      Center(
                                        child: ButtonThem.buildButton(
                                          context,
                                          title: "Save".tr,
                                          btnWidthRatio: 0.8,
                                          onPress: () async {
                                            if (controller.bankNameController
                                                .value.text.isEmpty) {
                                              ShowToastDialog.showToast(
                                                  "Please enter bank name".tr);
                                            } else if (controller
                                                .branchNameController
                                                .value
                                                .text
                                                .isEmpty) {
                                              ShowToastDialog.showToast(
                                                  "Please enter branch name"
                                                      .tr);
                                            } else if (controller
                                                .holderNameController
                                                .value
                                                .text
                                                .isEmpty) {
                                              ShowToastDialog.showToast(
                                                  "Please enter holder name"
                                                      .tr);
                                            } else if (controller
                                                .accountNumberController
                                                .value
                                                .text
                                                .isEmpty) {
                                              ShowToastDialog.showToast(
                                                  "Please enter account number"
                                                      .tr);
                                            } else {
                                              ShowToastDialog.showLoader(
                                                  "Aguarde...".tr);
                                              BankDetailsModel
                                                  bankDetailsModel = controller
                                                      .bankDetailsModel.value;

                                              bankDetailsModel.userId =
                                                  FireStoreUtils
                                                      .getCurrentUid();
                                              bankDetailsModel.bankName =
                                                  controller.bankNameController
                                                      .value.text;
                                              bankDetailsModel.branchName =
                                                  controller
                                                      .branchNameController
                                                      .value
                                                      .text;
                                              bankDetailsModel.holderName =
                                                  controller
                                                      .holderNameController
                                                      .value
                                                      .text;
                                              bankDetailsModel.accountNumber =
                                                  controller
                                                      .accountNumberController
                                                      .value
                                                      .text;
                                              bankDetailsModel
                                                      .otherInformation =
                                                  controller
                                                      .otherInformationController
                                                      .value
                                                      .text;

                                              await FireStoreUtils
                                                      .updateBankDetails(
                                                          bankDetailsModel)
                                                  .then((value) {
                                                ShowToastDialog.closeLoader();
                                                ShowToastDialog.showToast(
                                                    "Bank details update successfully"
                                                        .tr);
                                              });
                                            }
                                          },
                                        ),
                                      ),

                                      SizedBox(
                                          height:
                                              Responsive.height(3, context)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          );
        });
  }

  Widget _buildFormField(
    BuildContext context,
    DarkThemeProvider themeChange, {
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: Responsive.width(3.5, context),
            color: themeChange.getThem() ? Colors.white70 : Colors.black87,
          ),
        ),
        SizedBox(height: Responsive.height(0.8, context)),
        child,
      ],
    );
  }
}
