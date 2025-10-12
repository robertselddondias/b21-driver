import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/controller/details_upload_controller.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/responsive.dart';
import 'package:driver/themes/text_field_them.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DetailsUploadScreen extends StatelessWidget {
  const DetailsUploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return GetX<DetailsUploadController>(
      init: DetailsUploadController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: AppColors.primary,
          appBar: _buildAppBar(context, controller, themeChange),
          body: Column(
            children: [
              SizedBox(height: Responsive.height(3, context)),
              Expanded(
                child: _buildMainContent(context, controller, themeChange),
              ),
            ],
          ),
        );
      },
    );
  }

  /// AppBar responsiva e temática
  PreferredSizeWidget _buildAppBar(BuildContext context, DetailsUploadController controller, DarkThemeProvider themeChange) {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      centerTitle: true,
      title: Text(
        controller.documentModel.value.title.toString(),
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: Responsive.width(4.5, context),
          fontWeight: FontWeight.w600,
        ),
      ),
      leading: InkWell(
        onTap: () => Get.back(),
        borderRadius: BorderRadius.circular(25),
        child: Container(
          margin: EdgeInsets.all(Responsive.width(2, context)),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: Responsive.width(5, context),
          ),
        ),
      ),
      actions: [
        Container(
          margin: EdgeInsets.all(Responsive.width(2, context)),
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.width(3, context),
            vertical: Responsive.height(0.5, context),
          ),
          decoration: BoxDecoration(
            color: controller.documents.value.verified == true
                ? Colors.green.withOpacity(0.2)
                : Colors.orange.withOpacity(0.2),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: controller.documents.value.verified == true
                  ? Colors.green
                  : Colors.orange,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                controller.documents.value.verified == true
                    ? Icons.verified
                    : Icons.pending,
                color: controller.documents.value.verified == true
                    ? Colors.green
                    : Colors.orange,
                size: Responsive.width(4, context),
              ),
              SizedBox(width: Responsive.width(1, context)),
              Text(
                controller.documents.value.verified == true ? 'Verificado' : 'Pendente',
                style: GoogleFonts.poppins(
                  color: controller.documents.value.verified == true
                      ? Colors.green
                      : Colors.orange,
                  fontSize: Responsive.width(3, context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Conteúdo principal
  Widget _buildMainContent(BuildContext context, DetailsUploadController controller, DarkThemeProvider themeChange) {
    return Container(
      decoration: BoxDecoration(
        color: themeChange.getThem() ? AppColors.darkBackground : AppColors.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: controller.isLoading.value
          ? Constant.loader(context)
          : SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(Responsive.width(5, context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com informações
            _buildDocumentHeader(context, controller, themeChange),

            SizedBox(height: Responsive.height(3, context)),

            // Progresso
            _buildProgressIndicator(context, themeChange),

            SizedBox(height: Responsive.height(3, context)),

            // Campo do número do documento
            _buildDocumentNumberField(context, controller, themeChange),

            // Campo de data de expiração (se necessário)
            if (controller.documentModel.value.expireAt == true) ...[
              SizedBox(height: Responsive.height(2, context)),
              _buildExpirationDateField(context, controller, themeChange),
            ],

            SizedBox(height: Responsive.height(3, context)),

            // Upload de imagens
            _buildImageUploadSection(context, controller, themeChange),

            SizedBox(height: Responsive.height(4, context)),

            // Botão de envio
            if (controller.documents.value.verified != true)
              _buildSubmitButton(context, controller),

            SizedBox(height: Responsive.height(2, context)),
          ],
        ),
      ),
    );
  }

  /// Header com informações do documento
  Widget _buildDocumentHeader(BuildContext context, DetailsUploadController controller, DarkThemeProvider themeChange) {
    return Column(
      children: [
        // Indicador de arraste
        Container(
          width: Responsive.width(12, context),
          height: Responsive.height(0.6, context),
          decoration: BoxDecoration(
            color: themeChange.getThem() ? Colors.white24 : Colors.black26,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        SizedBox(height: Responsive.height(2, context)),

        // Header informativo
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(Responsive.width(3, context)),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                Icons.description,
                color: AppColors.primary,
                size: Responsive.width(7, context),
              ),
            ),
            SizedBox(width: Responsive.width(4, context)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upload de Documento',
                    style: GoogleFonts.poppins(
                      fontSize: Responsive.width(5.5, context),
                      fontWeight: FontWeight.bold,
                      color: themeChange.getThem() ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    'Envie ${controller.documentModel.value.title}',
                    style: GoogleFonts.poppins(
                      fontSize: Responsive.width(3.5, context),
                      color: themeChange.getThem() ? Colors.white70 : Colors.black54,
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
  Widget _buildProgressIndicator(BuildContext context, DarkThemeProvider themeChange) {
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
                Icons.upload_file,
                color: AppColors.primary,
                size: Responsive.width(5, context),
              ),
              SizedBox(width: Responsive.width(2, context)),
              Expanded(
                child: Text(
                  'Passo 3 de 3: Documentos',
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
                    color: AppColors.primary,
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

  /// Campo do número do documento
  Widget _buildDocumentNumberField(BuildContext context, DetailsUploadController controller, DarkThemeProvider themeChange) {
    return _buildFormField(
      context,
      label: 'Número do ${controller.documentModel.value.title}',
      icon: Icons.numbers,
      themeChange: themeChange,
      child: TextFieldThem.buildTextMask(
        context,
        inputMaskFormatter: controller.cnhMaskFormatter,
        hintText: controller.documentModel.value.title.toString(),
        controller: controller.documentNumberController.value,
        keyBoardType: TextInputType.number,
      ),
    );
  }

  /// Campo de data de expiração
  Widget _buildExpirationDateField(BuildContext context, DetailsUploadController controller, DarkThemeProvider themeChange) {
    return _buildFormField(
      context,
      label: 'Data de Expiração',
      icon: Icons.calendar_today,
      themeChange: themeChange,
      child: InkWell(
        onTap: () async {
          final selectedDate = await Constant.selectFetureDate(context);
          if (selectedDate != null) {
            controller.selectedDate.value = selectedDate;
            controller.expireAtController.value.text = DateFormat("dd/MM/yyyy").format(selectedDate);
          }
        },
        child: TextFieldThem.buildTextFiledWithSuffixIcon(
          context,
          hintText: "Informe a data de Expiração".tr,
          controller: controller.expireAtController.value,
          enable: false,
          suffixIcon: Icon(
            Icons.calendar_month,
            color: AppColors.primary,
            size: Responsive.width(5, context),
          ),
        ),
      ),
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
                color: AppColors.primary.withOpacity(0.1),
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
        child,
      ],
    );
  }

  /// Seção de upload de imagens
  Widget _buildImageUploadSection(BuildContext context, DetailsUploadController controller, DarkThemeProvider themeChange) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título da seção
        Row(
          children: [
            Icon(
              Icons.photo_camera,
              color: AppColors.primary,
              size: Responsive.width(5, context),
            ),
            SizedBox(width: Responsive.width(2, context)),
            Text(
              'Fotos do Documento',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: Responsive.width(4.5, context),
                color: themeChange.getThem() ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        SizedBox(height: Responsive.height(2, context)),

        // Upload da frente (se necessário)
        if (controller.documentModel.value.frontSide == true) ...[
          _buildImageUploadCard(
            context,
            controller,
            themeChange,
            title: "Frente ${controller.documentModel.value.title}",
            type: "front",
            imagePath: controller.frontImage.value,
          ),
          SizedBox(height: Responsive.height(2, context)),
        ],

        // Upload do verso (se necessário)
        if (controller.documentModel.value.backSide == true) ...[
          _buildImageUploadCard(
            context,
            controller,
            themeChange,
            title: "Verso ${controller.documentModel.value.title}",
            type: "back",
            imagePath: controller.backImage.value,
          ),
        ],
      ],
    );
  }

  /// Card de upload de imagem
  Widget _buildImageUploadCard(
      BuildContext context,
      DetailsUploadController controller,
      DarkThemeProvider themeChange, {
        required String title,
        required String type,
        required String imagePath,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: Responsive.width(4, context),
            fontWeight: FontWeight.w600,
            color: themeChange.getThem() ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: Responsive.height(1, context)),

        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: imagePath.isNotEmpty
              ? _buildImagePreview(context, controller, themeChange, imagePath, type)
              : _buildImagePlaceholder(context, controller, themeChange, type),
        ),
      ],
    );
  }

  /// Preview da imagem selecionada
  Widget _buildImagePreview(
      BuildContext context,
      DetailsUploadController controller,
      DarkThemeProvider themeChange,
      String imagePath,
      String type,
      ) {
    return InkWell(
      onTap: () {
        if (controller.documents.value.verified != true) {
          _buildBottomSheet(context, controller, type, themeChange);
        }
      },
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: Responsive.height(25, context),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Constant().hasValidUrl(imagePath) == false
                  ? Image.file(
                File(imagePath),
                height: double.infinity,
                width: double.infinity,
                fit: BoxFit.cover,
              )
                  : CachedNetworkImage(
                imageUrl: imagePath,
                fit: BoxFit.cover,
                height: double.infinity,
                width: double.infinity,
                placeholder: (context, url) => Constant.loader(context),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: Icon(
                    Icons.error,
                    color: Colors.red,
                    size: Responsive.width(10, context),
                  ),
                ),
              ),
            ),

            // Overlay de sucesso/edição
            if (controller.documents.value.verified != true)
              Positioned(
                top: Responsive.width(3, context),
                right: Responsive.width(3, context),
                child: Container(
                  padding: EdgeInsets.all(Responsive.width(2, context)),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: Responsive.width(4.5, context),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Placeholder para upload de imagem
  Widget _buildImagePlaceholder(
      BuildContext context,
      DetailsUploadController controller,
      DarkThemeProvider themeChange,
      String type,
      ) {
    return InkWell(
      onTap: () {
        _buildBottomSheet(context, controller, type, themeChange);
      },
      borderRadius: BorderRadius.circular(15),
      child: DottedBorder(
        borderType: BorderType.RRect,
        radius: const Radius.circular(15),
        dashPattern: const [8, 4],
        color: themeChange.getThem() ? Colors.white54 : Colors.black54,
        strokeWidth: 2,
        child: Container(
          height: Responsive.height(25, context),
          width: double.infinity,
          decoration: BoxDecoration(
            color: themeChange.getThem()
                ? AppColors.darkContainerBackground.withOpacity(0.3)
                : AppColors.containerBackground.withOpacity(0.7),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(Responsive.width(4, context)),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  Icons.add_a_photo,
                  size: Responsive.width(10, context),
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: Responsive.height(2, context)),
              Text(
                "Adicionar Foto".tr,
                style: GoogleFonts.poppins(
                  fontSize: Responsive.width(4, context),
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: Responsive.height(0.5, context)),
              Text(
                "Toque para selecionar",
                style: GoogleFonts.poppins(
                  fontSize: Responsive.width(3, context),
                  color: themeChange.getThem() ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Botão de envio
  Widget _buildSubmitButton(BuildContext context, DetailsUploadController controller) {
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
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => _handleSubmit(controller),
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
              Icons.upload,
              color: Colors.white,
              size: Responsive.width(5.5, context),
            ),
            SizedBox(width: Responsive.width(2, context)),
            Text(
              "Enviar".tr,
              style: GoogleFonts.poppins(
                fontSize: Responsive.width(4.5, context),
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            SizedBox(width: Responsive.width(2, context)),
            Icon(
              Icons.check,
              color: Colors.white,
              size: Responsive.width(5, context),
            ),
          ],
        ),
      ),
    );
  }

  /// Bottom sheet para seleção de imagem
  void _buildBottomSheet(BuildContext context, DetailsUploadController controller, String type, DarkThemeProvider themeChange) {
    showModalBottomSheet(
      context: context,
      backgroundColor: themeChange.getThem()
          ? AppColors.darkContainerBackground
          : AppColors.containerBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      builder: (context) {
        return Container(
          height: Responsive.height(30, context),
          padding: EdgeInsets.all(Responsive.width(5, context)),
          child: Column(
            children: [
              // Indicador de arraste
              Container(
                width: Responsive.width(12, context),
                height: Responsive.height(0.6, context),
                decoration: BoxDecoration(
                  color: themeChange.getThem() ? Colors.white24 : Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              SizedBox(height: Responsive.height(2, context)),

              // Título
              Text(
                "Selecione uma opção".tr,
                style: GoogleFonts.poppins(
                  fontSize: Responsive.width(5, context),
                  fontWeight: FontWeight.w600,
                  color: themeChange.getThem() ? Colors.white : Colors.black,
                ),
              ),

              SizedBox(height: Responsive.height(3, context)),

              // Opções
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildBottomSheetOption(
                    context,
                    icon: Icons.camera_alt,
                    title: "Câmera".tr,
                    onTap: () {
                      controller.pickFile(source: ImageSource.camera, type: type);
                      Get.back();
                    },
                    themeChange: themeChange,
                  ),
                  _buildBottomSheetOption(
                    context,
                    icon: Icons.photo_library,
                    title: "Galeria".tr,
                    onTap: () {
                      controller.pickFile(source: ImageSource.gallery, type: type);
                      Get.back();
                    },
                    themeChange: themeChange,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Opção do bottom sheet
  Widget _buildBottomSheetOption(
      BuildContext context, {
        required IconData icon,
        required String title,
        required VoidCallback onTap,
        required DarkThemeProvider themeChange,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: EdgeInsets.all(Responsive.width(6, context)),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: Responsive.width(8, context),
              color: AppColors.primary,
            ),
            SizedBox(height: Responsive.height(1, context)),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: Responsive.width(3.5, context),
                fontWeight: FontWeight.w600,
                color: themeChange.getThem() ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Manipula o envio do formulário
  void _handleSubmit(DetailsUploadController controller) {
    if (controller.documentNumberController.value.text.isEmpty) {
      ShowToastDialog.showToast("Por favor, insira o número do documento".tr);
      return;
    }

    if (controller.documentModel.value.frontSide == true && controller.frontImage.value.isEmpty) {
      ShowToastDialog.showToast("Por favor, carregue a frente do documento.".tr);
      return;
    }

    if (controller.documentModel.value.backSide == true && controller.backImage.value.isEmpty) {
      ShowToastDialog.showToast("Por favor, carregue o verso do documento.".tr);
      return;
    }

    ShowToastDialog.showLoader("Por favor, aguarde..".tr);
    controller.uploadDocument();
  }
}