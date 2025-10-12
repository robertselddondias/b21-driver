import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:driver/constant/collection_name.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/model/order_model.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class LiveTrackingController extends GetxController {
  GoogleMapController? mapController;
  Rx<OrderModel> orderModel = OrderModel().obs;
  RxString streetName = "Obtendo sua localização...".obs;
  RxBool isLoading = true.obs;
  RxBool followMe = true.obs;

  StreamSubscription<Position>? locationSubscription;
  Rx<Position> driverCurrentPosition = Position(
    longitude: 0.0,
    latitude: 0.0,
    timestamp: DateTime.now(),
    accuracy: 0.0,
    altitude: 0.0,
    heading: 0.0,
    speed: 0.0,
    speedAccuracy: 0.0,
    altitudeAccuracy: 0.0,
    headingAccuracy: 0.0,
  ).obs;

  RxString etaInMinutes = "0".obs;
  RxDouble distanceRemaining = 0.0.obs;
  RxDouble currentSpeed = 0.0.obs;

  RxMap<MarkerId, Marker> markers = <MarkerId, Marker>{}.obs;
  RxMap<PolylineId, Polyline> polyLines = <PolylineId, Polyline>{}.obs;
  PolylinePoints polylinePoints = PolylinePoints();
  BitmapDescriptor? departureIcon;
  BitmapDescriptor? destinationIcon;
  BitmapDescriptor? driverIcon;

  @override
  void onInit() {
    addMarkerSetup();
    getArgument();
    super.onInit();
  }

  @override
  void onClose() {
    locationSubscription?.cancel();
    ShowToastDialog.closeLoader();
    super.onClose();
  }

  getArgument() async {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      OrderModel argumentOrderModel = argumentData['orderModel'];

      await startLocationTracking();

      FireStoreUtils.fireStore.collection(CollectionName.orders).doc(argumentOrderModel.id).snapshots().listen((event) async {
        if (event.data() != null) {
          OrderModel orderModelStream = OrderModel.fromJson(event.data()!);
          orderModel.value = orderModelStream;

          if (orderModel.value.status == Constant.rideInProgress) {
            getPolyline(
                sourceLatitude: driverCurrentPosition.value.latitude,
                sourceLongitude: driverCurrentPosition.value.longitude,
                destinationLatitude: orderModel.value.destinationLocationLAtLng!.latitude,
                destinationLongitude: orderModel.value.destinationLocationLAtLng!.longitude);
          } else {
            getPolyline(
                sourceLatitude: driverCurrentPosition.value.latitude,
                sourceLongitude: driverCurrentPosition.value.longitude,
                destinationLatitude: orderModel.value.sourceLocationLAtLng!.latitude,
                destinationLongitude: orderModel.value.sourceLocationLAtLng!.longitude);
          }
        }
      });
    }
    isLoading.value = false;
    update();
  }

  Future<void> startLocationTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Serviços de localização estão desativados.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Permissão de localização negada.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Permissão de localização negada permanentemente.');
    }

    Position initialPosition = await Geolocator.getCurrentPosition();
    driverCurrentPosition.value = initialPosition;
    updateCameraPosition(initialPosition);

    locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),
    ).listen((Position position) async {
      driverCurrentPosition.value = position;
      currentSpeed.value = position.speed * 3.6;
      streetName.value = await getStreetName(position.latitude, position.longitude);
      updateCameraPosition(position);

      addMarker(
          latitude: position.latitude,
          longitude: position.longitude,
          id: "driver",
          descriptor: driverIcon!,
          rotation: position.heading);
    });
  }

  void updateCameraPosition(Position position) {
    if (followMe.value && mapController != null) {
      final newCameraPosition = CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 18.5,
        bearing: position.heading,
        tilt: 55.0,
      );
      mapController!.animateCamera(CameraUpdate.newCameraPosition(newCameraPosition));
    }
  }

  void toggleFollowMe() {
    followMe.value = !followMe.value;
    if (followMe.value) {
      updateCameraPosition(driverCurrentPosition.value);
    }
  }

  Future<String> getStreetName(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        return placemarks.first.street ?? "Rua Desconhecida";
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao obter o nome da rua: $e');
      }
    }
    return "Rua Desconhecida";
  }

  void getPolyline({
    required double? sourceLatitude,
    required double? sourceLongitude,
    required double? destinationLatitude,
    required double? destinationLongitude
  }) async {
    if (sourceLatitude != null && sourceLongitude != null && destinationLatitude != null && destinationLongitude != null) {
      ShowToastDialog.showLoader("Calculando rota...");

      try {
        final String url = "https://maps.googleapis.com/maps/api/directions/json"
            "?origin=$sourceLatitude,$sourceLongitude"
            "&destination=$destinationLatitude,$destinationLongitude"
            "&mode=driving"
            "&key=${Constant.mapAPIKey}";

        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          if (data["status"] == "OK") {
            if (data["routes"] != null && data["routes"].isNotEmpty) {
              final route = data["routes"][0];
              final polylineString = route["overview_polyline"]["points"];
              final polylineCoordinates = polylinePoints.decodePolyline(polylineString);

              if (route["legs"] != null && route["legs"].isNotEmpty) {
                final leg = route["legs"][0];
                if (leg["distance"] != null && leg["distance"]["value"] != null) {
                  distanceRemaining.value = (leg["distance"]["value"] / 1000).toDouble();
                }
                if (leg["duration"] != null && leg["duration"]["value"] != null) {
                  etaInMinutes.value = (leg["duration"]["value"] / 60).toStringAsFixed(0);
                }
              }
              _addPolyLine(polylineCoordinates.map((p) => LatLng(p.latitude, p.longitude)).toList());
            }
          } else {
            if (kDebugMode) {
              print('Erro na API de Rotas: ${data["error_message"]}');
            }
          }
        } else {
          if (kDebugMode) {
            print('Falha na chamada HTTP com o status: ${response.statusCode}');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Erro inesperado: $e');
        }
      } finally {
        ShowToastDialog.closeLoader();
      }

      addMarker(
          latitude: orderModel.value.sourceLocationLAtLng!.latitude,
          longitude: orderModel.value.sourceLocationLAtLng!.longitude,
          id: "Departure",
          descriptor: departureIcon!,
          rotation: 0.0);
      addMarker(
          latitude: orderModel.value.destinationLocationLAtLng!.latitude,
          longitude: orderModel.value.destinationLocationLAtLng!.longitude,
          id: "Destination",
          descriptor: destinationIcon!,
          rotation: 0.0);
    }
  }

  addMarkerSetup() async {
    final Uint8List departure = await Constant().getBytesFromAsset('assets/images/pickup.png', 100);
    final Uint8List destination = await Constant().getBytesFromAsset('assets/images/dropoff.png', 100);
    final Uint8List driver = await Constant().getBytesFromAsset('assets/images/ic_cab.png', 120);

    departureIcon = BitmapDescriptor.fromBytes(departure);
    destinationIcon = BitmapDescriptor.fromBytes(destination);
    driverIcon = BitmapDescriptor.fromBytes(driver);
  }

  addMarker({required double? latitude, required double? longitude, required String id, required BitmapDescriptor descriptor, required double? rotation}) {
    MarkerId markerId = MarkerId(id);
    Marker marker = Marker(markerId: markerId, icon: descriptor, position: LatLng(latitude ?? 0.0, longitude ?? 0.0), rotation: rotation ?? 0.0);
    markers[markerId] = marker;
  }

  _addPolyLine(List<LatLng> polylineCoordinates) {
    PolylineId id = const PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      points: polylineCoordinates,
      consumeTapEvents: true,
      startCap: Cap.roundCap,
      width: 6,
    );
    polyLines[id] = polyline;
    updateCameraLocationBounds(polylineCoordinates.first, polylineCoordinates.last, mapController);
  }

  Future<void> updateCameraLocationBounds(
      LatLng source,
      LatLng destination,
      GoogleMapController? mapController,
      ) async {
    if (mapController == null) return;

    LatLngBounds bounds;

    if (source.latitude > destination.latitude && source.longitude > destination.longitude) {
      bounds = LatLngBounds(southwest: destination, northeast: source);
    } else if (source.longitude > destination.longitude) {
      bounds = LatLngBounds(southwest: LatLng(source.latitude, destination.longitude), northeast: LatLng(destination.latitude, source.longitude));
    } else if (source.latitude > destination.latitude) {
      bounds = LatLngBounds(southwest: LatLng(destination.latitude, source.longitude), northeast: LatLng(source.latitude, destination.longitude));
    } else {
      bounds = LatLngBounds(southwest: source, northeast: destination);
    }

    CameraUpdate cameraUpdate = CameraUpdate.newLatLngBounds(bounds, 10);

    return checkCameraLocation(cameraUpdate, mapController);
  }

  Future<void> checkCameraLocation(CameraUpdate cameraUpdate, GoogleMapController mapController) async {
    mapController.animateCamera(cameraUpdate);
    LatLngBounds l1 = await mapController.getVisibleRegion();
    LatLngBounds l2 = await mapController.getVisibleRegion();

    if (l1.southwest.latitude == -90 || l2.southwest.latitude == -90) {
      return checkCameraLocation(cameraUpdate, mapController);
    }
  }
}