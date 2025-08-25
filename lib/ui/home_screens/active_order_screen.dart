// lib/ui/home_screens/active_order_screen.dart - Versão corrigida baseada no código original
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/constant/collection_name.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/send_notification.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/controller/active_order_controller.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/model/order_model.dart';
import 'package:driver/model/user_model.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/button_them.dart';
import 'package:driver/ui/chat_screen/chat_screen.dart';
import 'package:driver/ui/home_screens/live_tracking_screen.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:driver/utils/utils.dart';
import 'package:driver/widget/location_view.dart';
import 'package:driver/widget/rating_dialog.dart'; // Import do novo widget
import 'package:driver/widget/user_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class ActiveOrderScreen extends StatelessWidget {
  const ActiveOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return GetBuilder<ActiveOrderController>(
        init: ActiveOrderController(),
        builder: (controller) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(CollectionName.orders)
                .where('driverId', isEqualTo: FireStoreUtils.getCurrentUid())
                .where('status', whereIn: [Constant.rideInProgress, Constant.rideActive]).snapshots(),
            builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasError) {
                return Text('Something went wrong'.tr);
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Constant.loader(context);
              }
              return snapshot.data!.docs.isEmpty
                  ? Center(
                child: Text("No active rides Found".tr),
              )
                  : ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    OrderModel orderModel = OrderModel.fromJson(snapshot.data!.docs[index].data() as Map<String, dynamic>);
                    return InkWell(
                      onTap: () {
                        if (Constant.mapType == "inappmap") {
                          if (orderModel.status == Constant.rideActive || orderModel.status == Constant.rideInProgress) {
                            Get.to(const LiveTrackingScreen(), arguments: {
                              "orderModel": orderModel,
                              "type": "orderModel",
                            });
                          }
                        } else {
                          if (orderModel.status == Constant.rideInProgress) {
                            Utils.redirectMap(
                                latitude: orderModel.destinationLocationLAtLng!.latitude!,
                                longLatitude: orderModel.destinationLocationLAtLng!.longitude!,
                                name: orderModel.destinationLocationName.toString());
                          } else {
                            Utils.redirectMap(
                                latitude: orderModel.sourceLocationLAtLng!.latitude!,
                                longLatitude: orderModel.sourceLocationLAtLng!.longitude!,
                                name: orderModel.destinationLocationName.toString());
                          }
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: themeChange.getThem() ? AppColors.darkContainerBackground : AppColors.containerBackground,
                            borderRadius: const BorderRadius.all(Radius.circular(10)),
                            border: Border.all(color: themeChange.getThem() ? AppColors.darkContainerBorder : AppColors.containerBorder, width: 0.5),
                            boxShadow: themeChange.getThem()
                                ? null
                                : [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                            child: Column(
                              children: [
                                UserView(
                                  userId: orderModel.userId,
                                  amount: orderModel.finalRate,
                                  distance: orderModel.distance,
                                  distanceType: orderModel.distanceType,
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 5),
                                  child: Divider(),
                                ),
                                LocationView(
                                  sourceLocation: orderModel.sourceLocationName.toString(),
                                  destinationLocation: orderModel.destinationLocationName.toString(),
                                ),
                                const SizedBox(height: 10),

                                // LAYOUT ORIGINAL: Botões com diferentes estruturas dependendo do status
                                Row(
                                  children: [
                                    // PRIMEIRO BOTÃO: Complete Ride OU Pickup Customer (ocupa todo espaço quando rideInProgress)
                                    Expanded(
                                      child: orderModel.status == Constant.rideInProgress
                                          ? ButtonThem.buildBorderButton(
                                        context,
                                        title: "Complete Ride".tr,
                                        btnHeight: 44,
                                        iconVisibility: false,
                                        onPress: () async {
                                          // NOVA FUNCIONALIDADE: Mostrar dialog de avaliação antes de completar
                                          _showRatingDialog(context, orderModel, controller, themeChange);
                                        },
                                      )
                                          : ButtonThem.buildBorderButton(
                                        context,
                                        title: "Pickup Customer".tr,
                                        btnHeight: 44,
                                        iconVisibility: false,
                                        onPress: () async {
                                          // Executar pickup diretamente sem OTP
                                          await _pickupCustomer(orderModel);
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),

                                    // SEGUNDA SEÇÃO: Chat e Call (só aparecem quando NÃO é rideInProgress)
                                    if (orderModel.status == Constant.rideActive) ...[
                                      Row(
                                        children: [
                                          // Botão Chat
                                          InkWell(
                                            onTap: () async {
                                              UserModel? customer = await FireStoreUtils.getCustomer(orderModel.userId.toString());
                                              DriverUserModel? driver = await FireStoreUtils.getDriverProfile(orderModel.driverId.toString());

                                              Get.to(const ChatScreens(), arguments: {
                                                "orderId": orderModel.id.toString(),
                                                "customerId": orderModel.userId.toString(),
                                                "driverId": FireStoreUtils.getCurrentUid(),
                                                "customerName": customer?.fullName ?? '',
                                                "customerProfilePic": customer?.profilePic ?? '',
                                              });
                                            },
                                            child: Container(
                                              height: 44,
                                              width: 44,
                                              decoration: BoxDecoration(
                                                  color: themeChange.getThem() ? AppColors.darkModePrimary : AppColors.primary,
                                                  borderRadius: BorderRadius.circular(5)
                                              ),
                                              child: Icon(Icons.chat, color: themeChange.getThem() ? Colors.black : Colors.white),
                                            ),
                                          ),
                                          const SizedBox(width: 10),

                                          // Botão Call
                                          InkWell(
                                            onTap: () async {
                                              UserModel? customer = await FireStoreUtils.getCustomer(orderModel.userId.toString());
                                              Constant.makePhoneCall("${customer!.countryCode}${customer.phoneNumber}");
                                            },
                                            child: Container(
                                              height: 44,
                                              width: 44,
                                              decoration: BoxDecoration(
                                                  color: themeChange.getThem() ? AppColors.darkModePrimary : AppColors.primary,
                                                  borderRadius: BorderRadius.circular(5)
                                              ),
                                              child: Icon(Icons.call, color: themeChange.getThem() ? Colors.black : Colors.white),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  });
            },
          );
        });
  }

  // NOVA FUNÇÃO: Mostrar dialog de avaliação
  void _showRatingDialog(BuildContext context, OrderModel orderModel, ActiveOrderController controller, DarkThemeProvider themeChange) {
    Get.dialog(
      RatingDialog(
        orderModel: orderModel,
        onComplete: () async {
          // Após a avaliação, completar a corrida
          await _completeRide(orderModel, controller);
        },
      ),
      barrierDismissible: false,
    );
  }

  // Função para completar a corrida (lógica original completa)
  Future<void> _completeRide(OrderModel orderModel, ActiveOrderController controller) async {
    try {
      orderModel.status = Constant.rideComplete;
      orderModel.paymentStatus = true;

      await FireStoreUtils.getCustomer(orderModel.userId.toString()).then((value) async {
        if (value != null) {
          if (value.fcmToken != null) {
            Map<String, dynamic> playLoad = <String, dynamic>{"type": "city_order_complete", "orderId": orderModel.id};

            await SendNotification.sendOneNotification(
                token: value.fcmToken.toString(),
                title: 'Ride complete!'.tr,
                body: 'Ride Complete successfully.'.tr,
                payload: playLoad);
          }
        }
      });

      await FireStoreUtils.setOrder(orderModel).then((value) {
        if (value == true) {
          ShowToastDialog.showToast("Ride Complete successfully".tr);
          controller.homeController.selectedIndex.value = 3; // Índice original do código
        }
      });
    } catch (error) {
      ShowToastDialog.showToast("Erro ao completar corrida: $error");
    }
  }

  // Função para fazer pickup do cliente (sem OTP)
  Future<void> _pickupCustomer(OrderModel orderModel) async {
    try {
      ShowToastDialog.showLoader("Please wait...".tr);

      orderModel.status = Constant.rideInProgress;

      await FireStoreUtils.getCustomer(orderModel.userId.toString()).then((value) async {
        if (value != null) {
          await SendNotification.sendOneNotification(
              token: value.fcmToken.toString(),
              title: 'Ride Started'.tr,
              body: 'The ride has officially started. Please follow the designated route to the destination.'.tr,
              payload: {});
        }
      });

      await FireStoreUtils.setOrder(orderModel).then((value) {
        if (value == true) {
          ShowToastDialog.closeLoader();
          ShowToastDialog.showToast("Customer pickup successfully".tr);
        }
      });
    } catch (error) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Erro ao fazer pickup: $error");
    }
  }
}