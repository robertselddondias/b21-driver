import 'dart:developer';
import 'dart:io';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/controller/login_controller.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/button_them.dart';
import 'package:driver/themes/responsive.dart';
import 'package:driver/ui/auth_screen/information_screen.dart';
import 'package:driver/ui/dashboard_screen.dart';
import 'package:driver/ui/terms_and_condition/terms_and_condition_screen.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return GetX<LoginController>(
      init: LoginController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: themeChange.getThem()
              ? AppColors.darkBackground
              : AppColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderImage(context, themeChange),
                  _buildLoginContent(context, controller, themeChange),
                ],
              ),
            ),
          ),
          bottomNavigationBar: _buildTermsAndPrivacy(context, themeChange),
        );
      },
    );
  }

  /// Imagem de cabeçalho responsiva
  Widget _buildHeaderImage(BuildContext context, DarkThemeProvider themeChange) {
    return Container(
      width: double.infinity,
      height: Responsive.height(35, context),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Imagem de fundo
          Positioned.fill(
            child: Image.asset(
              "assets/images/login_image.png",
              width: Responsive.width(100, context),
              fit: BoxFit.cover,
            ),
          ),

          // Overlay com gradiente
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    (themeChange.getThem()
                        ? AppColors.darkBackground
                        : AppColors.background).withOpacity(0.1),
                  ],
                ),
              ),
            ),
          ),

          // Logo ou título sobre a imagem (opcional)
          Positioned(
            bottom: Responsive.height(3, context),
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.width(6, context),
                    vertical: Responsive.height(1, context),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'B-21 Motorista ',
                    style: GoogleFonts.poppins(
                      fontSize: Responsive.width(6, context),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Conteúdo principal do login
  Widget _buildLoginContent(BuildContext context, LoginController controller, DarkThemeProvider themeChange) {
    return Padding(
      padding: EdgeInsets.all(Responsive.width(5, context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: Responsive.height(3, context)),

          // Título e subtítulo
          _buildWelcomeSection(context, themeChange),

          SizedBox(height: Responsive.height(4, context)),

          // Campo de telefone
          _buildPhoneNumberField(context, controller, themeChange),

          SizedBox(height: Responsive.height(4, context)),

          // Botão Next
          _buildNextButton(context, controller),

          // Divider OR
          _buildOrDivider(context, themeChange),

          // Botões de login social
          _buildSocialLoginButtons(context, controller, themeChange),

          SizedBox(height: Responsive.height(3, context)),
        ],
      ),
    );
  }

  /// Seção de boas-vindas
  Widget _buildWelcomeSection(BuildContext context, DarkThemeProvider themeChange) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(Responsive.width(2, context)),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.login,
                color: AppColors.primary,
                size: Responsive.width(6, context),
              ),
            ),
            SizedBox(width: Responsive.width(3, context)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Login".tr,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: Responsive.width(6, context),
                      color: themeChange.getThem() ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    "Welcome Back! We are happy to have you back".tr,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w400,
                      fontSize: Responsive.width(3.5, context),
                      color: themeChange.getThem() ? Colors.white70 : Colors.black54,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Campo de número de telefone responsivo
  Widget _buildPhoneNumberField(BuildContext context, LoginController controller, DarkThemeProvider themeChange) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.phone_android,
              color: AppColors.primary,
              size: Responsive.width(5, context),
            ),
            SizedBox(width: Responsive.width(2, context)),
            Text(
              "Número de Telefone".tr,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: Responsive.width(4, context),
                color: themeChange.getThem() ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        SizedBox(height: Responsive.height(1.5, context)),

        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: themeChange.getThem()
                  ? AppColors.darkTextFieldBorder
                  : AppColors.textFieldBorder,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            validator: (value) => value != null && value.isNotEmpty ? null : 'Required',
            keyboardType: TextInputType.number,
            textCapitalization: TextCapitalization.sentences,
            controller: controller.phoneNumberController.value,
            textAlign: TextAlign.start,
            style: GoogleFonts.poppins(
              color: themeChange.getThem() ? Colors.white : Colors.black,
              fontSize: Responsive.width(4, context),
            ),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: themeChange.getThem()
                  ? AppColors.darkTextField
                  : AppColors.textField,
              contentPadding: EdgeInsets.symmetric(
                vertical: Responsive.height(2, context),
                horizontal: Responsive.width(1, context),
              ),
              prefixIcon: Container(
                padding: EdgeInsets.symmetric(horizontal: Responsive.width(2, context)),
                child: CountryCodePicker(
                  onChanged: (value) {
                    controller.countryCode.value = value.dialCode.toString();
                  },
                  dialogBackgroundColor: themeChange.getThem()
                      ? AppColors.darkBackground
                      : AppColors.background,
                  initialSelection: controller.countryCode.value,
                  comparator: (a, b) => b.name!.compareTo(a.name.toString()),
                  flagDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  textStyle: GoogleFonts.poppins(
                    fontSize: Responsive.width(3.5, context),
                    color: themeChange.getThem() ? Colors.white : Colors.black,
                  ),
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1.5),
              ),
              hintText: "Phone number".tr,
              hintStyle: GoogleFonts.poppins(
                color: themeChange.getThem() ? Colors.white54 : Colors.black54,
                fontSize: Responsive.width(3.5, context),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Botão Next responsivo
  Widget _buildNextButton(BuildContext context, LoginController controller) {
    return Container(
      width: double.infinity,
      height: Responsive.height(7, context),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primary],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          controller.sendCode();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Next".tr,
              style: GoogleFonts.poppins(
                fontSize: Responsive.width(4.5, context),
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            SizedBox(width: Responsive.width(2, context)),
            Icon(
              Icons.arrow_forward,
              color: Colors.white,
              size: Responsive.width(5, context),
            ),
          ],
        ),
      ),
    );
  }

  /// Divider com texto OR
  Widget _buildOrDivider(BuildContext context, DarkThemeProvider themeChange) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: Responsive.height(4, context),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: themeChange.getThem() ? Colors.white24 : Colors.black26,
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: Responsive.width(5, context)),
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.width(4, context),
              vertical: Responsive.height(1, context),
            ),
            decoration: BoxDecoration(
              color: themeChange.getThem()
                  ? AppColors.darkContainerBackground
                  : AppColors.containerBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: themeChange.getThem() ? Colors.white24 : Colors.black26,
              ),
            ),
            child: Text(
              "OR".tr,
              style: GoogleFonts.poppins(
                fontSize: Responsive.width(3.5, context),
                fontWeight: FontWeight.w600,
                color: themeChange.getThem() ? Colors.white : Colors.black,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: themeChange.getThem() ? Colors.white24 : Colors.black26,
            ),
          ),
        ],
      ),
    );
  }

  /// Botões de login social
  Widget _buildSocialLoginButtons(BuildContext context, LoginController controller, DarkThemeProvider themeChange) {
    return Column(
      children: [
        // Google Login
        _buildSocialButton(
          context,
          title: "Login with Google".tr,
          iconPath: 'assets/icons/ic_google.png',
          themeChange: themeChange,
          onPressed: () async {
            await _handleGoogleLogin(controller);
          },
        ),

        SizedBox(height: Responsive.height(2, context)),

        // Apple Login (apenas iOS)
        if (Platform.isIOS)
          _buildSocialButton(
            context,
            title: "Login with Apple".tr,
            iconPath: 'assets/icons/ic_apple.png',
            themeChange: themeChange,
            onPressed: () async {
              await _handleAppleLogin(controller);
            },
          ),
      ],
    );
  }

  /// Botão social personalizado
  Widget _buildSocialButton(
      BuildContext context, {
        required String title,
        required String iconPath,
        required DarkThemeProvider themeChange,
        required VoidCallback onPressed,
      }) {
    return Container(
      width: double.infinity,
      height: Responsive.height(6.5, context),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeChange.getThem()
              ? AppColors.darkContainerBorder
              : AppColors.containerBorder,
          width: 1.5,
        ),
        color: themeChange.getThem()
            ? AppColors.darkContainerBackground
            : AppColors.containerBackground,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              iconPath,
              width: Responsive.width(6, context),
              height: Responsive.width(6, context),
            ),
            SizedBox(width: Responsive.width(3, context)),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: Responsive.width(4, context),
                fontWeight: FontWeight.w600,
                color: themeChange.getThem() ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Termos e privacidade no bottom
  Widget _buildTermsAndPrivacy(BuildContext context, DarkThemeProvider themeChange) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.width(5, context),
        vertical: Responsive.height(2, context),
      ),
      decoration: BoxDecoration(
        color: themeChange.getThem()
            ? AppColors.darkBackground
            : AppColors.background,
        border: Border(
          top: BorderSide(
            color: themeChange.getThem() ? Colors.white24 : Colors.black12,
            width: 1,
          ),
        ),
      ),
      child: Text.rich(
        textAlign: TextAlign.center,
        TextSpan(
          text: 'By tapping "Next" you agree to '.tr,
          style: GoogleFonts.poppins(
            fontSize: Responsive.width(3.2, context),
            color: themeChange.getThem() ? Colors.white70 : Colors.black54,
          ),
          children: <TextSpan>[
            TextSpan(
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  Get.to(const TermsAndConditionScreen(type: "terms"));
                },
              text: 'Terms and conditions'.tr,
              style: GoogleFonts.poppins(
                decoration: TextDecoration.underline,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: Responsive.width(3.2, context),
              ),
            ),
            TextSpan(
              text: ' and ',
              style: GoogleFonts.poppins(
                fontSize: Responsive.width(3.2, context),
                color: themeChange.getThem() ? Colors.white70 : Colors.black54,
              ),
            ),
            TextSpan(
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  Get.to(const TermsAndConditionScreen(type: "privacy"));
                },
              text: 'privacy policy'.tr,
              style: GoogleFonts.poppins(
                decoration: TextDecoration.underline,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: Responsive.width(3.2, context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Manipula login do Google
  Future<void> _handleGoogleLogin(LoginController controller) async {
    ShowToastDialog.showLoader("Aguarde...".tr);

    try {
      final value = await controller.signInWithGoogle();
      ShowToastDialog.closeLoader();

      if (value != null) {
        if (value.additionalUserInfo!.isNewUser) {
          log("----->new user");
          DriverUserModel userModel = DriverUserModel();
          userModel.id = value.user!.uid;
          userModel.email = value.user!.email;
          userModel.fullName = value.user!.displayName;
          userModel.profilePic = value.user!.photoURL;
          userModel.loginType = Constant.googleLoginType;

          Get.to(const InformationScreen(), arguments: {
            "userModel": userModel,
          });
        } else {
          log("----->old user");
          final userExit = await FireStoreUtils.userExitOrNot(value.user!.uid);

          if (userExit == true) {
            Get.to(const DashBoardScreen());
          } else {
            DriverUserModel userModel = DriverUserModel();
            userModel.id = value.user!.uid;
            userModel.email = value.user!.email;
            userModel.fullName = value.user!.displayName;
            userModel.profilePic = value.user!.photoURL;
            userModel.loginType = Constant.googleLoginType;

            Get.to(const InformationScreen(), arguments: {
              "userModel": userModel,
            });
          }
        }
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Erro ao fazer login com Google".tr);
    }
  }

  /// Manipula login da Apple
  Future<void> _handleAppleLogin(LoginController controller) async {
    ShowToastDialog.showLoader("Aguarde...".tr);

    try {
      final value = await controller.signInWithApple();
      ShowToastDialog.closeLoader();

      if (value.additionalUserInfo!.isNewUser) {
        log("----->new user");
        DriverUserModel userModel = DriverUserModel();
        userModel.id = value.user!.uid;
        userModel.email = value.user!.email;
        userModel.profilePic = value.user!.photoURL;
        userModel.loginType = Constant.appleLoginType;

        Get.to(const InformationScreen(), arguments: {
          "userModel": userModel,
        });
      } else {
        log("----->old user");
        final userExit = await FireStoreUtils.userExitOrNot(value.user!.uid);

        if (userExit == true) {
          Get.to(const DashBoardScreen());
        } else {
          DriverUserModel userModel = DriverUserModel();
          userModel.id = value.user!.uid;
          userModel.email = value.user!.email;
          userModel.profilePic = value.user!.photoURL;
          userModel.loginType = Constant.appleLoginType;

          Get.to(const InformationScreen(), arguments: {
            "userModel": userModel,
          });
        }
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Erro ao fazer login com Apple".tr);
    }
  }
}