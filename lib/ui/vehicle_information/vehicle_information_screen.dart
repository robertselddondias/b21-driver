// lib/ui/vehicle_information/vehicle_information_screen.dart - Versão com temas e responsividade
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/controller/vehicle_information_controller.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/model/service_model.dart';
import 'package:driver/model/vehicle_type_model.dart';
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
                        padding: EdgeInsets.all(Responsive.width(5, context)),
                        child: Text(
                          'Informações do Veículo',
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
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.width(5, context),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Service Selection Section
                              _buildSectionTitle(context, themeChange, 'Tipo de Serviço'),
                              SizedBox(height: Responsive.height(1, context)),
                              _buildServiceSelector(context, controller, themeChange),

                              SizedBox(height: Responsive.height(3, context)),

                              // Vehicle Information Section
                              _buildSectionTitle(context, themeChange, 'Informações do Veículo'),
                              SizedBox(height: Responsive.height(1.5, context)),

                              // Vehicle Number Field
                              _buildFormField(
                                context,
                                themeChange,
                                label: 'Placa do Veículo',
                                child: TextFieldThem.buildTextMask(
                                  context,
                                  hintText: 'Placa do Veículo'.tr,
                                  controller: controller.vehicleNumberController.value,
                                  inputMaskFormatter: controller.maskFormatter,
                                ),
                              ),

                              SizedBox(height: Responsive.height(2, context)),

                              // Registration Date Field
                              _buildFormField(
                                context,
                                themeChange,
                                label: 'Data de Registro',
                                child: InkWell(
                                  onTap: () async {
                                    await Constant.selectDate(context).then((value) {
                                      if (value != null) {
                                        controller.selectedDate.value = value;
                                        controller.registrationDateController.value.text =
                                            DateFormat("dd/MM/yyyy").format(value);
                                      }
                                    });
                                  },
                                  child: TextFieldThem.buildTextFiled(
                                    context,
                                    hintText: 'Registration Date'.tr,
                                    controller: controller.registrationDateController.value,
                                    enable: false,
                                  ),
                                ),
                              ),

                              SizedBox(height: Responsive.height(2, context)),

                              // Vehicle Type Dropdown
                              _buildFormField(
                                context,
                                themeChange,
                                label: 'Tipo de Veículo',
                                child: _buildDropdown<VehicleTypeModel>(
                                  context,
                                  themeChange,
                                  value: controller.selectedVehicle.value.id == null
                                      ? null
                                      : controller.selectedVehicle.value,
                                  hint: "Select vehicle type".tr,
                                  items: controller.vehicleList,
                                  onChanged: (value) {
                                    controller.selectedVehicle.value = value!;
                                  },
                                  itemBuilder: (item) => Text(item.name.toString()),
                                ),
                              ),

                              SizedBox(height: Responsive.height(2, context)),

                              // Vehicle Color Dropdown
                              _buildFormField(
                                context,
                                themeChange,
                                label: 'Cor do Veículo',
                                child: _buildDropdown<String>(
                                  context,
                                  themeChange,
                                  value: controller.selectedColor.value.isEmpty
                                      ? null
                                      : controller.selectedColor.value,
                                  hint: "Select vehicle color".tr,
                                  items: controller.carColorList,
                                  onChanged: (value) {
                                    controller.selectedColor.value = value!;
                                  },
                                  itemBuilder: (item) => Text(item.toString()),
                                ),
                              ),

                              SizedBox(height: Responsive.height(2, context)),

                              // Number of Seats Dropdown
                              _buildFormField(
                                context,
                                themeChange,
                                label: 'Número de Assentos',
                                child: _buildDropdown<String>(
                                  context,
                                  themeChange,
                                  value: controller.seatsController.value.text.isEmpty
                                      ? null
                                      : controller.seatsController.value.text,
                                  hint: "How Many Seats".tr,
                                  items: controller.sheetList,
                                  onChanged: (value) {
                                    controller.seatsController.value.text = value!;
                                  },
                                  itemBuilder: (item) => Text(item.toString()),
                                ),
                              ),

                              SizedBox(height: Responsive.height(2, context)),

                              // Zone Selection Field
                              _buildFormField(
                                context,
                                themeChange,
                                label: 'Zona de Atuação',
                                child: InkWell(
                                  onTap: () {
                                    _showZoneDialog(context, controller, themeChange);
                                  },
                                  child: TextFieldThem.buildTextFiled(
                                    context,
                                    hintText: 'Select Zone'.tr,
                                    controller: controller.zoneNameController.value,
                                    enable: false,
                                  ),
                                ),
                              ),

                              SizedBox(height: Responsive.height(3, context)),

                              // Driver Rules Section
                              _buildSectionTitle(context, themeChange, "Select Your Rules".tr),
                              SizedBox(height: Responsive.height(1, context)),
                              _buildDriverRules(context, controller, themeChange),

                              SizedBox(height: Responsive.height(3, context)),

                              // Save Button
                              Center(
                                child: ButtonThem.buildButton(
                                  context,
                                  title: "Save".tr,
                                  btnWidthRatio: 0.8,
                                  onPress: () => _handleSave(controller),
                                ),
                              ),

                              SizedBox(height: Responsive.height(2, context)),

                              // Warning Text
                              Container(
                                padding: EdgeInsets.all(Responsive.width(4, context)),
                                margin: EdgeInsets.symmetric(
                                  horizontal: Responsive.width(2, context),
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
                                    SizedBox(width: Responsive.width(3, context)),
                                    Expanded(
                                      child: Text(
                                        "You can not change once you select one service type if you want to change please contact to administrator ".tr,
                                        style: GoogleFonts.poppins(
                                          fontSize: Responsive.width(3, context),
                                          color: Colors.orange.shade700,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
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
      },
    );
  }

  Widget _buildSectionTitle(BuildContext context, DarkThemeProvider themeChange, String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontWeight: FontWeight.w600,
        fontSize: Responsive.width(4.2, context),
        color: themeChange.getThem() ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildFormField(BuildContext context, DarkThemeProvider themeChange, {
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

  Widget _buildServiceSelector(BuildContext context, VehicleInformationController controller, DarkThemeProvider themeChange) {
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
                    controller.selectedServiceId.value = serviceModel.id;
                  }
                },
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  width: Responsive.width(25, context),
                  decoration: BoxDecoration(
                    color: controller.selectedServiceId.value == serviceModel.id
                        ? AppColors.primary
                        : (themeChange.getThem()
                        ? AppColors.darkContainerBackground
                        : AppColors.containerBackground),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: controller.selectedServiceId.value == serviceModel.id
                          ? AppColors.primary
                          : (themeChange.getThem()
                          ? AppColors.darkContainerBorder
                          : AppColors.containerBorder),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(Responsive.width(2, context)),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: serviceModel.image.toString(),
                          fit: BoxFit.contain,
                          height: Responsive.height(6, context),
                          width: Responsive.width(12, context),
                          placeholder: (context, url) => Container(
                            width: Responsive.width(12, context),
                            height: Responsive.height(6, context),
                            child: Center(
                              child: SizedBox(
                                width: Responsive.width(4, context),
                                height: Responsive.width(4, context),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Icon(
                            Icons.directions_car,
                            size: Responsive.width(8, context),
                            color: AppColors.subTitleColor,
                          ),
                        ),
                      ),
                      SizedBox(height: Responsive.height(1, context)),
                      Text(
                        serviceModel.title.toString().toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: controller.selectedServiceId.value == serviceModel.id
                              ? Colors.white
                              : (themeChange.getThem() ? Colors.white : Colors.black),
                          fontWeight: FontWeight.w500,
                          fontSize: Responsive.width(3, context),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
        required void Function(T?) onChanged,
        required Widget Function(T) itemBuilder,
      }) {
    return DropdownButtonFormField<T>(
      style: GoogleFonts.poppins(
        fontSize: Responsive.width(3.5, context),
        color: themeChange.getThem() ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: themeChange.getThem()
            ? AppColors.darkTextField
            : AppColors.textField,
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
            width: 2,
          ),
        ),
      ),
      dropdownColor: themeChange.getThem()
          ? AppColors.darkContainerBackground
          : AppColors.containerBackground,
      value: value,
      onChanged: onChanged,
      hint: Text(
        hint,
        style: GoogleFonts.poppins(
          fontSize: Responsive.width(3.5, context),
          color: AppColors.subTitleColor,
          fontWeight: FontWeight.w400,
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: DefaultTextStyle(
            style: GoogleFonts.poppins(
              fontSize: Responsive.width(3.5, context),
              color: themeChange.getThem() ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            child: itemBuilder(item),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDriverRules(BuildContext context, VehicleInformationController controller, DarkThemeProvider themeChange) {
    return Container(
      decoration: BoxDecoration(
        color: themeChange.getThem()
            ? AppColors.darkContainerBackground
            : AppColors.containerBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeChange.getThem()
              ? AppColors.darkContainerBorder
              : AppColors.containerBorder,
        ),
      ),
      child: Column(
        children: controller.driverRulesList.map((item) {
          return Obx(() => CheckboxListTile(
            checkColor: Colors.white,
            activeColor: AppColors.primary,
            value: controller.selectedDriverRulesList
                .indexWhere((element) => element.id == item.id) !=
                -1,
            title: Text(
              item.name.toString(),
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w400,
                fontSize: Responsive.width(3.5, context),
                color: themeChange.getThem() ? Colors.white : Colors.black87,
              ),
            ),
            onChanged: (value) {
              if (value == true) {
                controller.selectedDriverRulesList.add(item);
              } else {
                controller.selectedDriverRulesList.removeAt(
                    controller.selectedDriverRulesList
                        .indexWhere((element) => element.id == item.id));
              }
            },
          ));
        }).toList(),
      ),
    );
  }

  void _showZoneDialog(BuildContext context, VehicleInformationController controller, DarkThemeProvider themeChange) {
    showDialog(
      context: context,
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
            ),
          ),
          title: Text(
            'Zone list',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: Responsive.width(4.5, context),
              color: themeChange.getThem() ? Colors.white : Colors.black,
            ),
          ),
          content: SizedBox(
            width: Responsive.width(80, context),
            child: controller.zoneList.isEmpty
                ? Text(
              'Nenhuma zona disponível',
              style: GoogleFonts.poppins(
                color: AppColors.subTitleColor,
              ),
            )
                : Obx(
                  () => ListView.builder(
                shrinkWrap: true,
                itemCount: controller.zoneList.length,
                itemBuilder: (BuildContext context, int index) {
                  return Obx(
                        () => CheckboxListTile(
                      value: controller.selectedZone
                          .contains(controller.zoneList[index].id),
                      onChanged: (value) {
                        if (controller.selectedZone
                            .contains(controller.zoneList[index].id)) {
                          controller.selectedZone
                              .remove(controller.zoneList[index].id);
                        } else {
                          controller.selectedZone
                              .add(controller.zoneList[index].id);
                        }
                      },
                      activeColor: AppColors.primary,
                      checkColor: Colors.white,
                      title: Text(
                        controller.zoneList[index].name.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: Responsive.width(3.5, context),
                          color: themeChange.getThem()
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.width(4, context),
                  vertical: Responsive.height(1, context),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: AppColors.subTitleColor),
                ),
              ),
              child: Text(
                "Cancel",
                style: GoogleFonts.poppins(
                  color: AppColors.subTitleColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: () {
                Get.back();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.width(4, context),
                  vertical: Responsive.height(1, context),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                "Continue",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () {
                if (controller.selectedZone.isEmpty) {
                  ShowToastDialog.showToast("Please select zone");
                } else {
                  String nameValue = "";
                  for (var element in controller.selectedZone) {
                    List list = controller.zoneList
                        .where((p0) => p0.id == element)
                        .toList();
                    if (list.isNotEmpty) {
                      nameValue =
                      "$nameValue${nameValue.isEmpty ? "" : ","} ${list.first.name}";
                    }
                  }
                  controller.zoneNameController.value.text = nameValue;
                  Get.back();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _handleSave(VehicleInformationController controller) async {
    ShowToastDialog.showLoader("Aguarde...".tr);

    if (controller.selectedServiceId.value!.isEmpty) {
      ShowToastDialog.showToast("Please select service".tr);
    } else if (controller.vehicleNumberController.value.text.isEmpty) {
      ShowToastDialog.showToast("Please enter Vehicle number".tr);
    } else if (controller.registrationDateController.value.text.isEmpty) {
      ShowToastDialog.showToast("Please select registration date".tr);
    } else if (controller.selectedVehicle.value.id == null ||
        controller.selectedVehicle.value.id!.isEmpty) {
      ShowToastDialog.showToast("Please enter Vehicle type".tr);
    } else if (controller.selectedColor.value.isEmpty) {
      ShowToastDialog.showToast("Please enter Vehicle color".tr);
    } else if (controller.seatsController.value.text.isEmpty) {
      ShowToastDialog.showToast("Please enter seats".tr);
    } else if (controller.selectedZone.isEmpty) {
      ShowToastDialog.showToast("Please select Zone".tr);
    } else {
      if (controller.driverModel.value.serviceId == null) {
        controller.driverModel.value.serviceId = controller.selectedServiceId.value;
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

      await FireStoreUtils.updateDriverUser(controller.driverModel.value).then((value) {
        ShowToastDialog.closeLoader();
        if (value == true) {
          ShowToastDialog.showToast("Information update successfully".tr);
        }
      });
    }
  }
}