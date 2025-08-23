// lib/controller/home_controller.dart - Versão corrigida

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
      print('⚠️ Índice inválido: $index. Máximo permitido: ${widgetOptions.length - 1}');
      selectedIndex.value = 0; // Volta para o primeiro tab
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
  RxInt isActiveValue = 0.obs;

  getDriver() async {
    updateCurrentLocation();
    FireStoreUtils.fireStore
        .collection(CollectionName.driverUsers)
        .doc(FireStoreUtils.getCurrentUid())
        .snapshots()
        .listen((event) {
      if (event.exists) {
        driverModel.value = DriverUserModel.fromJson(event.data()!);
        isLoading.value = false;
      }
    });
  }

  getActiveRide() {
    FireStoreUtils.fireStore
        .collection(CollectionName.orders)
        .where('driverId', isEqualTo: FireStoreUtils.getCurrentUid())
        .where('status', whereIn: [Constant.rideInProgress, Constant.rideActive])
        .snapshots()
        .listen((event) {
      isActiveValue.value = event.docs.length;
    });
  }

  updateCurrentLocation() async {
    Location location = Location();
    PermissionStatus permissionStatus = await location.hasPermission();

    if (permissionStatus == PermissionStatus.granted) {
      location.enableBackgroundMode(enable: true);
      location.changeSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: double.parse(Constant.driverLocationUpdate.toString()),
          interval: 2000
      );

      location.onLocationChanged.listen((locationData) {
        Constant.currentLocation = LocationLatLng(
            latitude: locationData.latitude,
            longitude: locationData.longitude
        );
        updateDriverLocation();
      });
    } else {
      location.requestPermission().then((permissionStatus) {
        if (permissionStatus == PermissionStatus.granted) {
          location.enableBackgroundMode(enable: true);
          location.changeSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: double.parse(Constant.driverLocationUpdate.toString()),
              interval: 2000
          );

          location.onLocationChanged.listen((locationData) {
            Constant.currentLocation = LocationLatLng(
                latitude: locationData.latitude,
                longitude: locationData.longitude
            );
            updateDriverLocation();
          });
        }
      });
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

      Positions positions = Positions(
          geoPoint: position.geoPoint,
          geohash: position.hash
      );

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
    if (selectedIndex.value >= 0 && selectedIndex.value < widgetOptions.length) {
      return widgetOptions[selectedIndex.value];
    } else {
      print('⚠️ selectedIndex fora do range, retornando primeiro widget');
      selectedIndex.value = 0;
      return widgetOptions[0];
    }
  }

  // CORREÇÃO: Método para resetar para tab válida
  void resetToValidTab() {
    if (selectedIndex.value >= widgetOptions.length) {
      selectedIndex.value = 0;
      print('🔄 Reset para tab 0 devido a índice inválido');
    }
  }

  // Getter para validar se índice está correto
  bool get isValidIndex =>
      selectedIndex.value >= 0 && selectedIndex.value < widgetOptions.length;
}