import 'dart:io';

import 'package:driver/constant/collection_name.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/controller/auto_assignment_controller.dart';
import 'package:driver/controller/dash_board_controller.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/model/order/location_lat_lng.dart';
import 'package:driver/model/order/positions.dart';
import 'package:driver/ui/home_screens/active_order_screen.dart';
import 'package:driver/ui/order_screen/order_screen.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:driver/widget/geoflutterfire/src/geoflutterfire.dart';
import 'package:driver/widget/geoflutterfire/src/models/point.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:location/location.dart';

class HomeController extends GetxController {
  // Simplificamos para apenas 2 tabs: Active e Completed
  RxInt selectedIndex = 0.obs;
  List<Widget> widgetOptions = <Widget>[
    const ActiveOrderScreen(),
    const OrderScreen()
  ];

  DashBoardController dashboardController = Get.put(DashBoardController());

  // Referência ao controller de atribuição automática
  late AutoAssignmentController autoAssignmentController;

  void onItemTapped(int index) {
    // CORREÇÃO: Validação para evitar RangeError
    if (index >= 0 && index < widgetOptions.length) {
      selectedIndex.value = index;
    } else {
      // Em caso de índice inválido, volta para o primeiro tab
      selectedIndex.value = 0;
    }
  }

  @override
  void onInit() {
    super.onInit();

    // CORREÇÃO: Validação inicial do selectedIndex
    if (selectedIndex.value >= widgetOptions.length) {
      selectedIndex.value = 0;
    }

    // Inicializa o sistema de atribuição automática
    Get.put(AutoAssignmentController());
    autoAssignmentController = AutoAssignmentController.instance;

    getDriver();
    getActiveRide();
    updateCurrentLocation();
  }

  Rx<DriverUserModel> driverModel = DriverUserModel().obs;
  RxBool isLoading = true.obs;
  RxBool hasError = false.obs;
  RxString errorMessage = ''.obs;
  RxInt isActiveValue = 0.obs;

  getDriver() async {
    try {
      isLoading.value = true;
      hasError.value = false;

      updateCurrentLocation();

      FireStoreUtils.fireStore
          .collection(CollectionName.driverUsers)
          .doc(FireStoreUtils.getCurrentUid())
          .snapshots()
          .listen(
        (event) {
          if (event.exists) {
            try {
              driverModel.value = DriverUserModel.fromJson(event.data()!);
              isLoading.value = false;
              hasError.value = false;
            } catch (e) {
              hasError.value = true;
              errorMessage.value = 'Erro ao processar dados do motorista';
              isLoading.value = false;
            }
          } else {
            hasError.value = true;
            errorMessage.value = 'Motorista não encontrado';
            isLoading.value = false;
          }
        },
        onError: (error) {
          hasError.value = true;
          errorMessage.value = 'Erro ao carregar dados: ${error.toString()}';
          isLoading.value = false;
        },
      );
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Erro inesperado: ${e.toString()}';
      isLoading.value = false;
    }
  }

  getActiveRide() {
    try {
      FireStoreUtils.fireStore
          .collection(CollectionName.orders)
          .where('driverId', isEqualTo: FireStoreUtils.getCurrentUid())
          .where('status',
              whereIn: [Constant.rideInProgress, Constant.rideActive])
          .snapshots()
          .listen(
            (event) {
              isActiveValue.value = event.docs.length;
            },
            onError: (error) {
              // Em caso de erro, mantém o valor atual
              isActiveValue.value = 0;
            },
          );
    } catch (e) {
      isActiveValue.value = 0;
    }
  }

  /// Tenta recarregar os dados do motorista
  Future<void> retryLoadDriver() async {
    await getDriver();
  }

  updateCurrentLocation() async {
    Location location = Location();

    try {
      // 1. Verificar se o serviço de localização está ativado
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          // Serviço de localização não habilitado
          return;
        }
      }

      // 2. Verificar permissão de localização
      PermissionStatus permissionStatus = await location.hasPermission();
      if (permissionStatus == PermissionStatus.denied) {
        permissionStatus = await location.requestPermission();
        if (permissionStatus != PermissionStatus.granted &&
            permissionStatus != PermissionStatus.grantedLimited) {
          // Permissão de localização negada
          return;
        }
      }

      // 3. Configurar modo background (Android)
      if (Platform.isAndroid) {
        try {
          await location.enableBackgroundMode(enable: true);
        } catch (e) {
          // Erro ao habilitar background mode - pode precisar de permissão "sempre"
        }
      } else {
        try {
          await location.enableBackgroundMode(enable: true);
        } catch (e) {
          // Erro no iOS - ignora
        }
      }

      // 4. Configurar precisão e intervalo de atualização
      await location.changeSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: double.parse(Constant.driverLocationUpdate.toString()),
        interval: 2000,
      );

      // 5. Escutar mudanças de localização
      location.onLocationChanged.listen(
        (locationData) {
          if (locationData.latitude != null && locationData.longitude != null) {
            Constant.currentLocation = LocationLatLng(
              latitude: locationData.latitude,
              longitude: locationData.longitude,
            );
            updateDriverLocation();
          }
        },
        onError: (error) {
          // Erro ao receber atualização de localização
        },
      );
    } catch (e) {
      // Erro geral ao configurar localização - app continua funcionando
    }
  }

  updateDriverLocation() async {
    if (Constant.currentLocation != null) {
      LocationLatLng locationLatLng = LocationLatLng(
        latitude: Constant.currentLocation!.latitude,
        longitude: Constant.currentLocation!.longitude,
      );

      GeoFirePoint position = Geoflutterfire().point(
        latitude: Constant.currentLocation!.latitude!,
        longitude: Constant.currentLocation!.longitude!,
      );

      Positions positions =
          Positions(geoPoint: position.geoPoint, geohash: position.hash);

      await FireStoreUtils.fireStore
          .collection(CollectionName.driverUsers)
          .doc(FireStoreUtils.getCurrentUid())
          .update({
        "location": locationLatLng.toJson(),
        "position": positions.toJson(),
        "g": position.data,
        "rotation": 0.0, // Usar 0.0 como padrão se não tiver heading
      });
    }
  }

  /// Alterna status online/offline do motorista
  Future<void> toggleOnlineStatus() async {
    await autoAssignmentController.toggleOnlineStatus();
  }

  // CORREÇÃO: Getter seguro para widget atual
  Widget get currentWidget {
    if (selectedIndex.value >= 0 &&
        selectedIndex.value < widgetOptions.length) {
      return widgetOptions[selectedIndex.value];
    } else {
      // selectedIndex fora do range, retorna primeiro widget
      selectedIndex.value = 0;
      return widgetOptions[0];
    }
  }

  // CORREÇÃO: Método para resetar para tab válida
  void resetToValidTab() {
    if (selectedIndex.value >= widgetOptions.length) {
      selectedIndex.value = 0;
    }
  }

  // Getter para validar se índice está correto
  bool get isValidIndex =>
      selectedIndex.value >= 0 && selectedIndex.value < widgetOptions.length;
}
