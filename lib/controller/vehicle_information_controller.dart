// lib/controller/vehicle_information_controller.dart - VERSÃO CORRIGIDA

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/model/driver_rules_model.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/model/service_model.dart';
import 'package:driver/model/vehicle_type_model.dart';
import 'package:driver/model/zone_model.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class VehicleInformationController extends GetxController {
  Rx<TextEditingController> vehicleNumberController = TextEditingController().obs;
  Rx<TextEditingController> seatsController = TextEditingController().obs;
  Rx<TextEditingController> registrationDateController = TextEditingController().obs;
  Rx<TextEditingController> driverRulesController = TextEditingController().obs;
  Rx<TextEditingController> zoneNameController = TextEditingController().obs;
  Rx<DateTime?> selectedDate = DateTime.now().obs;

  // CORREÇÃO PRINCIPAL: Controle de edição
  RxBool isEditable = true.obs; // Começa como editável
  RxBool hasVehicleRegistered = false.obs; // Novo: indica se já tem veículo cadastrado

  RxBool isLoading = true.obs;

  Rx<String> selectedColor = "".obs;
  List<String> carColorList = <String>[
    'Vermelho', 'Preto', 'Branco', 'Azul', 'Verde',
    'Laranjado', 'Prata', 'Cinza', 'Amarelo', 'Marron',
    'Dourado', 'Bege', 'Roxo'
  ].obs;
  List<String> sheetList = <String>['1', '2', '3', '4'].obs;

  var maskFormatter = MaskTextInputFormatter(
      mask: '###-####',
      filter: { "#": RegExp(r'[A-z0-9]') },
      type: MaskAutoCompletionType.lazy
  );

  @override
  void onInit() {
    getVehicleType();
    super.onInit();
  }

  List<VehicleTypeModel> vehicleList = <VehicleTypeModel>[].obs;
  Rx<VehicleTypeModel> selectedVehicle = VehicleTypeModel().obs;

  var colors = [
    AppColors.serviceColor1,
    AppColors.serviceColor2,
    AppColors.serviceColor3,
  ];

  Rx<DriverUserModel> driverModel = DriverUserModel().obs;
  RxList<DriverRulesModel> driverRulesList = <DriverRulesModel>[].obs;
  RxList<DriverRulesModel> selectedDriverRulesList = <DriverRulesModel>[].obs;

  RxList serviceList = <ServiceModel>[].obs;
  RxList zoneList = <ZoneModel>[].obs;
  RxList selectedZone = <String>[].obs;

  Rx<String?> selectedServiceId = "".obs;
  RxString zoneString = "".obs;

  /// Carrega dados do veículo e configura modo de edição
  getVehicleType() async {
    isLoading.value = true;

    // Carrega serviços
    await FireStoreUtils.getService().then((value) {
      serviceList.value = value;
    });

    // Carrega zonas
    await FireStoreUtils.getZone().then((value) {
      if (value != null) {
        zoneList.value = value;
      }
    });

    // Carrega dados do motorista
    await FireStoreUtils.getDriverProfile(FireStoreUtils.getCurrentUid()).then((value) {
      driverModel.value = value!;

      // ========================================================================
      // LÓGICA CORRIGIDA: Verifica se JÁ tem veículo cadastrado
      // ========================================================================
      if (driverModel.value.vehicleInformation != null &&
          driverModel.value.vehicleInformation!.vehicleNumber != null &&
          driverModel.value.vehicleInformation!.vehicleNumber!.isNotEmpty) {

        // ✅ JÁ TEM VEÍCULO CADASTRADO
        hasVehicleRegistered.value = true;
        isEditable.value = false; // BLOQUEIA EDIÇÃO

        print('🚗 VEÍCULO JÁ CADASTRADO - Modo VISUALIZAÇÃO');

        // Preenche os campos com os dados existentes
        vehicleNumberController.value.text =
            driverModel.value.vehicleInformation!.vehicleNumber.toString();

        selectedDate.value =
            driverModel.value.vehicleInformation!.registrationDate!.toDate();

        registrationDateController.value.text =
            DateFormat("dd/MM/yyyy").format(selectedDate.value!);

        selectedColor.value =
            driverModel.value.vehicleInformation!.vehicleColor.toString();

        seatsController.value.text =
            driverModel.value.vehicleInformation!.seats ?? "2";
      } else {
        // ✅ NÃO TEM VEÍCULO CADASTRADO
        hasVehicleRegistered.value = false;
        isEditable.value = true; // LIBERA EDIÇÃO

        print('📝 VEÍCULO NÃO CADASTRADO - Modo CADASTRO');
      }

      // Carrega zonas selecionadas
      if(driverModel.value.zoneIds != null){
        print(driverModel.value.zoneIds.toString());
        for (var element in driverModel.value.zoneIds!) {
          List list = zoneList.where((p0) => p0.id == element).toList();
          if(list.isNotEmpty){
            selectedZone.add(element);
            zoneString.value = "$zoneString${zoneString.isEmpty ? "" : ","} ${list.first.name}";
          }
        }
        zoneNameController.value.text = zoneString.value;
      }
    });

    // Carrega serviceId
    if (driverModel.value.serviceId != null) {
      selectedServiceId.value = driverModel.value.serviceId;
    }

    // Carrega tipos de veículos
    await FireStoreUtils.getVehicleType().then((value) {
      vehicleList = value!;
      if (driverModel.value.vehicleInformation != null) {
        for (var element in vehicleList) {
          if (element.id == driverModel.value.vehicleInformation!.vehicleTypeId) {
            selectedVehicle.value = element;
          }
        }
      }
    });

    // Carrega regras do motorista
    await FireStoreUtils.getDriverRules().then((value) {
      if (value != null) {
        driverRulesList.value = value;
        if (driverModel.value.vehicleInformation != null) {
          if (driverModel.value.vehicleInformation!.driverRules != null) {
            for (var element in driverModel.value.vehicleInformation!.driverRules!) {
              selectedDriverRulesList.add(element);
            }
          }
        }
      }
    });

    isLoading.value = false;
    update();
  }

  /// Alterna entre modo visualização e edição (NOVO)
  void toggleEditMode() {
    if (hasVehicleRegistered.value) {
      isEditable.value = !isEditable.value;
      update();

      if (isEditable.value) {
        print('✏️ Modo EDIÇÃO ativado');
      } else {
        print('👁️ Modo VISUALIZAÇÃO ativado');
      }
    }
  }

  /// Cancela edição e restaura valores originais (NOVO)
  void cancelEdit() {
    if (hasVehicleRegistered.value && driverModel.value.vehicleInformation != null) {
      // Restaura valores originais
      vehicleNumberController.value.text =
          driverModel.value.vehicleInformation!.vehicleNumber.toString();

      selectedDate.value =
          driverModel.value.vehicleInformation!.registrationDate!.toDate();

      registrationDateController.value.text =
          DateFormat("dd/MM/yyyy").format(selectedDate.value!);

      selectedColor.value =
          driverModel.value.vehicleInformation!.vehicleColor.toString();

      seatsController.value.text =
          driverModel.value.vehicleInformation!.seats ?? "2";

      // Volta para modo visualização
      isEditable.value = false;
      update();

      print('❌ Edição cancelada - valores restaurados');
    }
  }

  @override
  void onClose() {
    vehicleNumberController.value.dispose();
    seatsController.value.dispose();
    registrationDateController.value.dispose();
    driverRulesController.value.dispose();
    zoneNameController.value.dispose();
    super.onClose();
  }
}