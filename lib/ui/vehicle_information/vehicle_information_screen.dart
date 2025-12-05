// lib/ui/vehicle_information/vehicle_information_screen.dart - VERSÃO COMPLETA SEM EDIÇÃO
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/controller/vehicle_information_controller.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/model/service_model.dart';
import 'package:driver/model/vehicle_type_model.dart';
import 'package:driver/model/zone_model.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/button_them.dart';
import 'package:driver/themes/responsive.dart';
import 'package:driver/themes/text_field_them.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class VehicleInformationScreen extends StatelessWidget {
  const VehicleInformationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return GetX<VehicleInformationController>(
      init: VehicleInformationController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: AppColors.primary,
          body: Column(
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
                  child: controller.isLoading.value
                      ? Center(child: Constant.loader(context))
                      : Column(
                          children: [
                            // Header
                            Container(
                              width: Responsive.width(100, context),
                              padding:
                                  EdgeInsets.all(Responsive.width(5, context)),
                              child: Text(
                                'Informações do Veículo',
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

                            // BANNER DE STATUS
                            _buildStatusBanner(
                                context, controller, themeChange),

                            // Content
                            Expanded(
                              child: SingleChildScrollView(
                                padding: EdgeInsets.symmetric(
                                  horizontal: Responsive.width(5, context),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Service Selection Section
                                    _buildSectionTitle(context, themeChange,
                                        'Tipo de Serviço'),
                                    SizedBox(
                                        height: Responsive.height(1, context)),
                                    _buildServiceSelector(
                                        context, controller, themeChange),

                                    SizedBox(
                                        height: Responsive.height(3, context)),

                                    // Vehicle Information Section
                                    _buildSectionTitle(context, themeChange,
                                        'Informações do Veículo'),
                                    SizedBox(
                                        height:
                                            Responsive.height(1.5, context)),

                                    // Vehicle Number Field
                                    _buildFormField(
                                      context,
                                      themeChange,
                                      label: 'Placa do Veículo',
                                      child: TextFieldThem.buildTextMask(
                                        context,
                                        enable: controller.isEditable.value,
                                        hintText: 'Placa do Veículo'.tr,
                                        controller: controller
                                            .vehicleNumberController.value,
                                        inputMaskFormatter:
                                            controller.maskFormatter,
                                      ),
                                    ),

                                    SizedBox(
                                        height: Responsive.height(2, context)),

                                    // Registration Date Field
                                    _buildFormField(
                                      context,
                                      themeChange,
                                      label: 'Data de Registro',
                                      child: InkWell(
                                        onTap: () async {
                                          if (controller.isEditable.value) {
                                            await Constant.selectDate(context)
                                                .then((value) {
                                              if (value != null) {
                                                controller.selectedDate.value =
                                                    value;
                                                controller
                                                    .registrationDateController
                                                    .value
                                                    .text = DateFormat(
                                                        "dd/MM/yyyy")
                                                    .format(value);
                                              }
                                            });
                                          }
                                        },
                                        child: AbsorbPointer(
                                          child: TextFieldThem.buildTextFiled(
                                            context,
                                            hintText: 'Registration Date'.tr,
                                            enable: controller.isEditable.value,
                                            controller: controller
                                                .registrationDateController
                                                .value,
                                          ),
                                        ),
                                      ),
                                    ),

                                    SizedBox(
                                        height: Responsive.height(2, context)),

                                    // Vehicle Type Dropdown
                                    _buildFormField(
                                      context,
                                      themeChange,
                                      label: 'Tipo de Veículo',
                                      child: _buildDropdown<VehicleTypeModel>(
                                        context,
                                        themeChange,
                                        value: controller
                                                    .selectedVehicle.value.id ==
                                                null
                                            ? null
                                            : controller.selectedVehicle.value,
                                        hint: "Select vehicle type".tr,
                                        items: controller.vehicleList,
                                        onChanged: controller.isEditable.value
                                            ? (value) {
                                                controller.selectedVehicle
                                                    .value = value!;
                                              }
                                            : null,
                                        itemBuilder: (item) =>
                                            Text(item.name ?? 'Tipo'),
                                      ),
                                    ),

                                    SizedBox(
                                        height: Responsive.height(2, context)),

                                    // Vehicle Color Dropdown
                                    _buildFormField(
                                      context,
                                      themeChange,
                                      label: 'Cor do Veículo',
                                      child: _buildDropdown<String>(
                                        context,
                                        themeChange,
                                        value: controller
                                                .selectedColor.value.isEmpty
                                            ? null
                                            : controller.selectedColor.value,
                                        hint: "Select vehicle color".tr,
                                        items: controller.carColorList,
                                        onChanged: controller.isEditable.value
                                            ? (value) {
                                                controller.selectedColor.value =
                                                    value!;
                                              }
                                            : null,
                                        itemBuilder: (item) =>
                                            Text(item.toString()),
                                      ),
                                    ),

                                    SizedBox(
                                        height: Responsive.height(2, context)),

                                    // Number of Seats Dropdown
                                    _buildFormField(
                                      context,
                                      themeChange,
                                      label: 'Número de Assentos',
                                      child: _buildDropdown<String>(
                                        context,
                                        themeChange,
                                        value: controller.seatsController.value
                                                .text.isEmpty
                                            ? null
                                            : controller
                                                .seatsController.value.text,
                                        hint: "How Many Seats".tr,
                                        items: controller.sheetList,
                                        onChanged: controller.isEditable.value
                                            ? (value) {
                                                controller.seatsController.value
                                                    .text = value!;
                                              }
                                            : null,
                                        itemBuilder: (item) =>
                                            Text(item.toString()),
                                      ),
                                    ),

                                    SizedBox(
                                        height: Responsive.height(2, context)),

                                    // Zone Selection Field
                                    _buildFormField(
                                      context,
                                      themeChange,
                                      label: 'Zona de Atuação',
                                      child: InkWell(
                                        onTap: () {
                                          if (controller.isEditable.value) {
                                            _showZoneDialog(context, controller,
                                                themeChange);
                                          }
                                        },
                                        child: AbsorbPointer(
                                          child: TextFieldThem.buildTextFiled(
                                            context,
                                            hintText: 'Select Zone'.tr,
                                            controller: controller
                                                .zoneNameController.value,
                                            enable: controller.isEditable.value,
                                          ),
                                        ),
                                      ),
                                    ),

                                    SizedBox(
                                        height: Responsive.height(3, context)),

                                    _buildDriverRules(
                                        context, controller, themeChange),

                                    SizedBox(
                                        height: Responsive.height(3, context)),

                                    // Warning Text
                                    Container(
                                      padding: EdgeInsets.all(
                                          Responsive.width(4, context)),
                                      margin: EdgeInsets.symmetric(
                                        horizontal:
                                            Responsive.width(2, context),
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.orange.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.warning_rounded,
                                            color: Colors.orange,
                                            size: Responsive.width(5, context),
                                          ),
                                          SizedBox(
                                              width:
                                                  Responsive.width(3, context)),
                                          Expanded(
                                            child: Text(
                                              "You can not change once you select one service type if you want to change please contact to administrator "
                                                  .tr,
                                              style: GoogleFonts.poppins(
                                                fontSize: Responsive.width(
                                                    3, context),
                                                color: Colors.orange.shade700,
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    SizedBox(
                                        height: Responsive.height(3, context)),
                                  ],
                                ),
                              ),
                            ),

                            // BOTÕES DE AÇÃO
                            Padding(
                              padding:
                                  EdgeInsets.all(Responsive.width(5, context)),
                              child: _buildActionButtons(
                                  context, controller, themeChange),
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

  /// ============================================================================
  /// BANNER DE STATUS - APENAS 2 ESTADOS (SEM EDIÇÃO)
  /// ============================================================================
  Widget _buildStatusBanner(BuildContext context,
      VehicleInformationController controller, DarkThemeProvider themeChange) {
    return Obx(() {
      if (!controller.hasVehicleRegistered.value) {
        // Estado 1: CADASTRO INICIAL - AZUL
        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: Responsive.width(5, context),
            vertical: Responsive.height(1, context),
          ),
          padding: EdgeInsets.all(Responsive.width(3, context)),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade400, Colors.blue.shade600],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(Responsive.width(2, context)),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: Responsive.width(5, context),
                ),
              ),
              SizedBox(width: Responsive.width(3, context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cadastro de Veículo',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: Responsive.width(3.8, context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: Responsive.height(0.3, context)),
                    Text(
                      'Preencha os dados do seu veículo para começar',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: Responsive.width(3, context),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      } else {
        // Estado 2: VEÍCULO JÁ CADASTRADO - VERDE (SEM BOTÃO EDITAR)
        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: Responsive.width(5, context),
            vertical: Responsive.height(1, context),
          ),
          padding: EdgeInsets.all(Responsive.width(3, context)),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade400, Colors.green.shade600],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(Responsive.width(2, context)),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: Responsive.width(5, context),
                ),
              ),
              SizedBox(width: Responsive.width(3, context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Veículo Cadastrado',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: Responsive.width(3.8, context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: Responsive.height(0.3, context)),
                    Text(
                      'Informações do veículo registradas com sucesso',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: Responsive.width(3, context),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              // ÍCONE DE BLOQUEIO
              Container(
                padding: EdgeInsets.all(Responsive.width(2, context)),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.lock_outline,
                  color: Colors.white,
                  size: Responsive.width(4.5, context),
                ),
              ),
            ],
          ),
        );
      }
    });
  }

  /// ============================================================================
  /// BOTÕES DE AÇÃO - APENAS QUANDO NÃO TEM CADASTRO
  /// ============================================================================
  Widget _buildActionButtons(BuildContext context,
      VehicleInformationController controller, DarkThemeProvider themeChange) {
    return Obx(() {
      if (!controller.hasVehicleRegistered.value) {
        // Primeira vez - botão cadastrar
        return Center(
          child: ButtonThem.buildButton(
            context,
            title: "Cadastrar Veículo".tr,
            btnWidthRatio: 0.8,
            onPress: () => _handleSave(controller),
          ),
        );
      } else {
        // Já cadastrado - mensagem informativa
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.width(5, context),
            vertical: Responsive.height(2, context),
          ),
          child: Container(
            padding: EdgeInsets.all(Responsive.width(4, context)),
            decoration: BoxDecoration(
              color: themeChange.getThem()
                  ? Colors.blue.shade900.withOpacity(0.3)
                  : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: themeChange.getThem()
                    ? Colors.blue.shade700
                    : Colors.blue.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: themeChange.getThem()
                      ? Colors.blue.shade300
                      : Colors.blue.shade700,
                  size: Responsive.width(5, context),
                ),
                SizedBox(width: Responsive.width(3, context)),
                Expanded(
                  child: Text(
                    'Para alterar as informações do veículo, entre em contato com o administrador.',
                    style: GoogleFonts.poppins(
                      fontSize: Responsive.width(3.3, context),
                      color: themeChange.getThem()
                          ? Colors.blue.shade200
                          : Colors.blue.shade800,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    });
  }

  /// ============================================================================
  /// WIDGETS AUXILIARES
  /// ============================================================================

  Widget _buildSectionTitle(
      BuildContext context, DarkThemeProvider themeChange, String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontWeight: FontWeight.w600,
        fontSize: Responsive.width(4.2, context),
        color: themeChange.getThem() ? Colors.white : Colors.black87,
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

  Widget _buildServiceSelector(BuildContext context,
      VehicleInformationController controller, DarkThemeProvider themeChange) {
    return SizedBox(
      height: Responsive.height(16, context),
      child: ListView.builder(
        itemCount: controller.serviceList.length,
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        itemBuilder: (context, index) {
          ServiceModel serviceModel = controller.serviceList[index];
          return Obx(
            () => Container(
              margin: EdgeInsets.only(right: Responsive.width(3, context)),
              child: InkWell(
                onTap: () async {
                  if (controller.driverModel.value.serviceId == null) {
                    controller.selectedServiceId.value = serviceModel.id ?? '';
                  }
                },
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  width: Responsive.width(25, context),
                  decoration: BoxDecoration(
                    color: controller.selectedServiceId.value ==
                            (serviceModel.id ?? '')
                        ? AppColors.primary
                        : (themeChange.getThem()
                            ? AppColors.darkContainerBackground
                            : AppColors.containerBackground),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: controller.selectedServiceId.value ==
                              (serviceModel.id ?? '')
                          ? AppColors.primary
                          : (themeChange.getThem()
                              ? AppColors.darkContainerBorder
                              : AppColors.containerBorder),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CachedNetworkImage(
                        imageUrl: serviceModel.image ?? '',
                        height: Responsive.height(6, context),
                        width: Responsive.width(12, context),
                        color: controller.selectedServiceId.value ==
                                (serviceModel.id ?? '')
                            ? Colors.white
                            : null,
                        errorWidget: (context, url, error) => Icon(
                          Icons.image_not_supported,
                          size: Responsive.width(12, context),
                        ),
                      ),
                      SizedBox(height: Responsive.height(1, context)),
                      Text(
                        serviceModel.title ?? 'Serviço',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: GoogleFonts.poppins(
                          fontSize: Responsive.width(3, context),
                          fontWeight: FontWeight.w500,
                          color: controller.selectedServiceId.value ==
                                  (serviceModel.id ?? '')
                              ? Colors.white
                              : (themeChange.getThem()
                                  ? Colors.white
                                  : Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDropdown<T>(
    BuildContext context,
    DarkThemeProvider themeChange, {
    required T? value,
    required String hint,
    required List<T> items,
    required void Function(T?)? onChanged,
    required Widget Function(T) itemBuilder,
  }) {
    final bool isEnabled = onChanged != null;

    final Color fillColor = isEnabled
        ? (themeChange.getThem()
            ? AppColors.darkTextField
            : AppColors.textField)
        : (themeChange.getThem()
            ? AppColors.darkTextField.withOpacity(0.5)
            : AppColors.textField.withOpacity(0.5));

    final Color valueTextColor = isEnabled
        ? (themeChange.getThem() ? Colors.white : Colors.black87)
        : (themeChange.getThem() ? Colors.white54 : Colors.black54);

    return DropdownButtonFormField<T>(
      initialValue: value,
      style: GoogleFonts.poppins(
        fontSize: Responsive.width(3.5, context),
        color: valueTextColor,
        fontWeight: FontWeight.w500,
      ),
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: fillColor,
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          fontSize: Responsive.width(3.5, context),
          color: themeChange.getThem() ? Colors.white54 : Colors.black54,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: Responsive.width(3, context),
          vertical: Responsive.height(1.2, context),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: themeChange.getThem()
                ? AppColors.darkTextFieldBorder
                : AppColors.textFieldBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: themeChange.getThem()
                ? AppColors.darkTextFieldBorder
                : AppColors.textFieldBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: themeChange.getThem()
                ? AppColors.darkTextFieldBorder.withOpacity(0.5)
                : AppColors.textFieldBorder.withOpacity(0.5),
          ),
        ),
      ),
      items: items.map((T item) {
        return DropdownMenuItem<T>(
          value: item,
          child: itemBuilder(item),
        );
      }).toList(),
      icon: Icon(
        Icons.keyboard_arrow_down,
        color: isEnabled
            ? (themeChange.getThem() ? Colors.white : Colors.black54)
            : (themeChange.getThem() ? Colors.white24 : Colors.black26),
      ),
    );
  }

  Widget _buildDriverRules(BuildContext context,
      VehicleInformationController controller, DarkThemeProvider themeChange) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Regras do Motorista',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: Responsive.width(4.2, context),
            color: themeChange.getThem() ? Colors.white : Colors.black87,
          ),
        ),
        SizedBox(height: Responsive.height(1.5, context)),
        Obx(
          () => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: controller.driverRulesList.map((rule) {
              bool isSelected = controller.selectedDriverRulesList
                  .any((selected) => selected.id == rule.id);
              return InkWell(
                onTap: () {
                  if (controller.isEditable.value) {
                    if (isSelected) {
                      controller.selectedDriverRulesList
                          .removeWhere((item) => item.id == rule.id);
                    } else {
                      controller.selectedDriverRulesList.add(rule);
                    }
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.width(3, context),
                    vertical: Responsive.height(1, context),
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : (themeChange.getThem()
                            ? AppColors.darkContainerBackground
                            : AppColors.containerBackground),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (themeChange.getThem()
                              ? AppColors.darkContainerBorder
                              : AppColors.containerBorder),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected)
                        Padding(
                          padding: EdgeInsets.only(
                              right: Responsive.width(1.5, context)),
                          child: Icon(
                            Icons.check,
                            color: Colors.white,
                            size: Responsive.width(4, context),
                          ),
                        ),
                      Text(
                        rule.name ?? 'Regra',
                        style: GoogleFonts.poppins(
                          fontSize: Responsive.width(3.3, context),
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (themeChange.getThem()
                                  ? Colors.white
                                  : Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _showZoneDialog(BuildContext context,
      VehicleInformationController controller, DarkThemeProvider themeChange) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Selecione as Zonas'),
          content: SizedBox(
            width: double.maxFinite,
            child: Obx(
              () => ListView.builder(
                shrinkWrap: true,
                itemCount: controller.zoneList.length,
                itemBuilder: (context, index) {
                  ZoneModel zone = controller.zoneList[index];
                  bool isSelected =
                      controller.selectedZone.contains(zone.id.toString());
                  return CheckboxListTile(
                    title: Text(zone.name ?? 'Zona'),
                    value: isSelected,
                    onChanged: (bool? value) {
                      if (value == true) {
                        controller.selectedZone.add(zone.id.toString());
                      } else {
                        controller.selectedZone.remove(zone.id.toString());
                      }
                    },
                  );
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                String nameValue = "";
                for (var element in controller.selectedZone) {
                  List list = controller.zoneList
                      .where((p0) => p0.id == element)
                      .toList();
                  if (list.isNotEmpty) {
                    nameValue =
                        "$nameValue${nameValue.isEmpty ? "" : ", "} ${list.first.name}";
                  }
                }
                controller.zoneNameController.value.text = nameValue;
                Get.back();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Confirmar',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleSave(VehicleInformationController controller) async {
    ShowToastDialog.showLoader("Aguarde...".tr);

    if (controller.selectedServiceId.value!.isEmpty) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Please select service".tr);
    } else if (controller.vehicleNumberController.value.text.isEmpty) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Please enter Vehicle number".tr);
    } else if (controller.registrationDateController.value.text.isEmpty) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Please select registration date".tr);
    } else if (controller.selectedVehicle.value.id == null ||
        controller.selectedVehicle.value.id!.isEmpty) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Please enter Vehicle type".tr);
    } else if (controller.selectedColor.value.isEmpty) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Please enter Vehicle color".tr);
    } else if (controller.seatsController.value.text.isEmpty) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Please enter seats".tr);
    } else if (controller.selectedZone.isEmpty) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Please select Zone".tr);
    } else {
      if (controller.driverModel.value.serviceId == null) {
        controller.driverModel.value.serviceId =
            controller.selectedServiceId.value;
        await FireStoreUtils.updateDriverUser(controller.driverModel.value);
      }

      controller.driverModel.value.zoneIds = controller.selectedZone;
      controller.driverModel.value.vehicleInformation = VehicleInformation(
        registrationDate: Timestamp.fromDate(controller.selectedDate.value!),
        vehicleColor: controller.selectedColor.value,
        vehicleNumber: controller.vehicleNumberController.value.text,
        vehicleType: controller.selectedVehicle.value.name,
        vehicleTypeId: controller.selectedVehicle.value.id,
        seats: controller.seatsController.value.text,
        driverRules: controller.selectedDriverRulesList,
      );

      await FireStoreUtils.updateDriverUser(controller.driverModel.value)
          .then((value) {
        ShowToastDialog.closeLoader();
        if (value == true) {
          // MARCA COMO CADASTRADO - BLOQUEIA EDIÇÃO PERMANENTEMENTE
          controller.hasVehicleRegistered.value = true;
          controller.isEditable.value = false;

          ShowToastDialog.showToast("Veículo cadastrado com sucesso!".tr);

          print('✅ Veículo cadastrado e BLOQUEADO para edição');
        }
      });
    }
  }
}
