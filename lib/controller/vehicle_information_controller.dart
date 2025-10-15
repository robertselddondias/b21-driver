// lib/controller/vehicle_information_controller.dart - VERSÃO COMPLETA SEM EDIÇÃO
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
  // ============================================================================
  // CONTROLLERS DE TEXTO
  // ============================================================================
  Rx<TextEditingController> vehicleNumberController = TextEditingController().obs;
  Rx<TextEditingController> seatsController = TextEditingController().obs;
  Rx<TextEditingController> registrationDateController = TextEditingController().obs;
  Rx<TextEditingController> driverRulesController = TextEditingController().obs;
  Rx<TextEditingController> zoneNameController = TextEditingController().obs;

  // ============================================================================
  // VARIÁVEIS REATIVAS
  // ============================================================================
  RxString selectedColor = "".obs;
  Rx<DateTime?> selectedDate = DateTime.now().obs;
  RxBool isLoading = true.obs;

  // ============================================================================
  // CONTROLE DE CADASTRO - SEM POSSIBILIDADE DE EDIÇÃO APÓS CADASTRAR
  // ============================================================================
  RxBool hasVehicleRegistered = false.obs; // Indica se já tem veículo cadastrado
  RxBool isEditable = false.obs; // Se false, campos ficam bloqueados

  List<String> carColorList = <String>[
    'Vermelho', 'Preto', 'Branco', 'Azul', 'Verde',
    'Laranjado', 'Prata', 'Cinza', 'Amarelo', 'Marron',
    'Dourado', 'Bege', 'Roxo'
  ].obs;
  List<String> sheetList = <String>['1', '2', '3', '4'].obs;

  // ============================================================================
  // FORMATADORES E SELETORES
  // ============================================================================
  var maskFormatter = MaskTextInputFormatter(
    mask: 'AAA-#X##',
    filter: {
      "A": RegExp(r'[A-Za-z]'),
      "#": RegExp(r'[0-9]'),
      "X": RegExp(r'[0-9A-Za-z]')
    },
  );

  Rx<VehicleTypeModel> selectedVehicle = VehicleTypeModel().obs;
  List<VehicleTypeModel> vehicleList = [];


  List<Color> vehicleColorList = [
    AppColors.serviceColor1,
    AppColors.serviceColor2,
    AppColors.serviceColor3,
  ];

  // ============================================================================
  // MODELOS E LISTAS
  // ============================================================================
  Rx<DriverUserModel> driverModel = DriverUserModel().obs;
  RxList<DriverRulesModel> driverRulesList = <DriverRulesModel>[].obs;
  RxList<DriverRulesModel> selectedDriverRulesList = <DriverRulesModel>[].obs;

  RxList serviceList = <ServiceModel>[].obs;
  RxList zoneList = <ZoneModel>[].obs;
  RxList selectedZone = <String>[].obs;

  Rx<String?> selectedServiceId = "".obs;
  RxString zoneString = "".obs;

  // ============================================================================
  // INICIALIZAÇÃO
  // ============================================================================
  @override
  void onInit() {
    getVehicleType();
    super.onInit();
  }

  // ============================================================================
  // CARREGA DADOS DO VEÍCULO E CONFIGURA MODO DE EDIÇÃO
  // ============================================================================
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
    await FireStoreUtils.getDriverProfile(FireStoreUtils.getCurrentUid())
        .then((value) {
      driverModel.value = value!;

      // ========================================================================
      // LÓGICA PRINCIPAL: Verifica se JÁ tem veículo cadastrado
      // ========================================================================
      if (driverModel.value.vehicleInformation != null &&
          driverModel.value.vehicleInformation!.vehicleNumber != null &&
          driverModel.value.vehicleInformation!.vehicleNumber!.isNotEmpty) {

        // ✅ JÁ TEM VEÍCULO CADASTRADO
        hasVehicleRegistered.value = true;
        isEditable.value = false; // BLOQUEIA PARA SEMPRE

        print('🚗 VEÍCULO JÁ CADASTRADO - Modo VISUALIZAÇÃO APENAS');
        print('🔒 Edição BLOQUEADA permanentemente');

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
        isEditable.value = true; // LIBERA APENAS PARA CADASTRO

        print('📝 VEÍCULO NÃO CADASTRADO - Modo CADASTRO');
      }

      // Carrega zonas selecionadas
      if (driverModel.value.zoneIds != null) {
        for (var element in driverModel.value.zoneIds!) {
          List list = zoneList.where((p0) => p0.id == element).toList();
          if (list.isNotEmpty) {
            selectedZone.add(element);
            zoneString.value =
            "$zoneString${zoneString.isEmpty ? "" : ","} ${list.first.name}";
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
          if (element.id ==
              driverModel.value.vehicleInformation!.vehicleTypeId) {
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
            for (var element
            in driverModel.value.vehicleInformation!.driverRules!) {
              selectedDriverRulesList.add(element);
            }
          }
        }
      }
    });

    isLoading.value = false;
    update();
  }

  // ============================================================================
  // DISPOSE
  // ============================================================================
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