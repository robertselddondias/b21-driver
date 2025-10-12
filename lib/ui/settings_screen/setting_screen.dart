// lib/ui/setting_screen.dart - Versão com temas e responsividade
import 'dart:convert';

import 'package:driver/constant/constant.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/services/localization_service.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/responsive.dart';
import 'package:driver/ui/auth_screen/login_screen.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:driver/utils/Preferences.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controller/setting_controller.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return GetBuilder<SettingController>(
      init: SettingController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: AppColors.primary,
          body: controller.isLoading.value
              ? Center(child: Constant.loader(context))
              : Column(
            children: [
              SizedBox(
                height: Responsive.height(6, context),
                width: Responsive.width(100, context),
              ),
              Expanded(
                child: Container(
                  width: Responsive.width(100, context),
                  decoration: BoxDecoration(
                    color: themeChange.getThem()
                        ? AppColors.darkBackground
                        : AppColors.background,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        width: Responsive.width(100, context),
                        padding: EdgeInsets.all(Responsive.width(5, context)),
                        child: Text(
                          'Configurações',
                          style: GoogleFonts.poppins(
                            fontSize: Responsive.width(5, context),
                            fontWeight: FontWeight.w600,
                            color: themeChange.getThem() ? Colors.white : Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      // Content
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.width(4, context),
                            vertical: Responsive.height(1, context),
                          ),
                          children: [

                            SizedBox(height: Responsive.height(1, context)),

                            // Theme Setting
                            _buildSettingCard(
                              context,
                              themeChange,
                              icon: 'assets/icons/ic_light_drak.svg',
                              title: "Light/dark mod".tr,
                              child: SizedBox(
                                width: Responsive.width(30, context),
                                child: DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: Responsive.width(3, context),
                                      vertical: Responsive.height(0.8, context),
                                    ),
                                    filled: true,
                                    fillColor: themeChange.getThem()
                                        ? AppColors.darkContainerBackground
                                        : AppColors.containerBackground,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: themeChange.getThem()
                                            ? AppColors.darkContainerBorder
                                            : AppColors.containerBorder,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: themeChange.getThem()
                                            ? AppColors.darkContainerBorder
                                            : AppColors.containerBorder,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: AppColors.primary,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  value: controller.selectedMode.isEmpty
                                      ? null
                                      : controller.selectedMode.value,
                                  onChanged: (value) {
                                    controller.selectedMode.value = value!;
                                    Preferences.setString(Preferences.themKey, value.toString());
                                    if (controller.selectedMode.value == "Dark mode") {
                                      themeChange.darkTheme = 0;
                                    } else if (controller.selectedMode.value == "Light mode") {
                                      themeChange.darkTheme = 1;
                                    } else {
                                      themeChange.darkTheme = 2;
                                    }
                                  },
                                  hint: Text(
                                    "select".tr,
                                    style: GoogleFonts.poppins(
                                      fontSize: Responsive.width(3.2, context),
                                      color: AppColors.subTitleColor,
                                    ),
                                  ),
                                  items: controller.modeList.map((item) {
                                    return DropdownMenuItem(
                                      value: item,
                                      child: Text(
                                        item.toString(),
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w500,
                                          fontSize: Responsive.width(3.2, context),
                                          color: themeChange.getThem()
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),

                            SizedBox(height: Responsive.height(1, context)),

                            // Support
                            _buildSettingCard(
                              context,
                              themeChange,
                              icon: 'assets/icons/ic_support.svg',
                              title: "Support".tr,
                              isAction: true,
                              onTap: () async {
                                final Uri url = Uri.parse(Constant.supportURL.toString());
                                if (!await launchUrl(url)) {
                                  throw Exception(
                                    'Could not launch ${Constant.supportURL.toString()}'.tr,
                                  );
                                }
                              },
                            ),

                            SizedBox(height: Responsive.height(1, context)),

                            // Delete Account
                            _buildSettingCard(
                              context,
                              themeChange,
                              icon: 'assets/icons/ic_delete.svg',
                              title: "Delete Account".tr,
                              isAction: true,
                              isDangerous: true,
                              onTap: () {
                                _showDeleteAccountDialog(context, themeChange);
                              },
                            ),
                          ],
                        ),
                      ),

                      // Version Footer
                      Container(
                        padding: EdgeInsets.all(Responsive.width(5, context)),
                        child: Text(
                          "V ${Constant.appVersion}",
                          style: GoogleFonts.poppins(
                            fontSize: Responsive.width(3, context),
                            color: AppColors.subTitleColor,
                            fontWeight: FontWeight.w400,
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
      },
    );
  }

  Widget _buildSettingCard(
      BuildContext context,
      DarkThemeProvider themeChange, {
        required String icon,
        required String title,
        Widget? child,
        bool isAction = false,
        bool isDangerous = false,
        VoidCallback? onTap,
      }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: Responsive.height(0.5, context)),
      decoration: BoxDecoration(
        color: themeChange.getThem()
            ? AppColors.darkContainerBackground
            : AppColors.containerBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDangerous
              ? Colors.red.withOpacity(0.3)
              : (themeChange.getThem()
              ? AppColors.darkContainerBorder
              : AppColors.containerBorder),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(Responsive.width(4, context)),
          child: Row(
            children: [
              // Icon Container
              Container(
                padding: EdgeInsets.all(Responsive.width(2.5, context)),
                decoration: BoxDecoration(
                  color: isDangerous
                      ? Colors.red.withOpacity(0.1)
                      : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SvgPicture.asset(
                  icon,
                  width: Responsive.width(5, context),
                  height: Responsive.width(5, context),
                  color: isDangerous ? Colors.red : AppColors.primary,
                ),
              ),

              SizedBox(width: Responsive.width(4, context)),

              // Title
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: Responsive.width(3.8, context),
                    color: isDangerous
                        ? Colors.red
                        : (themeChange.getThem() ? Colors.white : Colors.black87),
                  ),
                ),
              ),

              // Child widget or arrow
              if (child != null)
                child
              else if (isAction)
                Icon(
                  Icons.chevron_right,
                  color: isDangerous
                      ? Colors.red
                      : (themeChange.getThem()
                      ? Colors.white54
                      : Colors.black54),
                  size: Responsive.width(5, context),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, DarkThemeProvider themeChange) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: themeChange.getThem()
              ? AppColors.darkContainerBackground
              : AppColors.containerBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(
              color: themeChange.getThem()
                  ? AppColors.darkContainerBorder
                  : AppColors.containerBorder,
              width: 1,
            ),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(Responsive.width(2, context)),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.warning_rounded,
                  color: Colors.red,
                  size: Responsive.width(5, context),
                ),
              ),
              SizedBox(width: Responsive.width(3, context)),
              Expanded(
                child: Text(
                  "Account delete".tr,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: Responsive.width(4.2, context),
                    color: themeChange.getThem() ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ],
          ),
          content: Padding(
            padding: EdgeInsets.symmetric(vertical: Responsive.height(1, context)),
            child: Text(
              "Are you sure want to delete Account.".tr,
              style: GoogleFonts.poppins(
                fontSize: Responsive.width(3.5, context),
                color: themeChange.getThem() ? Colors.white70 : Colors.black87,
                height: 1.4,
              ),
            ),
          ),
          actions: [
            // Cancel Button
            TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.width(5, context),
                  vertical: Responsive.height(1, context),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: themeChange.getThem()
                        ? AppColors.darkContainerBorder
                        : AppColors.containerBorder,
                  ),
                ),
              ),
              child: Text(
                "Cancel".tr,
                style: GoogleFonts.poppins(
                  color: AppColors.subTitleColor,
                  fontWeight: FontWeight.w500,
                  fontSize: Responsive.width(3.5, context),
                ),
              ),
              onPressed: () {
                Get.back();
              },
            ),

            SizedBox(width: Responsive.width(2, context)),

            // Delete Button
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.width(5, context),
                  vertical: Responsive.height(1, context),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                "Delete".tr,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: Responsive.width(3.5, context),
                ),
              ),
              onPressed: () async {
                Get.back(); // Fecha o dialog primeiro
                ShowToastDialog.showLoader("Aguarde...".tr);
                await FireStoreUtils.deleteUser().then((value) {
                  ShowToastDialog.closeLoader();
                  if (value == true) {
                    ShowToastDialog.showToast("Account delete".tr);
                    Get.offAll(const LoginScreen());
                  } else {
                    ShowToastDialog.showToast("Please contact to administrator".tr);
                  }
                });
              },
            ),
          ],
        );
      },
    );
  }
}