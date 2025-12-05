// lib/ui/setting_screen.dart - Versão com layout melhorado e compacto

import 'package:driver/constant/constant.dart';
import 'package:driver/constant/show_toast_dialog.dart';
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
import 'package:package_info_plus/package_info_plus.dart';

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
                            // Header melhorado
                            Padding(
                              padding:
                                  EdgeInsets.all(Responsive.width(4, context)),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(
                                        Responsive.width(2, context)),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.settings_outlined,
                                      color: AppColors.primary,
                                      size: Responsive.width(5, context),
                                    ),
                                  ),
                                  SizedBox(
                                      width: Responsive.width(2.5, context)),
                                  Text(
                                    'Configurações'.tr,
                                    style: GoogleFonts.poppins(
                                      fontSize: Responsive.width(4.2, context),
                                      fontWeight: FontWeight.w600,
                                      color: themeChange.getThem()
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
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
                                  // Theme Setting
                                  _buildSettingCard(
                                    context,
                                    themeChange,
                                    controller,
                                    icon: 'assets/icons/ic_light_drak.svg',
                                    title: "Light/dark mod".tr,
                                    subtitle: _getThemeSubtitle(
                                        controller.selectedMode.value),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal:
                                            Responsive.width(2.5, context),
                                        vertical:
                                            Responsive.height(0.5, context),
                                      ),
                                      decoration: BoxDecoration(
                                        color: themeChange.getThem()
                                            ? AppColors.darkContainerBackground
                                            : AppColors.containerBackground,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: themeChange.getThem()
                                              ? AppColors.darkContainerBorder
                                              : AppColors.containerBorder,
                                        ),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          isDense: true,
                                          isExpanded: false,
                                          value: controller.selectedMode.isEmpty
                                              ? null
                                              : controller.selectedMode.value,
                                          onChanged: (value) {
                                            controller.selectedMode.value =
                                                value!;
                                            Preferences.setString(
                                                Preferences.themKey,
                                                value.toString());
                                            if (controller.selectedMode.value ==
                                                "Dark mode") {
                                              themeChange.darkTheme = 0;
                                            } else if (controller
                                                    .selectedMode.value ==
                                                "Light mode") {
                                              themeChange.darkTheme = 1;
                                            } else {
                                              themeChange.darkTheme = 2;
                                            }
                                          },
                                          hint: Text(
                                            "select".tr,
                                            style: GoogleFonts.poppins(
                                              fontSize:
                                                  Responsive.width(3, context),
                                              color: AppColors.subTitleColor,
                                            ),
                                          ),
                                          icon: Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            color: themeChange.getThem()
                                                ? Colors.white54
                                                : Colors.black54,
                                            size:
                                                Responsive.width(4.5, context),
                                          ),
                                          dropdownColor: themeChange.getThem()
                                              ? AppColors
                                                  .darkContainerBackground
                                              : AppColors.containerBackground,
                                          items:
                                              controller.modeList.map((item) {
                                            return DropdownMenuItem(
                                              value: item,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    _getThemeIcon(item),
                                                    size: Responsive.width(
                                                        3.5, context),
                                                    color: themeChange.getThem()
                                                        ? Colors.white70
                                                        : Colors.black87,
                                                  ),
                                                  SizedBox(
                                                      width: Responsive.width(
                                                          1.5, context)),
                                                  Text(
                                                    item.toString(),
                                                    style: GoogleFonts.poppins(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize:
                                                          Responsive.width(
                                                              3, context),
                                                      color:
                                                          themeChange.getThem()
                                                              ? Colors.white
                                                              : Colors.black,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(
                                      height: Responsive.height(1.2, context)),

                                  // Support
                                  _buildSettingCard(
                                    context,
                                    themeChange,
                                    controller,
                                    icon: 'assets/icons/ic_support.svg',
                                    title: "Support".tr,
                                    subtitle: "Entre em contato conosco",
                                    isAction: true,
                                    onTap: () async {
                                      final Uri url = Uri.parse(
                                          Constant.supportURL.toString());
                                      if (!await launchUrl(url)) {
                                        throw Exception(
                                          'Could not launch ${Constant.supportURL.toString()}'
                                              .tr,
                                        );
                                      }
                                    },
                                  ),

                                  SizedBox(
                                      height: Responsive.height(1.2, context)),

                                  // Delete Account
                                  _buildSettingCard(
                                    context,
                                    themeChange,
                                    controller,
                                    icon: 'assets/icons/ic_delete.svg',
                                    title: "Delete Account".tr,
                                    subtitle:
                                        "Excluir permanentemente sua conta",
                                    isAction: true,
                                    isDangerous: true,
                                    onTap: () {
                                      _showDeleteAccountDialog(
                                          context, themeChange);
                                    },
                                  ),
                                ],
                              ),
                            ),

                            // Version Footer com FutureBuilder
                            _buildVersionFooter(context, themeChange),
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

  /// Footer de versão com informações do package
  Widget _buildVersionFooter(
      BuildContext context, DarkThemeProvider themeChange) {
    return Container(
      padding: EdgeInsets.all(Responsive.width(4, context)),
      child: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          String versionText = "Carregando...";

          if (snapshot.hasData) {
            final packageInfo = snapshot.data!;
            versionText =
                "Versão ${packageInfo.version} (${packageInfo.buildNumber})";
          } else if (snapshot.hasError) {
            versionText = "Versão ${Constant.appVersion}";
          }

          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.width(3, context),
              vertical: Responsive.height(0.8, context),
            ),
            decoration: BoxDecoration(
              color: themeChange.getThem()
                  ? AppColors.darkContainerBackground
                  : AppColors.containerBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: themeChange.getThem()
                    ? AppColors.darkContainerBorder
                    : AppColors.containerBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  size: Responsive.width(3.5, context),
                  color: AppColors.subTitleColor,
                ),
                SizedBox(width: Responsive.width(1.5, context)),
                Text(
                  versionText,
                  style: GoogleFonts.poppins(
                    fontSize: Responsive.width(2.8, context),
                    color: AppColors.subTitleColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettingCard(
    BuildContext context,
    DarkThemeProvider themeChange,
    SettingController controller, {
    required String icon,
    required String title,
    String? subtitle,
    Widget? child,
    bool isAction = false,
    bool isDangerous = false,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: Responsive.height(0.3, context)),
      decoration: BoxDecoration(
        color: themeChange.getThem()
            ? AppColors.darkContainerBackground
            : AppColors.containerBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
                      color: isDangerous
                          ? Colors.red.withValues(alpha: 0.3)                 : (themeChange.getThem()
                    ? AppColors.darkContainerBorder
                    : AppColors.containerBorder),
          width: 1,
        ),
        boxShadow: themeChange.getThem()
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: EdgeInsets.all(Responsive.width(3.5, context)),
          child: Row(
            children: [
              // Icon Container
              Container(
                width: Responsive.width(10, context),
                height: Responsive.width(10, context),
                decoration: BoxDecoration(
                            color: isDangerous
                                ? Colors.red.withValues(alpha: 0.1)                      : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    icon,
                    width: Responsive.width(4.5, context),
                    height: Responsive.width(4.5, context),
                    color: isDangerous ? Colors.red : AppColors.primary,
                  ),
                ),
              ),

              SizedBox(width: Responsive.width(2.5, context)),

              // Title and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: Responsive.width(3.5, context),
                        color: isDangerous
                            ? Colors.red
                            : (themeChange.getThem()
                                ? Colors.white
                                : Colors.black87),
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: Responsive.height(0.2, context)),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: Responsive.width(2.8, context),
                          color: themeChange.getThem()
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
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
                          ? Colors.grey.shade600
                          : Colors.grey.shade400),
                  size: Responsive.width(4.5, context),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getThemeSubtitle(String mode) {
    switch (mode) {
      case "Dark mode":
        return "Modo escuro ativado";
      case "Light mode":
        return "Modo claro ativado";
      case "System":
        return "Segue o sistema";
      default:
        return "Selecione um tema";
    }
  }

  IconData _getThemeIcon(String mode) {
    switch (mode) {
      case "Dark mode":
        return Icons.dark_mode_outlined;
      case "Light mode":
        return Icons.light_mode_outlined;
      case "System":
        return Icons.settings_suggest_outlined;
      default:
        return Icons.brightness_auto;
    }
  }

  void _showDeleteAccountDialog(
      BuildContext context, DarkThemeProvider themeChange) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: themeChange.getThem()
              ? AppColors.darkContainerBackground
              : AppColors.containerBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
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
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.warning_rounded,
                  color: Colors.red,
                  size: Responsive.width(5, context),
                ),
              ),
              SizedBox(width: Responsive.width(2.5, context)),
              Expanded(
                child: Text(
                  "Account delete".tr,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: Responsive.width(4, context),
                    color: themeChange.getThem() ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ],
          ),
          content: Padding(
            padding:
                EdgeInsets.symmetric(vertical: Responsive.height(0.5, context)),
            child: Text(
              "Are you sure want to delete Account.".tr,
              style: GoogleFonts.poppins(
                fontSize: Responsive.width(3.2, context),
                color: themeChange.getThem() ? Colors.white70 : Colors.black87,
                height: 1.4,
              ),
            ),
          ),
          actionsPadding: EdgeInsets.all(Responsive.width(3, context)),
          actions: [
            // Cancel Button
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    vertical: Responsive.height(1.2, context),
                  ),
                  side: BorderSide(
                    color: themeChange.getThem()
                        ? AppColors.darkContainerBorder
                        : AppColors.containerBorder,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  "Cancel".tr,
                  style: GoogleFonts.poppins(
                    color:
                        themeChange.getThem() ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: Responsive.width(3.2, context),
                  ),
                ),
                onPressed: () {
                  Get.back();
                },
              ),
            ),

            SizedBox(width: Responsive.width(2.5, context)),

            // Delete Button
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(
                    vertical: Responsive.height(1.2, context),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  "Delete".tr,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: Responsive.width(3.2, context),
                  ),
                ),
                onPressed: () async {
                  Get.back();
                  ShowToastDialog.showLoader("Aguarde...".tr);
                  await FireStoreUtils.deleteUser().then((value) {
                    ShowToastDialog.closeLoader();
                    if (value == true) {
                      ShowToastDialog.showToast("Account delete".tr);
                      Get.offAll(const LoginScreen());
                    } else {
                      ShowToastDialog.showToast(
                          "Please contact to administrator".tr);
                    }
                  });
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
