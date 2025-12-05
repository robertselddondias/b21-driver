// lib/ui/home_screens/home_screen.dart - Versão moderna e otimizada

import 'package:badges/badges.dart' as badges;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/constant/collection_name.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/controller/home_controller.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/responsive.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

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
            body: controller.hasError.value
                ? _buildErrorState(context, controller, themeChange, isDarkMode)
                : Column(
                    children: [
                      // Header com status online/offline
                      _buildHeader(context, controller, themeChange, isDarkMode),

                      // Conteúdo principal
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: Responsive.width(100, context),
                          decoration: BoxDecoration(
                            color: AppColors.getBackgroundColor(isDarkMode),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(30),
                              topRight: Radius.circular(30),
                            ),
                          ),
                          child: Column(
                            children: [
                              // Informações do motorista online - APENAS na aba Ativo (index 0)
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 350),
                                switchInCurve: Curves.easeInOut,
                                switchOutCurve: Curves.easeInOut,
                                transitionBuilder: (Widget child, Animation<double> animation) {
                                  return SizeTransition(
                                    sizeFactor: animation,
                                    axisAlignment: -1.0,
                                    child: FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    ),
                                  );
                                },
                                child: controller.selectedIndex.value == 0
                                    ? _buildDriverStatusCard(context, controller, themeChange, isDarkMode)
                                    : const SizedBox.shrink(),
                              ),

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

  Widget _buildErrorState(BuildContext context, HomeController controller, DarkThemeProvider themeChange, bool isDarkMode) {
    return Container(
      color: AppColors.getBackgroundColor(isDarkMode),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(Responsive.width(8, context)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(Responsive.width(8, context)),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.red.shade400.withOpacity(0.15),
                      Colors.red.shade600.withOpacity(0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: Responsive.width(20, context),
                  color: Colors.red.shade600,
                ),
              ),
              SizedBox(height: Responsive.height(3, context)),
              Text(
                'Ops! Algo deu errado',
                style: GoogleFonts.poppins(
                  fontSize: Responsive.width(5, context),
                  fontWeight: FontWeight.w700,
                  color: AppColors.getTextColor(isDarkMode),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: Responsive.height(1.5, context)),
              Text(
                controller.errorMessage.value.isNotEmpty
                    ? controller.errorMessage.value
                    : 'Não foi possível carregar seus dados',
                style: GoogleFonts.poppins(
                  fontSize: Responsive.width(3.8, context),
                  color: AppColors.getSecondaryTextColor(isDarkMode),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: Responsive.height(4, context)),
              ElevatedButton.icon(
                onPressed: controller.retryLoadDriver,
                icon: Icon(Icons.refresh_rounded, size: Responsive.width(5, context)),
                label: Text(
                  'Tentar Novamente',
                  style: GoogleFonts.poppins(
                    fontSize: Responsive.width(4, context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.width(8, context),
                    vertical: Responsive.height(2, context),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, HomeController controller, DarkThemeProvider themeChange, bool isDarkMode) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: Responsive.width(100, context),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: controller.autoAssignmentController.isOnline.value
              ? [AppColors.primary, AppColors.darkModePrimary]
              : [AppColors.primary.withOpacity(0.8), AppColors.primary.withOpacity(0.6)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: Responsive.height(1.5, context),
        left: Responsive.width(5, context),
        right: Responsive.width(5, context),
        bottom: Responsive.height(2, context),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Saudação compacta
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: controller.autoAssignmentController.isOnline.value
                        ? Colors.greenAccent
                        : Colors.grey.shade300,
                    boxShadow: controller.autoAssignmentController.isOnline.value
                        ? [
                            BoxShadow(
                              color: Colors.greenAccent.withOpacity(0.6),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                ),
                SizedBox(width: Responsive.width(3, context)),
                Flexible(
                  child: Text(
                    'Olá, ${controller.driverModel.value.fullName ?? 'Motorista'}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: Responsive.width(4.8, context),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Botão online/offline compacto
          GestureDetector(
            onTap: controller.toggleOnlineStatus,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.width(4, context),
                vertical: Responsive.height(1, context),
              ),
              decoration: BoxDecoration(
                color: controller.autoAssignmentController.isOnline.value
                    ? Colors.greenAccent.shade400
                    : Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: controller.autoAssignmentController.isOnline.value
                        ? Colors.greenAccent.withOpacity(0.4)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.power_settings_new_rounded,
                    color: Colors.white,
                    size: Responsive.width(4, context),
                  ),
                  SizedBox(width: Responsive.width(1.2, context)),
                  Text(
                    controller.autoAssignmentController.isOnline.value ? 'ON' : 'OFF',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: Responsive.width(3.2, context),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
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
    if (!controller.autoAssignmentController.isOnline.value) {
      // Estado OFFLINE - Mensagem simples e call-to-action
      return Container(
        margin: EdgeInsets.symmetric(
          horizontal: Responsive.width(5, context),
          vertical: Responsive.height(2, context),
        ),
        padding: EdgeInsets.all(Responsive.width(6, context)),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [Colors.grey.shade800, Colors.grey.shade900]
                : [Colors.grey.shade100, Colors.grey.shade200],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.getBorderColor(isDarkMode).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.offline_bolt_outlined,
              size: Responsive.width(12, context),
              color: Colors.grey.shade500,
            ),
            SizedBox(height: Responsive.height(1.5, context)),
            Text(
              'Você está offline',
              style: GoogleFonts.poppins(
                fontSize: Responsive.width(4.2, context),
                fontWeight: FontWeight.w700,
                color: AppColors.getTextColor(isDarkMode),
              ),
            ),
            SizedBox(height: Responsive.height(0.5, context)),
            Text(
              'Toque em ON para começar a receber corridas',
              style: GoogleFonts.poppins(
                fontSize: Responsive.width(3.3, context),
                color: AppColors.getSecondaryTextColor(isDarkMode),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Estado ONLINE - Grid de estatísticas 2x2
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: Responsive.width(5, context),
        vertical: Responsive.height(2, context),
      ),
      child: Column(
        children: [
          // Linha 1: Carteira e Avaliação
          Row(
            children: [
              Expanded(
                child: _buildModernStatCard(
                  context: context,
                  label: 'Carteira',
                  value: 'R\$ ${double.parse(controller.driverModel.value.walletAmount ?? '0.00').toStringAsFixed(2)}',
                  icon: Icons.account_balance_wallet_rounded,
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.green.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  isDarkMode: isDarkMode,
                ),
              ),
              SizedBox(width: Responsive.width(3, context)),
              Expanded(
                child: _buildModernStatCard(
                  context: context,
                  label: 'Avaliação',
                  value: _calculateRating(controller),
                  icon: Icons.star_rounded,
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade400, Colors.orange.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  isDarkMode: isDarkMode,
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.height(2, context)),
          // Linha 2: Total de corridas completadas (tempo real)
          _buildCompletedRidesCard(context, controller, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildCompletedRidesCard(BuildContext context, HomeController controller, bool isDarkMode) {
    return StreamBuilder<QuerySnapshot>(
      stream: FireStoreUtils.fireStore
          .collection(CollectionName.orders)
          .where('driverId', isEqualTo: FireStoreUtils.getCurrentUid())
          .where('status', isEqualTo: Constant.rideComplete)
          .snapshots(),
      builder: (context, snapshot) {
        int completedCount = 0;

        if (snapshot.hasData) {
          completedCount = snapshot.data!.docs.length;
        }

        return _buildFullWidthCard(
          context: context,
          label: 'Total de Corridas Completadas',
          value: '$completedCount',
          icon: Icons.done_all_rounded,
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.darkModePrimary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          isDarkMode: isDarkMode,
        );
      },
    );
  }

  String _calculateRating(HomeController controller) {
    try {
      final reviewsCount = controller.driverModel.value.reviewsCount;
      final reviewsSum = controller.driverModel.value.reviewsSum;

      if (reviewsCount == null || reviewsSum == null ||
          reviewsCount.isEmpty || reviewsSum.isEmpty ||
          reviewsCount == '0' || reviewsSum == '0') {
        return '5.0';
      }

      final count = double.tryParse(reviewsCount) ?? 0;
      final sum = double.tryParse(reviewsSum) ?? 0;

      if (count == 0) return '5.0';

      final rating = sum / count;
      return rating.toStringAsFixed(1);
    } catch (e) {
      return '5.0';
    }
  }

  Widget _buildModernStatCard({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    required Gradient gradient,
    required bool isDarkMode,
  }) {
    return Container(
      height: Responsive.height(13, context),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Ícone decorativo de fundo
          Positioned(
            right: -10,
            bottom: -10,
            child: Opacity(
              opacity: 0.15,
              child: Icon(
                icon,
                size: Responsive.width(20, context),
                color: Colors.white,
              ),
            ),
          ),
          // Conteúdo
          Padding(
            padding: EdgeInsets.all(Responsive.width(3.5, context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(Responsive.width(2, context)),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: Responsive.width(5, context),
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.poppins(
                        fontSize: Responsive.width(5, context),
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: Responsive.width(3, context),
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullWidthCard({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    required Gradient gradient,
    required bool isDarkMode,
  }) {
    return Container(
      height: Responsive.height(11.5, context),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Ícone decorativo de fundo
          Positioned(
            right: -15,
            top: -15,
            bottom: -15,
            child: Opacity(
              opacity: 0.15,
              child: Icon(
                icon,
                size: Responsive.width(25, context),
                color: Colors.white,
              ),
            ),
          ),
          // Conteúdo
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.width(5, context),
              vertical: Responsive.height(1.5, context),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(Responsive.width(3, context)),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: Responsive.width(6, context),
                  ),
                ),
                SizedBox(width: Responsive.width(4, context)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.poppins(
                          fontSize: Responsive.width(3.2, context),
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: Responsive.height(0.3, context)),
                      Text(
                        value,
                        style: GoogleFonts.poppins(
                          fontSize: Responsive.width(6, context),
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildBottomNavigation(BuildContext context, HomeController controller, DarkThemeProvider themeChange, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDarkMode
              ? [
                  AppColors.getContainerColor(isDarkMode).withOpacity(0.95),
                  AppColors.getContainerColor(isDarkMode),
                ]
              : [
                  Colors.white.withOpacity(0.98),
                  Colors.white,
                ],
        ),
        border: Border(
          top: BorderSide(
            color: AppColors.getBorderColor(isDarkMode).withOpacity(0.5),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            items: [
              BottomNavigationBarItem(
                icon: _buildNavItem(
                  context: context,
                  icon: Icons.local_taxi_rounded,
                  isSelected: controller.selectedIndex.value == 0,
                  isDarkMode: isDarkMode,
                ),
                label: 'Corridas'.tr,
              ),
              BottomNavigationBarItem(
                icon: _buildNavItem(
                  context: context,
                  icon: Icons.history_rounded,
                  isSelected: controller.selectedIndex.value == 1,
                  isDarkMode: isDarkMode,
                ),
                label: 'Histórico'.tr,
              ),
            ],
            type: BottomNavigationBarType.fixed,
            currentIndex: controller.isValidIndex ? controller.selectedIndex.value : 0,
            selectedItemColor: AppColors.getPrimaryColor(isDarkMode),
            unselectedItemColor: AppColors.getSecondaryTextColor(isDarkMode),
            selectedLabelStyle: GoogleFonts.poppins(
              fontSize: Responsive.width(3.2, context),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(
              fontSize: Responsive.width(3, context),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
            onTap: controller.onItemTapped,
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required bool isSelected,
    required bool isDarkMode,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: EdgeInsets.all(Responsive.width(2, context)),
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                colors: [
                  AppColors.getPrimaryColor(isDarkMode).withOpacity(0.2),
                  AppColors.getPrimaryColor(isDarkMode).withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(
                color: AppColors.getPrimaryColor(isDarkMode).withOpacity(0.3),
                width: 2,
              )
            : null,
      ),
      child: Icon(
        icon,
        color: isSelected
            ? AppColors.getPrimaryColor(isDarkMode)
            : AppColors.getSecondaryTextColor(isDarkMode),
        size: Responsive.width(6, context),
      ),
    );
  }
}