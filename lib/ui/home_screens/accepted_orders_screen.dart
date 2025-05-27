// accepted_orders_view.dart
import 'package:driver/constant/constant.dart';
import 'package:driver/controller/accepted_orders_controller.dart';
import 'package:driver/model/order/driverId_accept_reject.dart';
import 'package:driver/model/order_model.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:driver/widget/location_view.dart';
import 'package:driver/widget/user_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class AcceptedOrdersScreen extends StatelessWidget {
  const AcceptedOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return GetBuilder<AcceptedOrdersController>(
      init: AcceptedOrdersController(),
      builder: (controller) {
        return Obx(() {
          if (controller.acceptedOrders.isEmpty) {
            return Center(child: Text("No accepted ride found".tr));
          }
          return ListView.builder(
            itemCount: controller.acceptedOrders.length,
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemBuilder: (context, index) {
              final orderModel = controller.acceptedOrders[index];
              return AcceptedOrderItem(orderModel: orderModel, themeChange: themeChange);
            },
          );
        });
      },
    );
  }
}

class AcceptedOrderItem extends StatelessWidget {
  final OrderModel orderModel;
  final DarkThemeProvider themeChange;

  const AcceptedOrderItem({super.key, required this.orderModel, required this.themeChange});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AcceptedOrdersController>();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: themeChange.getThem() ? AppColors.darkContainerBackground : AppColors.containerBackground,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          border: Border.all(
            color: themeChange.getThem() ? AppColors.darkContainerBorder : AppColors.containerBorder,
            width: 0.5,
          ),
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
                amount: orderModel.offerRate,
                distance: orderModel.distance,
                distanceType: orderModel.distanceType,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 5),
                child: Divider(),
              ),
              FutureBuilder<DriverIdAcceptReject?>(
                future: controller.getDriverIdAcceptReject(orderModel.id.toString()),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Constant.loader(context);
                  } else if (snapshot.hasError || !snapshot.hasData) {
                    return Text('Error'.tr);
                  }
                  final driverIdAcceptReject = snapshot.data!;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: themeChange.getThem() ? AppColors.darkContainerBackground : AppColors.containerBackground,
                        borderRadius: const BorderRadius.all(Radius.circular(10)),
                        border: Border.all(
                          color: themeChange.getThem() ? AppColors.darkContainerBorder : AppColors.containerBorder,
                          width: 0.5,
                        ),
                        boxShadow: themeChange.getThem()
                            ? null
                            : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.10),
                            blurRadius: 5,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                "Offer Rate".tr,
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                              ),
                            ),
                            Text(Constant.amountShow(amount: driverIdAcceptReject.offerAmount.toString())),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              LocationView(
                sourceLocation: orderModel.sourceLocationName.toString(),
                destinationLocation: orderModel.destinationLocationName.toString(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
