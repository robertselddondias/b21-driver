// lib/ui/profile_screen.dart - Versão com temas e responsividade
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/controller/profile_controller.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/button_them.dart';
import 'package:driver/themes/responsive.dart';
import 'package:driver/themes/text_field_them.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return GetX<ProfileController>(
        init: ProfileController(),
        builder: (controller) {
          return Scaffold(
            backgroundColor: AppColors.primary,
            body: Column(
              children: [
                // Profile Header Section
                _buildProfileHeader(context, controller, themeChange),

                // Form Section
                Expanded(
                  child: Container(
                    width: Responsive.width(100, context),
                    decoration: BoxDecoration(
                      color: themeChange.getThem()
                          ? AppColors.darkBackground
                          : AppColors.background,
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(25),
                          topRight: Radius.circular(25)
                      ),
                    ),
                    child: controller.isLoading.value
                        ? Center(child: Constant.loader(context))
                        : Column(
                      children: [
                        // Title Section
                        Container(
                          width: Responsive.width(100, context),
                          padding: EdgeInsets.all(Responsive.width(5, context)),
                          child: Text(
                            'Editar Perfil',
                            style: GoogleFonts.poppins(
                              fontSize: Responsive.width(5, context),
                              fontWeight: FontWeight.w600,
                              color: themeChange.getThem() ? Colors.white : Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        // Form Content
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.symmetric(
                              horizontal: Responsive.width(5, context),
                              vertical: Responsive.height(1, context),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Full Name Field
                                _buildFormField(
                                  context,
                                  themeChange,
                                  label: 'Nome Completo',
                                  child: TextFieldThem.buildTextFiled(
                                    context,
                                    hintText: 'Full name'.tr,
                                    controller: controller.fullNameController.value,
                                  ),
                                ),

                                SizedBox(height: Responsive.height(2, context)),

                                // Phone Number Field
                                _buildFormField(
                                  context,
                                  themeChange,
                                  label: 'Número de Telefone',
                                  child: TextFormField(
                                    validator: (value) => value != null && value.isNotEmpty ? null : 'Required',
                                    keyboardType: TextInputType.number,
                                    textCapitalization: TextCapitalization.sentences,
                                    controller: controller.phoneNumberController.value,
                                    textAlign: TextAlign.start,
                                    enabled: false,
                                    style: GoogleFonts.poppins(
                                      color: themeChange.getThem() ? Colors.white70 : Colors.black54,
                                      fontSize: Responsive.width(3.5, context),
                                    ),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      filled: true,
                                      fillColor: themeChange.getThem()
                                          ? AppColors.darkTextField
                                          : AppColors.textField,
                                      contentPadding: EdgeInsets.symmetric(
                                          vertical: Responsive.height(1.5, context)
                                      ),
                                      prefixIcon: CountryCodePicker(
                                        onChanged: (value) {
                                          controller.countryCode.value = value.dialCode.toString();
                                        },
                                        dialogBackgroundColor: themeChange.getThem()
                                            ? AppColors.darkBackground
                                            : AppColors.background,
                                        initialSelection: controller.countryCode.value,
                                        comparator: (a, b) => b.name!.compareTo(a.name.toString()),
                                        flagDecoration: const BoxDecoration(
                                          borderRadius: BorderRadius.all(Radius.circular(2)),
                                        ),
                                        textStyle: GoogleFonts.poppins(
                                          color: themeChange.getThem() ? Colors.white70 : Colors.black54,
                                          fontSize: Responsive.width(3.5, context),
                                        ),
                                      ),
                                      hintText: "Phone number".tr,
                                      hintStyle: GoogleFonts.poppins(
                                        color: AppColors.subTitleColor,
                                        fontSize: Responsive.width(3.5, context),
                                      ),
                                      disabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                            color: themeChange.getThem()
                                                ? AppColors.darkTextFieldBorder
                                                : AppColors.textFieldBorder,
                                            width: 1
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: AppColors.primary,
                                          width: 2,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                            color: themeChange.getThem()
                                                ? AppColors.darkTextFieldBorder
                                                : AppColors.textFieldBorder,
                                            width: 1
                                        ),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: Colors.red,
                                          width: 1,
                                        ),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                            color: themeChange.getThem()
                                                ? AppColors.darkTextFieldBorder
                                                : AppColors.textFieldBorder,
                                            width: 1
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(height: Responsive.height(2, context)),

                                // Email Field
                                _buildFormField(
                                  context,
                                  themeChange,
                                  label: 'Email',
                                  child: TextFieldThem.buildTextFiled(
                                    context,
                                    hintText: 'Email'.tr,
                                    controller: controller.emailController.value,
                                    enable: false,
                                  ),
                                ),

                                SizedBox(height: Responsive.height(4, context)),

                                // Info Card
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(Responsive.width(4, context)),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.blue.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Colors.blue,
                                        size: Responsive.width(5, context),
                                      ),
                                      SizedBox(width: Responsive.width(3, context)),
                                      Expanded(
                                        child: Text(
                                          'O telefone e email não podem ser alterados por questões de segurança.',
                                          style: GoogleFonts.poppins(
                                            fontSize: Responsive.width(3, context),
                                            color: Colors.blue.shade700,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(height: Responsive.height(4, context)),

                                // Update Button
                                Center(
                                  child: ButtonThem.buildButton(
                                    context,
                                    title: "Update Profile".tr,
                                    btnWidthRatio: 0.8,
                                    onPress: () async {
                                      ShowToastDialog.showLoader("Aguarde...".tr);
                                      if (controller.profileImage.value.isNotEmpty) {
                                        controller.profileImage.value = await Constant.uploadUserImageToFireStorage(
                                            File(controller.profileImage.value),
                                            "profileImage/${FireStoreUtils.getCurrentUid()}",
                                            File(controller.profileImage.value).path.split('/').last
                                        );
                                      }

                                      DriverUserModel driverUserModel = controller.driverModel.value;
                                      driverUserModel.fullName = controller.fullNameController.value.text;
                                      driverUserModel.profilePic = controller.profileImage.value;

                                      FireStoreUtils.updateDriverUser(driverUserModel).then((value) {
                                        ShowToastDialog.closeLoader();
                                        ShowToastDialog.showToast("Profile update successfully".tr);
                                      });
                                    },
                                  ),
                                ),

                                SizedBox(height: Responsive.height(3, context)),
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

  Widget _buildProfileHeader(BuildContext context, ProfileController controller, DarkThemeProvider themeChange) {
    return Container(
      height: Responsive.height(32, context),
      width: Responsive.width(100, context),
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
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Profile Image
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: Responsive.width(28, context),
                  height: Responsive.width(28, context),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(Responsive.width(14, context)),
                    child: controller.profileImage.isEmpty
                        ? CachedNetworkImage(
                      imageUrl: Constant.userPlaceHolder,
                      fit: BoxFit.cover,
                      height: Responsive.width(28, context),
                      width: Responsive.width(28, context),
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade300,
                        child: Center(child: Constant.loader(context)),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade300,
                        child: Icon(
                          Icons.person,
                          size: Responsive.width(12, context),
                          color: Colors.grey,
                        ),
                      ),
                    )
                        : Constant().hasValidUrl(controller.profileImage.value) == false
                        ? Image.file(
                      File(controller.profileImage.value),
                      height: Responsive.width(28, context),
                      width: Responsive.width(28, context),
                      fit: BoxFit.cover,
                    )
                        : CachedNetworkImage(
                      imageUrl: controller.profileImage.value.toString(),
                      fit: BoxFit.cover,
                      height: Responsive.width(28, context),
                      width: Responsive.width(28, context),
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade300,
                        child: Center(child: Constant.loader(context)),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade300,
                        child: Icon(
                          Icons.person,
                          size: Responsive.width(12, context),
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),

                // Edit Button
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: () {
                      _buildBottomSheet(context, controller, themeChange);
                    },
                    child: Container(
                      width: Responsive.width(10, context),
                      height: Responsive.width(10, context),
                      decoration: BoxDecoration(
                        color: themeChange.getThem() ? AppColors.darkModePrimary : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        color: themeChange.getThem() ? Colors.black : AppColors.primary,
                        size: Responsive.width(5, context),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: Responsive.height(2, context)),

            // Name
            Text(
              'Meu Perfil',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: Responsive.width(5, context),
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(height: Responsive.height(0.5, context)),

            Text(
              'Gerencie suas informações pessoais',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: Responsive.width(3.2, context),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
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

  void _buildBottomSheet(BuildContext context, ProfileController controller, DarkThemeProvider themeChange) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: Responsive.height(25, context),
          decoration: BoxDecoration(
            color: themeChange.getThem() ? AppColors.darkBackground : AppColors.background,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Handle
              Container(
                margin: EdgeInsets.only(top: Responsive.height(1, context)),
                width: Responsive.width(12, context),
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.subTitleColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              SizedBox(height: Responsive.height(2, context)),

              // Title
              Text(
                "Please Select".tr,
                style: GoogleFonts.poppins(
                  fontSize: Responsive.width(4.5, context),
                  fontWeight: FontWeight.w600,
                  color: themeChange.getThem() ? Colors.white : Colors.black,
                ),
              ),

              SizedBox(height: Responsive.height(3, context)),

              // Options
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Camera Option
                  InkWell(
                    onTap: () => controller.pickFile(source: ImageSource.camera),
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      width: Responsive.width(35, context),
                      padding: EdgeInsets.all(Responsive.width(6, context)),
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
                          Container(
                            padding: EdgeInsets.all(Responsive.width(4, context)),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              size: Responsive.width(8, context),
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(height: Responsive.height(1, context)),
                          Text(
                            "Camera".tr,
                            style: GoogleFonts.poppins(
                              fontSize: Responsive.width(3.5, context),
                              fontWeight: FontWeight.w500,
                              color: themeChange.getThem() ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Gallery Option
                  InkWell(
                    onTap: () => controller.pickFile(source: ImageSource.gallery),
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      width: Responsive.width(35, context),
                      padding: EdgeInsets.all(Responsive.width(6, context)),
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
                          Container(
                            padding: EdgeInsets.all(Responsive.width(4, context)),
                            decoration: BoxDecoration(
                              color: AppColors.darkModePrimary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.photo_library_sharp,
                              size: Responsive.width(8, context),
                              color: AppColors.darkModePrimary,
                            ),
                          ),
                          SizedBox(height: Responsive.height(1, context)),
                          Text(
                            "Gallery".tr,
                            style: GoogleFonts.poppins(
                              fontSize: Responsive.width(3.5, context),
                              fontWeight: FontWeight.w500,
                              color: themeChange.getThem() ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}