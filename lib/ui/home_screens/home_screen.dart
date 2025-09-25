// lib/ui/home_screens/home_screen.dart - Versão com cores otimizadas

import 'package:badges/badges.dart' as badges;
import 'package:driver/controller/home_controller.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/responsive.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDarkMode = themeChange.getThem();

    return GetBuilder<HomeController>(
      init: HomeController(),
      builder: (controller) {
        return Obx(() {
          // CORREÇÃO: Valida e corrige o selectedIndex se necessário
          if (!controller.isValidIndex) {
            controller.resetToValidTab();
          }

          return Scaffold(
            backgroundColor: AppColors.getBackgroundColor(isDarkMode),
            // CORREÇÃO: AppBar para controlar a cor da status bar
            appBar: AppBar(
              backgroundColor: AppColors.primary,
              elevation: 0,
              toolbarHeight: 0,
              systemOverlayStyle: SystemUiOverlayStyle(
                statusBarColor: AppColors.primary,
                statusBarIconBrightness: Brightness.light,
                statusBarBrightness: Brightness.dark,
              ),
            ),
            body: Column(
              children: [
                // Header com status online/offline
                _buildHeader(context, controller, themeChange, isDarkMode),

                // Conteúdo principal
                Expanded(
                  child: Container(
                    width: Responsive.width(100, context),
                    decoration: BoxDecoration(
                      color: AppColors.getBackgroundColor(isDarkMode),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(25),
                        topRight: Radius.circular(25),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Indicador de arraste
                        Container(
                          margin: EdgeInsets.symmetric(
                            vertical: Responsive.height(1.5, context),
                          ),
                          width: Responsive.width(12, context),
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.white.withOpacity(0.4)
                                : Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),

                        // Informações do motorista online
                        _buildDriverStatusCard(context, controller, themeChange, isDarkMode),

                        // Conteúdo das tabs - CORREÇÃO: usando getter seguro
                        Expanded(
                          child: Container(
                            color: AppColors.getBackgroundColor(isDarkMode),
                            child: controller.currentWidget,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Navigation corrigido
                _buildBottomNavigation(context, controller, themeChange, isDarkMode),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _buildHeader(BuildContext context, HomeController controller, DarkThemeProvider themeChange, bool isDarkMode) {
    return Container(
      width: Responsive.width(100, context),
      color: AppColors.primary,
      padding: EdgeInsets.only(
        top: Responsive.height(1, context), // Reduzido já que AppBar controla status bar
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
                    color: Colors.white.withOpacity(0.8),
                    fontSize: Responsive.width(3.5, context),
                    fontWeight: FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          SizedBox(width: Responsive.width(2.5, context)),

          // Botão de alternância online/offline melhorado
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
                    : Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: controller.autoAssignmentController.isOnline.value
                      ? AppColors.darkModePrimary
                      : Colors.white.withOpacity(0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: controller.autoAssignmentController.isOnline.value
                        ? AppColors.darkModePrimary.withOpacity(0.3)
                        : Colors.black.withOpacity(0.2),
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

  Widget _buildDriverStatusCard(BuildContext context, HomeController controller, DarkThemeProvider themeChange, bool isDarkMode) {
    return Container(
      margin: EdgeInsets.all(Responsive.width(5, context)),
      padding: EdgeInsets.all(Responsive.width(5, context)),
      width: Responsive.width(90, context),
      decoration: BoxDecoration(
        color: AppColors.getContainerColor(isDarkMode),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppColors.getBorderColor(isDarkMode),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.4)
                : Colors.black.withOpacity(0.08),
            blurRadius: isDarkMode ? 15 : 10,
            offset: const Offset(0, 3),
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
                  color: AppColors.getTextColor(isDarkMode),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.width(3, context),
                  vertical: Responsive.height(0.7, context),
                ),
                decoration: BoxDecoration(
                  color: controller.autoAssignmentController.isOnline.value
                      ? AppColors.getSuccessColor(isDarkMode).withOpacity(isDarkMode ? 0.25 : 0.1)
                      : AppColors.getSecondaryTextColor(isDarkMode).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: controller.autoAssignmentController.isOnline.value
                        ? AppColors.getSuccessColor(isDarkMode)
                        : AppColors.getSecondaryTextColor(isDarkMode),
                    width: 1.5,
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
                        ? AppColors.getSuccessColor(isDarkMode)
                        : AppColors.getSecondaryTextColor(isDarkMode),
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
                  color: AppColors.getPrimaryColor(isDarkMode),
                  size: Responsive.width(5, context),
                ),
                SizedBox(width: Responsive.width(2.5, context)),
                Text(
                  'Procurando corridas próximas...',
                  style: GoogleFonts.poppins(
                    fontSize: Responsive.width(3.5, context),
                    color: AppColors.getSecondaryTextColor(isDarkMode),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),

            SizedBox(height: Responsive.height(1.5, context)),

            LinearProgressIndicator(
              backgroundColor: isDarkMode
                  ? Colors.white.withOpacity(0.2)
                  : AppColors.subTitleColor.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.getPrimaryColor(isDarkMode)
              ),
              minHeight: 4,
            ),
          ] else ...[
            Row(
              children: [
                Icon(
                  Icons.pause_circle,
                  color: AppColors.getSecondaryTextColor(isDarkMode),
                  size: Responsive.width(5, context),
                ),
                SizedBox(width: Responsive.width(2.5, context)),
                Expanded(
                  child: Text(
                    'Vá para online para receber corridas',
                    style: GoogleFonts.poppins(
                      fontSize: Responsive.width(3.5, context),
                      color: AppColors.getSecondaryTextColor(isDarkMode),
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
                AppColors.getPrimaryColor(isDarkMode),
                themeChange,
                isDarkMode,
              ),
              Container(
                width: 2,
                height: Responsive.height(6, context),
                decoration: BoxDecoration(
                  color: AppColors.getBorderColor(isDarkMode),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              _buildStatItem(
                context,
                'Carteira',
                'R\$ ${double.parse(controller.driverModel.value.walletAmount ?? '0.00').toStringAsFixed(2)}',
                Icons.account_balance_wallet,
                AppColors.darkModePrimary,
                themeChange,
                isDarkMode,
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
      DarkThemeProvider themeChange,
      bool isDarkMode
      ) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: Responsive.height(1, context)),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(Responsive.width(2.5, context)),
            decoration: BoxDecoration(
              color: color.withOpacity(isDarkMode ? 0.25 : 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withOpacity(isDarkMode ? 0.5 : 0.3),
                width: 1,
              ),
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
              color: AppColors.getTextColor(isDarkMode),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: Responsive.width(3, context),
              color: AppColors.getSecondaryTextColor(isDarkMode),
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context, HomeController controller, DarkThemeProvider themeChange, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getContainerColor(isDarkMode),
        border: Border(
          top: BorderSide(
            color: AppColors.getBorderColor(isDarkMode),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        items: [
          BottomNavigationBarItem(
            icon: badges.Badge(
              badgeContent: Text(
                controller.isActiveValue.value.toString(),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              badgeStyle: badges.BadgeStyle(
                badgeColor: AppColors.primary,
                padding: const EdgeInsets.all(6),
              ),
              child: Container(
                padding: EdgeInsets.all(Responsive.width(1.5, context)),
                child: Image.asset(
                  "assets/icons/ic_active.png",
                  width: Responsive.width(5, context),
                  color: controller.selectedIndex.value == 0
                      ? AppColors.getPrimaryColor(isDarkMode)
                      : AppColors.getSecondaryTextColor(isDarkMode),
                ),
              ),
            ),
            label: 'Ativo'.tr,
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: EdgeInsets.all(Responsive.width(1.5, context)),
              child: Image.asset(
                "assets/icons/ic_completed.png",
                width: Responsive.width(5, context),
                color: controller.selectedIndex.value == 1
                    ? AppColors.getPrimaryColor(isDarkMode)
                    : AppColors.getSecondaryTextColor(isDarkMode),
              ),
            ),
            label: 'Histórico'.tr,
          ),
        ],
        type: BottomNavigationBarType.fixed,
        currentIndex: controller.isValidIndex ? controller.selectedIndex.value : 0,
        selectedItemColor: AppColors.getPrimaryColor(isDarkMode),
        unselectedItemColor: AppColors.getSecondaryTextColor(isDarkMode),
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
    );
  }
}