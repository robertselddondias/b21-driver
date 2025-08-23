// lib/ui/dashboard_screen.dart - Versão com temas e responsividade
import 'package:cached_network_image/cached_network_image.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/controller/auto_assignment_controller.dart';
import 'package:driver/controller/dash_board_controller.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/responsive.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class DashBoardScreen extends StatefulWidget {
  const DashBoardScreen({super.key});

  @override
  State<DashBoardScreen> createState() => _DashBoardScreenState();
}

class _DashBoardScreenState extends State<DashBoardScreen> {
  @override
  void initState() {
    super.initState();
    // Inicializa o controlador de atribuição automática
    Get.put(AutoAssignmentController());
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return GetX<DashBoardController>(
        init: DashBoardController(),
        builder: (controller) {
          return Scaffold(
            backgroundColor: themeChange.getThem()
                ? AppColors.darkBackground
                : AppColors.background,
            appBar: _buildAppBar(context, controller, themeChange),
            drawer: _buildAppDrawer(context, controller, themeChange),
            body: WillPopScope(
              onWillPop: controller.onWillPop,
              child: controller.getDrawerItemWidget(controller.selectedDrawerIndex.value),
            ),
          );
        }
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, DashBoardController controller, DarkThemeProvider themeChange) {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      title: controller.selectedDrawerIndex.value == 0
          ? _buildOnlineStatusToggle(context, themeChange)
          : Text(
        controller.drawerItems[controller.selectedDrawerIndex.value].title,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: Responsive.width(4, context),
        ),
      ),
      centerTitle: true,
      leading: Builder(
          builder: (context) {
            return InkWell(
              onTap: () {
                Scaffold.of(context).openDrawer();
              },
              child: Container(
                margin: EdgeInsets.all(Responsive.width(3, context)),
                child: SvgPicture.asset(
                  'assets/icons/ic_humber.svg',
                  width: Responsive.width(6, context),
                  height: Responsive.width(6, context),
                  color: Colors.white,
                ),
              ),
            );
          }
      ),
    );
  }

  Widget _buildOnlineStatusToggle(BuildContext context, DarkThemeProvider themeChange) {
    return GetBuilder<AutoAssignmentController>(
        builder: (autoController) {
          return Obx(() {
            return GestureDetector(
              onTap: () async {
                ShowToastDialog.showLoader("Aguarde...".tr);
                await autoController.toggleOnlineStatus();
                ShowToastDialog.closeLoader();
              },
              child: Container(
                width: Responsive.width(40, context),
                height: Responsive.height(4.5, context),
                decoration: BoxDecoration(
                  color: themeChange.getThem()
                      ? AppColors.darkContainerBackground
                      : AppColors.containerBackground,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: themeChange.getThem()
                        ? AppColors.darkContainerBorder
                        : AppColors.containerBorder,
                    width: 1,
                  ),
                ),
                child: Stack(
                  children: [
                    // Background animado
                    AnimatedAlign(
                      alignment: Alignment(autoController.isOnline.value ? -1 : 1, 0),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: Container(
                        width: Responsive.width(20, context),
                        height: Responsive.height(4.5, context),
                        decoration: BoxDecoration(
                          color: autoController.isOnline.value
                              ? AppColors.darkModePrimary
                              : AppColors.subTitleColor,
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                    // Texto Online
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: Responsive.width(20, context),
                        alignment: Alignment.center,
                        child: Text(
                          'Online'.tr,
                          style: GoogleFonts.poppins(
                            color: autoController.isOnline.value
                                ? Colors.white
                                : (themeChange.getThem() ? Colors.white70 : Colors.black54),
                            fontWeight: FontWeight.w600,
                            fontSize: Responsive.width(3, context),
                          ),
                        ),
                      ),
                    ),
                    // Texto Offline
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: Responsive.width(20, context),
                        alignment: Alignment.center,
                        child: Text(
                          'Offline'.tr,
                          style: GoogleFonts.poppins(
                            color: !autoController.isOnline.value
                                ? Colors.white
                                : (themeChange.getThem() ? Colors.white70 : Colors.black54),
                            fontWeight: FontWeight.w600,
                            fontSize: Responsive.width(3, context),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          });
        }
    );
  }

  Widget _buildAppDrawer(BuildContext context, DashBoardController controller, DarkThemeProvider themeChange) {
    return Drawer(
      backgroundColor: themeChange.getThem()
          ? AppColors.darkBackground
          : AppColors.background,
      child: Column(
        children: [
          _buildDrawerHeader(context, themeChange),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.width(2, context),
                vertical: Responsive.height(1, context),
              ),
              itemCount: controller.drawerItems.length,
              itemBuilder: (context, index) {
                var item = controller.drawerItems[index];
                bool isSelected = index == controller.selectedDrawerIndex.value;

                return Container(
                  margin: EdgeInsets.symmetric(
                    vertical: Responsive.height(0.5, context),
                    horizontal: Responsive.width(1, context),
                  ),
                  child: InkWell(
                    onTap: () {
                      controller.onSelectItem(index);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.width(4, context),
                        vertical: Responsive.height(1.2, context),
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? null
                            : Border.all(
                          color: themeChange.getThem()
                              ? AppColors.darkContainerBorder.withOpacity(0.3)
                              : AppColors.containerBorder.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(Responsive.width(1.8, context)),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withOpacity(0.1)
                                  : (themeChange.getThem()
                                  ? AppColors.darkContainerBackground
                                  : AppColors.containerBackground),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SvgPicture.asset(
                              item.icon,
                              width: Responsive.width(4.5, context),
                              height: Responsive.width(4.5, context),
                              color: isSelected
                                  ? Colors.white
                                  : (themeChange.getThem()
                                  ? Colors.white
                                  : AppColors.drawerIcon),
                            ),
                          ),
                          SizedBox(width: Responsive.width(3.5, context)),
                          Expanded(
                            child: Text(
                              item.title,
                              style: GoogleFonts.poppins(
                                color: isSelected
                                    ? Colors.white
                                    : (themeChange.getThem()
                                    ? Colors.white
                                    : Colors.black87),
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                fontSize: Responsive.width(3.3, context),
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.chevron_right,
                              color: Colors.white,
                              size: Responsive.width(4.5, context),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context, DarkThemeProvider themeChange) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(Responsive.width(4, context)),
          child: FutureBuilder<DriverUserModel?>(
              future: FireStoreUtils.getDriverProfile(FireStoreUtils.getCurrentUid()),
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.waiting:
                    return SizedBox(
                      height: Responsive.height(15, context),
                      child: Center(child: Constant.loader(context)),
                    );
                  case ConnectionState.done:
                    if (snapshot.hasError) {
                      return SizedBox(
                        height: Responsive.height(15, context),
                        child: Center(
                          child: Text(
                            'Error loading profile',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: Responsive.width(3, context),
                            ),
                          ),
                        ),
                      );
                    } else {
                      DriverUserModel driverModel = snapshot.data!;
                      return IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Avatar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(25),
                              child: CachedNetworkImage(
                                height: Responsive.width(12, context),
                                width: Responsive.width(12, context),
                                imageUrl: driverModel.profilePic.toString(),
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey.withOpacity(0.3),
                                  child: Center(
                                    child: SizedBox(
                                      width: Responsive.width(5, context),
                                      height: Responsive.width(5, context),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey.withOpacity(0.3),
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: Responsive.width(6, context),
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: Responsive.height(1, context)),

                            // Nome
                            Text(
                              driverModel.fullName.toString(),
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontSize: Responsive.width(3.8, context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),

                            SizedBox(height: Responsive.height(0.3, context)),

                            // Email
                            Text(
                              driverModel.email.toString(),
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: Responsive.width(2.8, context),
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),

                            SizedBox(height: Responsive.height(0.8, context)),

                            // Status Online/Offline
                            GetBuilder<AutoAssignmentController>(
                                builder: (autoController) {
                                  return Obx(() {
                                    return Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: Responsive.width(2.5, context),
                                        vertical: Responsive.height(0.4, context),
                                      ),
                                      decoration: BoxDecoration(
                                        color: autoController.isOnline.value
                                            ? AppColors.darkModePrimary.withOpacity(0.2)
                                            : AppColors.subTitleColor.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: autoController.isOnline.value
                                              ? AppColors.darkModePrimary
                                              : AppColors.subTitleColor,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: Responsive.width(1.8, context),
                                            height: Responsive.width(1.8, context),
                                            decoration: BoxDecoration(
                                              color: autoController.isOnline.value
                                                  ? AppColors.darkModePrimary
                                                  : AppColors.subTitleColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          SizedBox(width: Responsive.width(1.5, context)),
                                          Text(
                                            autoController.isOnline.value
                                                ? 'Online - Ativo'
                                                : 'Offline',
                                            style: GoogleFonts.poppins(
                                              color: autoController.isOnline.value
                                                  ? AppColors.darkModePrimary
                                                  : AppColors.subTitleColor,
                                              fontSize: Responsive.width(2.5, context),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  });
                                }
                            ),
                          ],
                        ),
                      );
                    }
                  default:
                    return SizedBox(
                      height: Responsive.height(15, context),
                      child: Center(
                        child: Text(
                          'Error'.tr,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: Responsive.width(3, context),
                          ),
                        ),
                      ),
                    );
                }
              }
          ),
        ),
      ),
    );
  }

  Future<void> _showAlertDialog(BuildContext context, String type) async {
    final themeChange = Provider.of<DarkThemeProvider>(context, listen: false);
    final controllerDashBoard = Get.put(DashBoardController());

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: themeChange.getThem()
              ? AppColors.darkContainerBackground
              : AppColors.containerBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(
              color: themeChange.getThem()
                  ? AppColors.darkContainerBorder
                  : AppColors.containerBorder,
              width: 1,
            ),
          ),
          title: Text(
            'Information'.tr,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: Responsive.width(4.5, context),
              color: themeChange.getThem() ? Colors.white : Colors.black,
            ),
          ),
          content: SingleChildScrollView(
            child: Text(
              'To start earning with GoRide you need to fill in your personal information'.tr,
              style: GoogleFonts.poppins(
                fontSize: Responsive.width(3.5, context),
                color: themeChange.getThem() ? Colors.white70 : Colors.black87,
                height: 1.4,
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.width(5, context),
                  vertical: Responsive.height(1, context),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'No'.tr,
                style: GoogleFonts.poppins(
                  color: AppColors.subTitleColor,
                  fontWeight: FontWeight.w500,
                  fontSize: Responsive.width(3.5, context),
                ),
              ),
              onPressed: () {
                Get.back();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.width(5, context),
                  vertical: Responsive.height(1, context),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Yes'.tr,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: Responsive.width(3.5, context),
                ),
              ),
              onPressed: () {
                Get.back();
                if (type == "document") {
                  controllerDashBoard.onSelectItem(5);
                } else {
                  controllerDashBoard.onSelectItem(6);
                }
              },
            ),
          ],
        );
      },
    );
  }
}