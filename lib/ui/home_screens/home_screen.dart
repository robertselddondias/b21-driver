// lib/ui/home_screens/home_screen.dart
import 'package:driver/controller/home_controller.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return GetBuilder<HomeController>(
      init: HomeController(),
      builder: (controller) {
        return Obx(() {
          return Column(
            children: [
              // Header com status online/offline
              _buildHeader(controller, themeChange),

              // Conteúdo principal
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: themeChange.getThem()
                        ? AppColors.darkBackground
                        : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Informações do motorista online
                      _buildDriverStatusCard(controller, themeChange),

                      // Conteúdo das tabs
                      Expanded(
                        child: controller.widgetOptions[controller.selectedIndex.value],
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Navigation simplificado
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: BottomNavigationBar(
                  items: [
                    BottomNavigationBarItem(
                      icon: badges.Badge(
                        badgeContent: Text(
                          controller.isActiveValue.value.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Image.asset(
                            "assets/icons/ic_active.png",
                            width: 18,
                            color: controller.selectedIndex.value == 0
                                ? AppColors.darkModePrimary
                                : Colors.white,
                          ),
                        ),
                      ),
                      label: 'Ativo'.tr,
                    ),
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Image.asset(
                          "assets/icons/ic_completed.png",
                          width: 18,
                          color: controller.selectedIndex.value == 1
                              ? AppColors.darkModePrimary
                              : Colors.white,
                        ),
                      ),
                      label: 'Histórico'.tr,
                    ),
                  ],
                  backgroundColor: AppColors.primary,
                  type: BottomNavigationBarType.fixed,
                  currentIndex: controller.selectedIndex.value,
                  selectedItemColor: AppColors.darkModePrimary,
                  unselectedItemColor: Colors.white,
                  selectedFontSize: 12,
                  unselectedFontSize: 12,
                  onTap: controller.onItemTapped,
                ),
              ),
            ],
          );
        });
      },
    );
  }

  Widget _buildHeader(HomeController controller, DarkThemeProvider themeChange) {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
      child: Row(
        children: [
          // Coluna com informações do motorista (flex)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, ${controller.driverModel.value.fullName ?? 'Motorista'}!',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  controller.autoAssignmentController.isOnline.value
                      ? 'Você está online e recebendo corridas'
                      : 'Você está offline',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Botão de alternância online/offline (tamanho fixo)
          GestureDetector(
            onTap: controller.toggleOnlineStatus,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: controller.autoAssignmentController.isOnline.value
                    ? Colors.green
                    : Colors.red,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    controller.autoAssignmentController.isOnline.value
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    controller.autoAssignmentController.isOnline.value
                        ? 'Online'
                        : 'Offline',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverStatusCard(HomeController controller, DarkThemeProvider themeChange) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeChange.getThem()
            ? AppColors.darkContainerBackground
            : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Status do Motorista',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: themeChange.getThem() ? Colors.white : Colors.black,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: controller.autoAssignmentController.isOnline.value
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: controller.autoAssignmentController.isOnline.value
                        ? Colors.green
                        : Colors.red,
                    width: 1,
                  ),
                ),
                child: Text(
                  controller.autoAssignmentController.isOnline.value
                      ? 'ATIVO'
                      : 'INATIVO',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: controller.autoAssignmentController.isOnline.value
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          if (controller.autoAssignmentController.isOnline.value) ...[
            Row(
              children: [
                Icon(
                  Icons.search,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'Procurando corridas próximas...',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            LinearProgressIndicator(
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ] else ...[
            Row(
              children: [
                const Icon(
                  Icons.pause_circle,
                  color: Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'Vá para online para receber corridas',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 15),

          // Estatísticas rápidas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Corridas Ativas',
                controller.isActiveValue.value.toString(),
                Icons.directions_car,
                AppColors.primary,
                themeChange,
              ),
              _buildStatItem(
                'Carteira',
                'R\$ ${controller.driverModel.value.walletAmount ?? '0.00'}',
                Icons.account_balance_wallet,
                Colors.green,
                themeChange,
              ),
              _buildStatItem(
                'Avaliação',
                '${_calculateRating(controller)}★',
                Icons.star,
                Colors.orange,
                themeChange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color, DarkThemeProvider themeChange) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: themeChange.getThem() ? Colors.white : Colors.black,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  String _calculateRating(HomeController controller) {
    try {
      double reviewsSum = double.parse(controller.driverModel.value.reviewsSum ?? '0');
      double reviewsCount = double.parse(controller.driverModel.value.reviewsCount ?? '0');

      if (reviewsCount > 0) {
        double average = reviewsSum / reviewsCount;
        return average.toStringAsFixed(1);
      }
    } catch (e) {
      // Ignore parsing errors
    }
    return '5.0';
  }
}