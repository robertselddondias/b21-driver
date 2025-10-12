import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:driver/controller/live_tracking_controller.dart';
import 'package:driver/constant/constant.dart';

class LiveTrackingScreen extends StatelessWidget {
  const LiveTrackingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LiveTrackingController());

    return Scaffold(
      appBar: AppBar(
        title: const Text("Rastreamento de Viagem"),
      ),
      body: Obx(
            () {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(controller.driverCurrentPosition.value.latitude, controller.driverCurrentPosition.value.longitude),
                  zoom: 10.5,
                  bearing: controller.driverCurrentPosition.value.heading,

                ),
                // DESATIVANDO O ÍCONE PADRÃO PARA USAR O PERSONALIZADO
                myLocationEnabled: false,
                compassEnabled: true,
                tiltGesturesEnabled: true,

                onMapCreated: (GoogleMapController mapController) {
                  controller.mapController = mapController;
                },
                markers: Set<Marker>.of(controller.markers.values),
                polylines: Set<Polyline>.of(controller.polyLines.values),
              ),

              Positioned(
                bottom: 150,
                right: 20,
                child: FloatingActionButton(
                  heroTag: 'followMeBtn',
                  backgroundColor: Colors.white,
                  onPressed: () {
                    controller.toggleFollowMe();
                  },
                  child: Obx(
                        () => Icon(
                      controller.followMe.value ? Icons.gps_not_fixed : Icons.gps_fixed,
                      color: controller.followMe.value ? Colors.blue : Colors.grey,
                    ),
                  ),
                ),
              ),

              Positioned(
                bottom: 20,
                left: 10,
                right: 10,
                child: NavigationInfoCard(),
              ),

              Positioned(
                top: 10,
                left: 10,
                right: 10,
                child: SpeedDisplayCard(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class NavigationInfoCard extends StatelessWidget {
  final controller = Get.find<LiveTrackingController>();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
        child: Obx(
              () => Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Tempo Restante",
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  Text(
                    "${controller.etaInMinutes.value} min",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "Distância",
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  Text(
                    "${controller.distanceRemaining.value.toStringAsFixed(1)} km",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SpeedDisplayCard extends StatelessWidget {
  final controller = Get.find<LiveTrackingController>();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Obx(
              () => Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Velocidade Atual",
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  Text(
                    "${controller.currentSpeed.value.toStringAsFixed(0)} km/h",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Expanded(
                child: Text(
                  controller.streetName.value,
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}