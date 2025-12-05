import 'package:driver/controller/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ActiveOrderController extends GetxController {
  HomeController homeController = Get.put(HomeController());
  TextEditingController otpController = TextEditingController();
}
