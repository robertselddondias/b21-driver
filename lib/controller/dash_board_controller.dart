import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/ui/auth_screen/login_screen.dart';
import 'package:driver/ui/bank_details/bank_details_screen.dart';
import 'package:driver/ui/chat_screen/inbox_screen.dart';
import 'package:driver/ui/home_screens/home_screen.dart';
import 'package:driver/ui/online_registration/online_registartion_screen.dart';
import 'package:driver/ui/profile_screen/profile_screen.dart';
import 'package:driver/ui/settings_screen/setting_screen.dart';
import 'package:driver/ui/vehicle_information/vehicle_information_screen.dart';
import 'package:driver/ui/wallet/wallet_screen.dart';
import 'package:driver/utils/utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

class DashBoardController extends GetxController {
  final drawerItems = [
    DrawerItem('Home'.tr, "assets/icons/ic_city.svg"),
    // DrawerItem('Rides'.tr, "assets/icons/ic_order.svg"),
    // DrawerItem('OutStation'.tr, "assets/icons/ic_intercity.svg"),
    // DrawerItem('OutStation Rides'.tr, "assets/icons/ic_order.svg"),
    // DrawerItem('Freight'.tr, "assets/icons/ic_freight.svg"),
    DrawerItem('Minha Carteira'.tr, "assets/icons/ic_wallet.svg"),
    DrawerItem('Dados Bancários'.tr, "assets/icons/ic_profile.svg"),
    DrawerItem('Caixa Entrada'.tr, "assets/icons/ic_inbox.svg"),
    DrawerItem('Perfil'.tr, "assets/icons/ic_profile.svg"),
    DrawerItem('Documentos'.tr, "assets/icons/ic_document.svg"),
    DrawerItem('Informações do Veículo'.tr, "assets/icons/ic_city.svg"),
    DrawerItem('Configurações'.tr, "assets/icons/ic_settings.svg"),
    DrawerItem('Sair'.tr, "assets/icons/ic_logout.svg"),
  ];

  getDrawerItemWidget(int pos) {
    switch (pos) {
      case 0:
        return const HomeScreen();
      // case 1:
      //   return const OrderScreen();
      // case 1:
      //   return const HomeIntercityScreen();
      // // case 2:
      // //   return const OrderIntercityScreen();
      // case 2:
      //   return const FreightScreen();
      case 1:
        return const WalletScreen();
      case 2:
        return const BankDetailsScreen();
      case 3:
        return const InboxScreen();
      case 4:
        return const ProfileScreen();
      case 5:
        return const OnlineRegistrationScreen();
      case 6:
        return const VehicleInformationScreen();
      case 7:
        return const SettingScreen();
      default:
        return const Text("Error");
    }
  }

  RxInt selectedDrawerIndex = 0.obs;

  onSelectItem(int index) async {
    if (index == 8) {
      await FirebaseAuth.instance.signOut();
      Get.offAll(const LoginScreen());
    } else {
      selectedDrawerIndex.value = index;
    }
    Get.back();
  }

  @override
  void onInit() {
    // TODO: implement onInit
    getLocation();
    super.onInit();
  }

  getLocation() async {
    await Utils.determinePosition();
  }

  DateTime? currentBackPressTime;

  bool onWillPop() {
    DateTime now = DateTime.now();
    if (currentBackPressTime == null || now.difference(currentBackPressTime!) > const Duration(seconds: 2)) {
      currentBackPressTime = now;
      ShowToastDialog.showToast("Double press to exit", position: EasyLoadingToastPosition.center);
      return false;
    }
    return true;
  }
}

class DrawerItem {
  String title;
  String icon;

  DrawerItem(this.title, this.icon);
}
