// lib/ui/home_screens/home_screen.dart - Versão com temas e responsividade

import 'package:driver/controller/home_controller.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/responsive.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
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
          // CORREÇÃO: Valida e corrige o selectedIndex se necessário
          if (!controller.isValidIndex) {
            controller.resetToValidTab();
          }

          return Scaffold(
            backgroundColor: AppColors.primary,
            body: Column(
              children: [
                // Header com status online/offline
                _buildHeader(context, controller, themeChange),

                // Conteúdo principal
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
                    child: Column(
                      children: [
                        // Informações do motorista online
                        _buildDriverStatusCard(context, controller, themeChange),

                        // Conteúdo das tabs - CORREÇÃO: usando getter seguro
                        Expanded(
                          child: controller.currentWidget,
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
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(Responsive.width(1.5, context)),
                            child: Image.asset(
                              "assets/icons/ic_active.png",
                              width: Responsive.width(4.5, context),
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
                          padding: EdgeInsets.all(Responsive.width(1.5, context)),
                          child: Image.asset(
                            "assets/icons/ic_completed.png",
                            width: Responsive.width(4.5, context),
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
                    currentIndex: controller.isValidIndex ? controller.selectedIndex.value : 0,
                    selectedItemColor: AppColors.darkModePrimary,
                    unselectedItemColor: Colors.white,
                    selectedLabelStyle: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    onTap: controller.onItemTapped,
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _buildHeader(BuildContext context, HomeController controller, DarkThemeProvider themeChange) {
    return Container(
      width: Responsive.width(100, context),
      padding: EdgeInsets.only(
        top: Responsive.height(6, context),
        left: Responsive.width(5, context),
        right: Responsive.width(5, context),
        bottom: Responsive.height(2, context),
      ),
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
                    fontSize: Responsive.width(4.5, context),
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: Responsive.height(0.5, context)),
                Text(
                  controller.autoAssignmentController.isOnline.value
                      ? 'Você está online e recebendo corridas'
                      : 'Você está offline',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: Responsive.width(3.5, context),
                    fontWeight: FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          SizedBox(width: Responsive.width(2.5, context)),

          // Botão de alternância online/offline (tamanho fixo)
          GestureDetector(
            onTap: controller.toggleOnlineStatus,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.width(4, context),
                vertical: Responsive.height(1, context),
              ),
              decoration: BoxDecoration(
                color: controller.autoAssignmentController.isOnline.value
                    ? AppColors.darkModePrimary
                    : AppColors.subTitleColor,
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
                    size: Responsive.width(4, context),
                  ),
                  SizedBox(width: Responsive.width(1.2, context)),
                  Text(
                    controller.autoAssignmentController.isOnline.value
                        ? 'Online'
                        : 'Offline',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: Responsive.width(3, context),
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

  Widget _buildDriverStatusCard(BuildContext context, HomeController controller, DarkThemeProvider themeChange) {
    return Container(
      margin: EdgeInsets.all(Responsive.width(5, context)),
      padding: EdgeInsets.all(Responsive.width(5, context)),
      width: Responsive.width(90, context),
      decoration: BoxDecoration(
        color: themeChange.getThem()
            ? AppColors.darkContainerBackground
            : AppColors.containerBackground,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: themeChange.getThem()
              ? AppColors.darkContainerBorder
              : AppColors.containerBorder,
          width: 1,
        ),
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
                  fontSize: Responsive.width(4, context),
                  fontWeight: FontWeight.w600,
                  color: themeChange.getThem() ? Colors.white : Colors.black,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.width(3, context),
                  vertical: Responsive.height(0.7, context),
                ),
                decoration: BoxDecoration(
                  color: controller.autoAssignmentController.isOnline.value
                      ? AppColors.darkModePrimary.withOpacity(0.1)
                      : AppColors.subTitleColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: controller.autoAssignmentController.isOnline.value
                        ? AppColors.darkModePrimary
                        : AppColors.subTitleColor,
                    width: 1,
                  ),
                ),
                child: Text(
                  controller.autoAssignmentController.isOnline.value
                      ? 'ATIVO'
                      : 'INATIVO',
                  style: GoogleFonts.poppins(
                    fontSize: Responsive.width(3, context),
                    fontWeight: FontWeight.w600,
                    color: controller.autoAssignmentController.isOnline.value
                        ? AppColors.darkModePrimary
                        : AppColors.subTitleColor,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: Responsive.height(2, context)),

          if (controller.autoAssignmentController.isOnline.value) ...[
            Row(
              children: [
                Icon(
                  Icons.search,
                  color: AppColors.primary,
                  size: Responsive.width(5, context),
                ),
                SizedBox(width: Responsive.width(2.5, context)),
                Text(
                  'Procurando corridas próximas...',
                  style: GoogleFonts.poppins(
                    fontSize: Responsive.width(3.5, context),
                    color: AppColors.subTitleColor,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),

            SizedBox(height: Responsive.height(1.5, context)),

            LinearProgressIndicator(
              backgroundColor: AppColors.subTitleColor.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 3,
            ),
          ] else ...[
            Row(
              children: [
                Icon(
                  Icons.pause_circle,
                  color: AppColors.subTitleColor,
                  size: Responsive.width(5, context),
                ),
                SizedBox(width: Responsive.width(2.5, context)),
                Expanded(
                  child: Text(
                    'Vá para online para receber corridas',
                    style: GoogleFonts.poppins(
                      fontSize: Responsive.width(3.5, context),
                      color: AppColors.subTitleColor,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ],

          SizedBox(height: Responsive.height(2, context)),

          // Estatísticas rápidas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                context,
                'Corridas Ativas',
                controller.isActiveValue.value.toString(),
                Icons.directions_car,
                AppColors.primary,
                themeChange,
              ),
              Container(
                width: 1,
                height: Responsive.height(6, context),
                color: themeChange.getThem()
                    ? AppColors.darkContainerBorder
                    : AppColors.containerBorder,
              ),
              _buildStatItem(
                context,
                'Carteira',
                'R\$ ${controller.driverModel.value.walletAmount ?? '0.00'}',
                Icons.account_balance_wallet,
                AppColors.darkModePrimary,
                themeChange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      BuildContext context,
      String label,
      String value,
      IconData icon,
      Color color,
      DarkThemeProvider themeChange
      ) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: Responsive.height(1, context)),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(Responsive.width(2, context)),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: Responsive.width(6, context),
            ),
          ),
          SizedBox(height: Responsive.height(0.8, context)),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: Responsive.width(4, context),
              fontWeight: FontWeight.w700,
              color: themeChange.getThem() ? Colors.white : Colors.black,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: Responsive.width(3, context),
              color: AppColors.subTitleColor,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}