import 'package:driver/themes/app_colors.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:driver/controller/live_tracking_controller.dart';
import 'package:provider/provider.dart';

class LiveTrackingScreen extends StatelessWidget {
  const LiveTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LiveTrackingController());
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeChange.getThem()
          ? AppColors.darkBackground
          : AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          "Rastreamento de Viagem".tr,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  "Carregando mapa...".tr,
                  style: GoogleFonts.poppins(
                    color: themeChange.getThem() ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          );
        }

        return Stack(
          children: [
            // Mapa
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  controller.driverCurrentPosition.value.latitude,
                  controller.driverCurrentPosition.value.longitude,
                ),
                zoom: 16.5,
                bearing: controller.driverCurrentPosition.value.heading,
                tilt: 55.0,
              ),
              myLocationEnabled: false, // Usando marcador customizado
              compassEnabled: true,
              tiltGesturesEnabled: true,
              rotateGesturesEnabled: true,
              scrollGesturesEnabled: true,
              zoomGesturesEnabled: true,
              mapToolbarEnabled: false,
              onMapCreated: (GoogleMapController mapController) {
                controller.mapController = mapController;
              },
              markers: Set<Marker>.of(controller.markers.values),
              polylines: Set<Polyline>.of(controller.polyLines.values),
              // Tipo de mapa
              mapType: MapType.normal,
            ),

            // Botão Follow Me
            Positioned(
              bottom: 170,
              right: 16,
              child: FloatingActionButton(
                heroTag: 'followMeBtn',
                backgroundColor: Colors.white,
                elevation: 4,
                onPressed: () {
                  controller.toggleFollowMe();
                },
                child: Obx(() => Icon(
                  controller.followMe.value
                      ? Icons.gps_fixed
                      : Icons.gps_not_fixed,
                  color: controller.followMe.value
                      ? AppColors.primary
                      : Colors.grey,
                  size: 28,
                )),
              ),
            ),

            // Card de informações de navegação
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: NavigationInfoCard(themeChange: themeChange),
            ),

            // Card de velocidade e rua
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: SpeedDisplayCard(themeChange: themeChange),
            ),
          ],
        );
      }),
    );
  }
}

class NavigationInfoCard extends StatelessWidget {
  final DarkThemeProvider themeChange;

  const NavigationInfoCard({super.key, required this.themeChange});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LiveTrackingController>();

    return Card(
      elevation: 8.0,
      color: themeChange.getThem()
          ? AppColors.darkContainerBackground
          : AppColors.containerBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: themeChange.getThem()
              ? AppColors.darkContainerBorder
              : AppColors.containerBorder,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Obx(() => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Tempo restante
            _buildInfoColumn(
              icon: Icons.access_time,
              label: "Tempo Restante".tr,
              value: "${controller.etaInMinutes.value} min",
              iconColor: AppColors.primary,
            ),

            // Divider vertical
            Container(
              height: 50,
              width: 1,
              color: themeChange.getThem()
                  ? AppColors.darkContainerBorder
                  : AppColors.containerBorder,
            ),

            // Distância
            _buildInfoColumn(
              icon: Icons.straighten,
              label: "Distância".tr,
              value: "${controller.distanceRemaining.value.toStringAsFixed(1)} km",
              iconColor: Colors.blue,
            ),
          ],
        )),
      ),
    );
  }

  Widget _buildInfoColumn({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: themeChange.getThem()
                  ? Colors.grey.shade400
                  : Colors.grey.shade600,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: themeChange.getThem() ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class SpeedDisplayCard extends StatelessWidget {
  final DarkThemeProvider themeChange;

  const SpeedDisplayCard({super.key, required this.themeChange});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LiveTrackingController>();

    return Card(
      elevation: 8.0,
      color: themeChange.getThem()
          ? AppColors.darkContainerBackground
          : AppColors.containerBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: themeChange.getThem()
              ? AppColors.darkContainerBorder
              : AppColors.containerBorder,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Obx(() => Row(
          children: [
            // Ícone de velocímetro
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.speed,
                color: AppColors.primary,
                size: 28,
              ),
            ),

            const SizedBox(width: 12),

            // Velocidade
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Velocidade Atual".tr,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: themeChange.getThem()
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                  ),
                ),
                Text(
                  "${controller.currentSpeed.value.toStringAsFixed(0)} km/h",
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color:
                    themeChange.getThem() ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Nome da rua
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(
                    Icons.place,
                    color: themeChange.getThem()
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                    size: 16,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    controller.streetName.value,
                    textAlign: TextAlign.end,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: themeChange.getThem()
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        )),
      ),
    );
  }
}