import 'dart:async';
import 'dart:developer';

import 'package:driver/constant/constant.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/controller/otp_controller.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/responsive.dart';
import 'package:driver/ui/auth_screen/information_screen.dart';
import 'package:driver/ui/dashboard_screen.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  Timer? _timer;
  int _resendCountdown = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _canResend = false;
    _resendCountdown = 60;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return GetX<OtpController>(
      init: OtpController(),
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
                  _buildOtpContent(context, controller, themeChange),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Imagem de cabeçalho responsiva
  Widget _buildHeaderImage(
      BuildContext context, DarkThemeProvider themeChange) {
    return Container(
      width: double.infinity,
      height: Responsive.height(32, context),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
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
                            : AppColors.background)
                        .withValues(alpha: 0.1),
                  ],
                ),
              ),
            ),
          ),

          // Botão voltar
          Positioned(
            top: Responsive.height(2, context),
            left: Responsive.width(4, context),
            child: InkWell(
              onTap: () => Get.back(),
              borderRadius: BorderRadius.circular(25),
              child: Container(
                padding: EdgeInsets.all(Responsive.width(2.5, context)),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: Responsive.width(5, context),
                ),
              ),
            ),
          ),

          // Ícone de verificação sobre a imagem
          Positioned(
            bottom: Responsive.height(2, context),
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(Responsive.width(4, context)),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Icon(
                    Icons.verified_user,
                    color: Colors.white,
                    size: Responsive.width(12, context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Conteúdo principal do OTP
  Widget _buildOtpContent(BuildContext context, OtpController controller,
      DarkThemeProvider themeChange) {
    return Padding(
      padding: EdgeInsets.all(Responsive.width(5, context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: Responsive.height(3, context)),

          // Seção de título e informações
          _buildHeaderSection(context, controller, themeChange),

          SizedBox(height: Responsive.height(4, context)),

          // Indicador de progresso
          _buildProgressIndicator(context, themeChange),

          SizedBox(height: Responsive.height(4, context)),

          // Campos PIN
          _buildPinCodeFields(context, controller, themeChange),

          SizedBox(height: Responsive.height(3, context)),

          // Botão de reenvio
          _buildResendSection(context, controller, themeChange),

          SizedBox(height: Responsive.height(4, context)),

          // Botão de verificar
          _buildVerifyButton(context, controller),

          SizedBox(height: Responsive.height(3, context)),
        ],
      ),
    );
  }

  /// Seção de cabeçalho com informações
  Widget _buildHeaderSection(BuildContext context, OtpController controller,
      DarkThemeProvider themeChange) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(Responsive.width(2.5, context)),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.security,
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
                    "Verify Phone Number".tr,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: Responsive.width(6, context),
                      color:
                          themeChange.getThem() ? Colors.white : Colors.black,
                    ),
                  ),
                  SizedBox(height: Responsive.height(0.5, context)),
                  RichText(
                    text: TextSpan(
                      text: "We just sent a verification code to\n".tr,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w400,
                        fontSize: Responsive.width(3.5, context),
                        color: themeChange.getThem()
                            ? Colors.white70
                            : Colors.black54,
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(
                          text:
                              "${controller.countryCode.value}${controller.phoneNumber.value}",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                            fontSize: Responsive.width(3.8, context),
                          ),
                        ),
                      ],
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

  /// Indicador de progresso
  Widget _buildProgressIndicator(
      BuildContext context, DarkThemeProvider themeChange) {
    return Container(
      padding: EdgeInsets.all(Responsive.width(4, context)),
      decoration: BoxDecoration(
        color: themeChange.getThem()
            ? AppColors.darkContainerBackground
            : AppColors.containerBackground,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: themeChange.getThem()
              ? AppColors.darkContainerBorder
              : AppColors.containerBorder,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.sms,
                color: AppColors.primary,
                size: Responsive.width(5, context),
              ),
              SizedBox(width: Responsive.width(2, context)),
              Expanded(
                child: Text(
                  'Passo 1 de 3: Verificação por SMS',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: Responsive.width(3.8, context),
                    color: themeChange.getThem() ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.height(1.5, context)),
          // Barra de progresso
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              SizedBox(width: Responsive.width(1, context)),
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              SizedBox(width: Responsive.width(1, context)),
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Campos de PIN responsivos
  Widget _buildPinCodeFields(BuildContext context, OtpController controller,
      DarkThemeProvider themeChange) {
    return Column(
      children: [
        Row(
          children: [
            Icon(
              Icons.pin,
              color: AppColors.primary,
              size: Responsive.width(5, context),
            ),
            SizedBox(width: Responsive.width(2, context)),
            Text(
              'Digite o código de 6 dígitos',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: Responsive.width(4, context),
                color: themeChange.getThem() ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        SizedBox(height: Responsive.height(2, context)),
        Container(
          padding: EdgeInsets.all(Responsive.width(4, context)),
          decoration: BoxDecoration(
            color: themeChange.getThem()
                ? AppColors.darkContainerBackground
                : AppColors.containerBackground,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: themeChange.getThem()
                  ? AppColors.darkContainerBorder
                  : AppColors.containerBorder,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: PinCodeTextField(
            length: 6,
            appContext: context,
            keyboardType: TextInputType.number,
            textStyle: GoogleFonts.poppins(
              fontSize: Responsive.width(5, context),
              fontWeight: FontWeight.w600,
              color: themeChange.getThem() ? Colors.white : Colors.black,
            ),
            pinTheme: PinTheme(
              fieldHeight: Responsive.width(14, context),
              fieldWidth: Responsive.width(12, context),
              activeColor: AppColors.primary,
              selectedColor: AppColors.primary.withValues(alpha: 0.5),
              inactiveColor:
                  themeChange.getThem() ? Colors.white24 : Colors.black26,
              activeFillColor: themeChange.getThem()
                  ? AppColors.darkTextField
                  : AppColors.textField,
              inactiveFillColor: themeChange.getThem()
                  ? AppColors.darkTextField.withValues(alpha: 0.5)
                  : AppColors.textField.withValues(alpha: 0.5),
              selectedFillColor: themeChange.getThem()
                  ? AppColors.darkTextField
                  : AppColors.textField,
              shape: PinCodeFieldShape.box,
              borderRadius: BorderRadius.circular(12),
              borderWidth: 2,
            ),
            enableActiveFill: true,
            cursorColor: AppColors.primary,
            controller: controller.otpController.value,
            animationType: AnimationType.scale,
            animationDuration: const Duration(milliseconds: 300),
            onCompleted: (v) async {},
            onChanged: (value) {},
          ),
        ),
      ],
    );
  }

  /// Seção de reenvio de código
  Widget _buildResendSection(BuildContext context, OtpController controller,
      DarkThemeProvider themeChange) {
    return Container(
      padding: EdgeInsets.all(Responsive.width(4, context)),
      decoration: BoxDecoration(
        color: (themeChange.getThem() ? Colors.orange : Colors.orange.shade100)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule,
            color: Colors.orange,
            size: Responsive.width(5, context),
          ),
          SizedBox(width: Responsive.width(3, context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _canResend
                      ? "Não recebeu o código?".tr
                      : "Reenviar código em:",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: Responsive.width(3.5, context),
                    color: Colors.orange,
                  ),
                ),
                if (!_canResend)
                  Text(
                    "${_resendCountdown}s",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: Responsive.width(4, context),
                      color: Colors.orange,
                    ),
                  ),
              ],
            ),
          ),
          if (_canResend)
            InkWell(
              onTap: () {
                _handleResendCode(controller);
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.width(4, context),
                  vertical: Responsive.height(1, context),
                ),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Reenviar".tr,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: Responsive.width(3.5, context),
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Botão de verificar
  Widget _buildVerifyButton(BuildContext context, OtpController controller) {
    return Container(
      width: double.infinity,
      height: Responsive.height(7, context),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primary],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => _handleVerifyOtp(controller),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.verified_user,
              color: Colors.white,
              size: Responsive.width(5.5, context),
            ),
            SizedBox(width: Responsive.width(2, context)),
            Text(
              "Verify".tr,
              style: GoogleFonts.poppins(
                fontSize: Responsive.width(4.5, context),
                fontWeight: FontWeight.w700,
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

  /// Manipula reenvio de código
  void _handleResendCode(OtpController controller) {
    ShowToastDialog.showToast("Código reenviado!".tr);
    _startResendTimer();
    // Aqui você pode adicionar a lógica para realmente reenviar o SMS
  }

  /// Manipula verificação do OTP
  Future<void> _handleVerifyOtp(OtpController controller) async {
    if (controller.otpController.value.text.length != 6) {
      ShowToastDialog.showToast("Please Enter Valid OTP".tr);
      return;
    }

    try {
      ShowToastDialog.showLoader("Verify OTP".tr);

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: controller.verificationId.value,
        smsCode: controller.otpController.value.text,
      );

      final authResult =
          await FirebaseAuth.instance.signInWithCredential(credential);

      if (authResult.additionalUserInfo!.isNewUser) {
        log("----->new user");
        DriverUserModel userModel = DriverUserModel();
        userModel.id = authResult.user!.uid;
        userModel.countryCode = controller.countryCode.value;
        userModel.phoneNumber = controller.phoneNumber.value;
        userModel.loginType = Constant.phoneLoginType;

        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("Verificação realizada com sucesso!".tr);

        await Future.delayed(const Duration(milliseconds: 500));
        Get.to(const InformationScreen(), arguments: {
          "userModel": userModel,
        });
      } else {
        log("----->old user");
        final userExists =
            await FireStoreUtils.userExitOrNot(authResult.user!.uid);
        ShowToastDialog.closeLoader();

        if (userExists == true) {
          ShowToastDialog.showToast("Login realizado com sucesso!".tr);
          await Future.delayed(const Duration(milliseconds: 500));
          Get.offAll(const DashBoardScreen());
        } else {
          DriverUserModel userModel = DriverUserModel();
          userModel.id = authResult.user!.uid;
          userModel.countryCode = controller.countryCode.value;
          userModel.phoneNumber = controller.phoneNumber.value;
          userModel.loginType = Constant.phoneLoginType;

          ShowToastDialog.showToast("Verificação realizada com sucesso!".tr);
          await Future.delayed(const Duration(milliseconds: 500));
          Get.to(const InformationScreen(), arguments: {
            "userModel": userModel,
          });
        }
      }
    } catch (error) {
      ShowToastDialog.closeLoader();
      log("Erro na verificação OTP: $error");

      if (error.toString().contains('invalid-verification-code')) {
        ShowToastDialog.showToast("Código de verificação inválido".tr);
      } else if (error.toString().contains('session-expired')) {
        ShowToastDialog.showToast(
            "Sessão expirada. Solicite um novo código".tr);
      } else {
        ShowToastDialog.showToast("Code is Invalid".tr);
      }
    }
  }
}
