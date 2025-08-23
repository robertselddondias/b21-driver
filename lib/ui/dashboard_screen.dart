// lib/ui/dashboard_screen.dart
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
            backgroundColor: themeChange.getThem() ? AppColors.darkBackground : AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.primary,
              elevation: 0,
              title: controller.selectedDrawerIndex.value == 0
                  ? _buildOnlineStatusToggle(themeChange)
                  : Text(
                controller.drawerItems[controller.selectedDrawerIndex.value].title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              centerTitle: true,
              leading: Builder(
                  builder: (context) {
                    return InkWell(
                      onTap: () {
                        Scaffold.of(context).openDrawer();
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10, right: 20, top: 20, bottom: 20),
                        child: SvgPicture.asset('assets/icons/ic_humber.svg'),
                      ),
                    );
                  }
              ),
            ),
            drawer: buildAppDrawer(context, controller, themeChange),
            body: WillPopScope(
              onWillPop: controller.onWillPop,
              child: controller.getDrawerItemWidget(controller.selectedDrawerIndex.value),
            ),
          );
        }
    );
  }

  Widget _buildOnlineStatusToggle(DarkThemeProvider themeChange) {
    return GetBuilder<AutoAssignmentController>(
        builder: (autoController) {
          return Obx(() {
            return GestureDetector(
              onTap: autoController.toggleOnlineStatus,
              child: Container(
                width: Responsive.width(50, context),
                height: Responsive.height(5.5, context),
                decoration: const BoxDecoration(
                  color: AppColors.darkBackground,
                  borderRadius: BorderRadius.all(Radius.circular(50.0)),
                ),
                child: Stack(
                  children: [
                    AnimatedAlign(
                      alignment: Alignment(autoController.isOnline.value ? -1 : 1, 0),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeIn,
                      child: Container(
                        width: Responsive.width(26, context),
                        height: Responsive.height(5.5, context),
                        decoration: BoxDecoration(
                          color: autoController.isOnline.value ? Colors.green : Colors.red,
                          borderRadius: const BorderRadius.all(Radius.circular(50.0)),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        ShowToastDialog.showLoader("Aguarde...".tr);
                        await autoController.toggleOnlineStatus();
                        ShowToastDialog.closeLoader();
                      },
                      child: Align(
                        alignment: const Alignment(-1, 0),
                        child: Container(
                          width: Responsive.width(26, context),
                          color: Colors.transparent,
                          alignment: Alignment.center,
                          child: Text(
                            'Online'.tr,
                            style: GoogleFonts.poppins(
                              color: autoController.isOnline.value ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        ShowToastDialog.showLoader("Aguarde...".tr);
                        await autoController.toggleOnlineStatus();
                        ShowToastDialog.closeLoader();
                      },
                      child: Align(
                        alignment: const Alignment(1, 0),
                        child: Container(
                          width: Responsive.width(26, context),
                          color: Colors.transparent,
                          alignment: Alignment.center,
                          child: Text(
                            'Offline'.tr,
                            style: GoogleFonts.poppins(
                              color: autoController.isOnline.value ? Colors.black : Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
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

  buildAppDrawer(BuildContext context, DashBoardController controller, DarkThemeProvider themeChange) {
    var drawerOptions = <Widget>[];
    for (var i = 0; i < controller.drawerItems.length; i++) {
      var d = controller.drawerItems[i];
      drawerOptions.add(InkWell(
        onTap: () {
          controller.onSelectItem(i);
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: i == controller.selectedDrawerIndex.value
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                SvgPicture.asset(
                  d.icon,
                  width: 20,
                  color: i == controller.selectedDrawerIndex.value
                      ? themeChange.getThem()
                      ? Colors.black
                      : Colors.white
                      : themeChange.getThem()
                      ? Colors.white
                      : AppColors.drawerIcon,
                ),
                const SizedBox(width: 20),
                Text(
                  d.title,
                  style: GoogleFonts.poppins(
                    color: i == controller.selectedDrawerIndex.value
                        ? themeChange.getThem()
                        ? Colors.black
                        : Colors.white
                        : themeChange.getThem()
                        ? Colors.white
                        : Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                )
              ],
            ),
          ),
        ),
      ));
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
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
            child: FutureBuilder<DriverUserModel?>(
                future: FireStoreUtils.getDriverProfile(FireStoreUtils.getCurrentUid()),
                builder: (context, snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.waiting:
                      return Constant.loader(context);
                    case ConnectionState.done:
                      if (snapshot.hasError) {
                        return Text(snapshot.error.toString());
                      } else {
                        DriverUserModel driverModel = snapshot.data!;
                        return SingleChildScrollView( // Adicionado ScrollView para evitar overflow
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min, // Adicionado para minimizar o tamanho
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(60),
                                child: CachedNetworkImage(
                                  height: Responsive.width(12, context), // Reduzido de 15 para 12
                                  width: Responsive.width(12, context),
                                  imageUrl: driverModel.profilePic.toString(),
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Constant.loader(context),
                                  errorWidget: (context, url, error) =>
                                      Image.network(Constant.userPlaceHolder),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 6), // Reduzido de 10 para 6
                                child: Text(
                                  driverModel.fullName.toString(),
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                    fontSize: 14, // Adicionado tamanho específico
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 1), // Reduzido de 2 para 1
                                child: Text(
                                  driverModel.email.toString(),
                                  style: GoogleFonts.poppins(
                                    color: Colors.white70,
                                    fontSize: 11, // Reduzido de 12 para 11
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 4), // Reduzido de 8 para 4
                              GetBuilder<AutoAssignmentController>(
                                  builder: (autoController) {
                                    return Obx(() {
                                      return Row(
                                        children: [
                                          Container(
                                            width: 6, // Reduzido de 8 para 6
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: autoController.isOnline.value
                                                  ? Colors.green
                                                  : Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 6), // Reduzido de 8 para 6
                                          Expanded( // Adicionado Expanded
                                            child: Text(
                                              autoController.isOnline.value
                                                  ? 'Online - Ativo'
                                                  : 'Offline',
                                              style: GoogleFonts.poppins(
                                                color: Colors.white70,
                                                fontSize: 10, // Reduzido de 11 para 10
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      );
                                    });
                                  }
                              ),
                            ],
                          ),
                        );
                      }
                    default:
                      return Text('Error'.tr);
                  }
                }),
          ),
          Column(children: drawerOptions),
        ],
      ),
    );
  }

  Future<void> _showAlertDialog(BuildContext context, String type) async {
    final controllerDashBoard = Get.put(DashBoardController());

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Information'.tr),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('To start earning with GoRide you need to fill in your personal information'.tr),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('No'.tr),
              onPressed: () {
                Get.back();
              },
            ),
            TextButton(
              child: Text('Yes'.tr),
              onPressed: () {
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