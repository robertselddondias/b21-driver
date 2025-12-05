import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/controller/information_controller.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/responsive.dart';
import 'package:driver/themes/text_field_them.dart';
import 'package:driver/ui/dashboard_screen.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class InformationScreen extends StatelessWidget {
  const InformationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return GetX<InformationController>(
      init: InformationController(),
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
                  _buildFormContent(context, controller, themeChange),
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
      height: Responsive.height(30, context),
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
                padding: EdgeInsets.all(Responsive.width(2, context)),
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

          // Título sobre a imagem
          Positioned(
            bottom: Responsive.height(2, context),
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
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Bem-vindo ao B-21',
                    style: GoogleFonts.poppins(
                      fontSize: Responsive.width(5, context),
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

  /// Conteúdo do formulário
  Widget _buildFormContent(BuildContext context,
      InformationController controller, DarkThemeProvider themeChange) {
    return Padding(
      padding: EdgeInsets.all(Responsive.width(5, context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: Responsive.height(2, context)),

          // Seção de boas-vindas
          _buildWelcomeSection(context, themeChange),

          SizedBox(height: Responsive.height(3, context)),

          // Progresso do formulário
          _buildProgressIndicator(context, themeChange),

          SizedBox(height: Responsive.height(3, context)),

          // Campos do formulário
          _buildFormFields(context, controller, themeChange),

          SizedBox(height: Responsive.height(4, context)),

          // Botão de criar conta
          _buildCreateAccountButton(context, controller),

          SizedBox(height: Responsive.height(3, context)),
        ],
      ),
    );
  }

  /// Seção de boas-vindas
  Widget _buildWelcomeSection(
      BuildContext context, DarkThemeProvider themeChange) {
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
                Icons.person_add,
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
                    "Sign up".tr,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: Responsive.width(6, context),
                      color:
                          themeChange.getThem() ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    "Create your account to start using GoRide".tr,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w400,
                      fontSize: Responsive.width(3.5, context),
                      color: themeChange.getThem()
                          ? Colors.white70
                          : Colors.black54,
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
                Icons.info_outline,
                color: AppColors.primary,
                size: Responsive.width(5, context),
              ),
              SizedBox(width: Responsive.width(2, context)),
              Expanded(
                child: Text(
                  'Passo 2 de 3: Informações Pessoais',
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
            ],
          ),
        ],
      ),
    );
  }

  /// Campos do formulário
  Widget _buildFormFields(BuildContext context,
      InformationController controller, DarkThemeProvider themeChange) {
    return Column(
      children: [
        // Campo Nome Completo
        _buildFormField(
          context,
          label: 'Full name'.tr,
          icon: Icons.person,
          child: TextFieldThem.buildTextFiled(
            context,
            hintText: 'Full name'.tr,
            controller: controller.fullNameController.value,
            keyBoardType: TextInputType.name,
          ),
          themeChange: themeChange,
        ),

        SizedBox(height: Responsive.height(2.5, context)),

        // Campo Telefone
        _buildFormField(
          context,
          label: 'Phone number'.tr,
          icon: Icons.phone,
          child: _buildPhoneField(context, controller, themeChange),
          themeChange: themeChange,
        ),

        SizedBox(height: Responsive.height(2.5, context)),

        // Campo Email
        _buildFormField(
          context,
          label: 'Email'.tr,
          icon: Icons.email,
          child: TextFieldThem.buildTextFiled(
            context,
            hintText: 'Email'.tr,
            controller: controller.emailController.value,
            enable: controller.loginType.value == Constant.googleLoginType
                ? false
                : true,
            keyBoardType: TextInputType.emailAddress,
          ),
          themeChange: themeChange,
        ),
      ],
    );
  }

  /// Container para campos do formulário
  Widget _buildFormField(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Widget child,
    required DarkThemeProvider themeChange,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(Responsive.width(1.5, context)),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: Responsive.width(4.5, context),
              ),
            ),
            SizedBox(width: Responsive.width(2, context)),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: Responsive.width(4, context),
                color: themeChange.getThem() ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        SizedBox(height: Responsive.height(1, context)),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: child,
        ),
      ],
    );
  }

  /// Campo de telefone customizado
  Widget _buildPhoneField(BuildContext context,
      InformationController controller, DarkThemeProvider themeChange) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeChange.getThem()
              ? AppColors.darkTextFieldBorder
              : AppColors.textFieldBorder,
          width: 1.5,
        ),
      ),
      child: TextFormField(
        validator: (value) =>
            value != null && value.isNotEmpty ? null : 'Required',
        keyboardType: TextInputType.phone,
        textCapitalization: TextCapitalization.sentences,
        controller: controller.phoneNumberController.value,
        textAlign: TextAlign.start,
        inputFormatters: [controller.maskFormatter],
        enabled: controller.loginType.value == Constant.phoneLoginType
            ? false
            : true,
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
            padding:
                EdgeInsets.symmetric(horizontal: Responsive.width(2, context)),
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
          disabledBorder: OutlineInputBorder(
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
    );
  }

  /// Botão de criar conta
  Widget _buildCreateAccountButton(
      BuildContext context, InformationController controller) {
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
        onPressed: () => _handleCreateAccount(controller),
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
              Icons.account_circle,
              color: Colors.white,
              size: Responsive.width(5.5, context),
            ),
            SizedBox(width: Responsive.width(2, context)),
            Text(
              "Create account".tr,
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

  /// Manipula a criação da conta
  Future<void> _handleCreateAccount(InformationController controller) async {
    // Validações
    if (controller.fullNameController.value.text.isEmpty) {
      ShowToastDialog.showToast("Please enter full name".tr);
      return;
    }

    if (controller.emailController.value.text.isEmpty) {
      ShowToastDialog.showToast("Please enter email".tr);
      return;
    }

    if (controller.phoneNumberController.value.text.isEmpty) {
      ShowToastDialog.showToast("Please enter phone number".tr);
      return;
    }

    if (Constant.validateEmail(controller.emailController.value.text) ==
        false) {
      ShowToastDialog.showToast("Please enter valid email".tr);
      return;
    }

    try {
      ShowToastDialog.showLoader("Aguarde...".tr);

      DriverUserModel userModel = controller.userModel.value;
      userModel.fullName = controller.fullNameController.value.text.trim();
      userModel.email = controller.emailController.value.text.trim();
      userModel.countryCode = controller.countryCode.value;
      userModel.phoneNumber =
          controller.phoneNumberController.value.text.trim();
      userModel.documentVerification = false;
      userModel.isOnline = false;
      userModel.createdAt = Timestamp.now();

      final success = await FireStoreUtils.updateDriverUser(userModel);
      ShowToastDialog.closeLoader();

      if (success == true) {
        // Feedback de sucesso
        ShowToastDialog.showToast("Conta criada com sucesso!".tr);

        // Pequeno delay para mostrar o toast antes da navegação
        await Future.delayed(const Duration(milliseconds: 500));

        Get.offAll(const DashBoardScreen());
      } else {
        ShowToastDialog.showToast("Erro ao criar conta. Tente novamente.".tr);
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Erro inesperado. Tente novamente.".tr);
      print("Erro ao criar conta: $e");
    }
  }
}
