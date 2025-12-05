// accepted_orders_view.dart
import 'dart:ui';

import 'package:driver/constant/constant.dart';
import 'package:driver/controller/accepted_orders_controller.dart';
import 'package:driver/model/order/driverId_accept_reject.dart';
import 'package:driver/model/order_model.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/responsive.dart';
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
              return AcceptedOrderItem(
                  orderModel: orderModel, themeChange: themeChange);
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

  const AcceptedOrderItem(
      {super.key, required this.orderModel, required this.themeChange});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AcceptedOrdersController>();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: themeChange.getThem()
              ? AppColors.darkContainerBackground
              : AppColors.containerBackground,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          border: Border.all(
            color: themeChange.getThem()
                ? AppColors.darkContainerBorder
                : AppColors.containerBorder,
            width: 0.5,
          ),
          boxShadow: themeChange.getThem()
              ? null
              : [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.5),
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
                future: controller
                    .getDriverIdAcceptReject(orderModel.id.toString()),
                builder: (context, snapshot) {
                  // Estado de carregamento
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Container(
                        height: 50,
                        alignment: Alignment.center,
                        child: Constant.loader(context),
                      ),
                    );
                  }

                  // Tratamento de erro
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(10)),
                          border: Border.all(color: Colors.red, width: 1),
                        ),
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Erro ao carregar dados do pedido'.tr,
                                style: GoogleFonts.poppins(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Tratamento de dados nulos ou vazios
                  if (!snapshot.hasData || snapshot.data == null) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: themeChange.getThem()
                              ? AppColors.darkContainerBackground
                              : AppColors.containerBackground,
                          borderRadius:
                              const BorderRadius.all(Radius.circular(10)),
                          border: Border.all(
                            color: themeChange.getThem()
                                ? AppColors.darkContainerBorder
                                : AppColors.containerBorder,
                            width: 0.5,
                          ),
                        ),
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                "Offer Rate".tr,
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            Text(
                              Constant.amountShow(
                                  amount: orderModel.offerRate ?? '0.00'),
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Dados válidos encontrados
                  final driverIdAcceptReject = snapshot.data!;

                  // Validação adicional do objeto
                  final offerAmount = driverIdAcceptReject.offerAmount;
                  final displayAmount = (offerAmount != null &&
                          offerAmount.isNotEmpty &&
                          offerAmount != 'null')
                      ? offerAmount
                      : (orderModel.offerRate ?? '0.00');

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: themeChange.getThem()
                            ? AppColors.darkContainerBackground
                            : AppColors.containerBackground,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(10)),
                        border: Border.all(
                          color: themeChange.getThem()
                              ? AppColors.darkContainerBorder
                              : AppColors.containerBorder,
                          width: 0.5,
                        ),
                        boxShadow: themeChange.getThem()
                            ? null
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.10),
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
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            Text(
                              Constant.amountShow(amount: displayAmount),
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
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
                destinationLocation:
                    orderModel.destinationLocationName.toString(),
              ),
              const SizedBox(height: 15),

              // NOVA SEÇÃO: Timer de Expiração e Ações
              if (orderModel.isAutoAssigned) ...[
                _buildExpirationTimer(context, orderModel, themeChange),
                const SizedBox(height: 10),
              ],

              // Botões de Ação
              _buildActionButtons(context, orderModel, themeChange),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpirationTimer(BuildContext context, OrderModel orderModel,
      DarkThemeProvider themeChange) {
    return StreamBuilder<int>(
      stream: Stream.periodic(Duration(seconds: 1), (count) => count),
      builder: (context, snapshot) {
        final minutesRemaining = 15 - orderModel.minutesSinceAssignment;
        final secondsTotal = (minutesRemaining * 60) -
            (DateTime.now().difference(orderModel.assignedAt!.toDate()).inSeconds % 60);

        if (secondsTotal <= 0) {
          return Container(
            padding: EdgeInsets.all(Responsive.width(3, context)),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red, width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_rounded, color: Colors.red, size: 20),
                SizedBox(width: Responsive.width(2, context)),
                Expanded(
                  child: Text(
                    'Atribuição expirada! Esta corrida será reatribuída.',
                    style: GoogleFonts.poppins(
                      fontSize: Responsive.width(3, context),
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final minutes = secondsTotal ~/ 60;
        final seconds = secondsTotal % 60;
        final isUrgent = secondsTotal < 120; // Menos de 2 minutos

        return Container(
          padding: EdgeInsets.all(Responsive.width(3, context)),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isUrgent
                  ? [
                      Colors.red.withValues(alpha: 0.15),
                      Colors.deepOrange.withValues(alpha: 0.1),
                    ]
                  : [
                      Colors.orange.withValues(alpha: 0.15),
                      Colors.amber.withValues(alpha: 0.1),
                    ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isUrgent
                  ? Colors.red.withValues(alpha: 0.3)
                  : Colors.orange.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isUrgent ? Icons.timer_off_rounded : Icons.timer_rounded,
                color: isUrgent ? Colors.red : Colors.orange,
                size: Responsive.width(5, context),
              ),
              SizedBox(width: Responsive.width(2, context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tempo para aceitar:',
                      style: GoogleFonts.poppins(
                        fontSize: Responsive.width(3, context),
                        color: AppColors.subTitleColor,
                      ),
                    ),
                    Text(
                      '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                      style: GoogleFonts.poppins(
                        fontSize: Responsive.width(5, context),
                        fontWeight: FontWeight.w700,
                        color: isUrgent ? Colors.red : Colors.orange,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context, OrderModel orderModel,
      DarkThemeProvider themeChange) {
    return Row(
      children: [
        // Botão Navegar
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // Navegar para origem
              Get.toNamed('/order-map', arguments: {
                'orderModel': orderModel.id.toString(),
              });
            },
            icon: Icon(Icons.navigation, size: Responsive.width(4.5, context)),
            label: Text(
              'Navegar',
              style: GoogleFonts.poppins(
                fontSize: Responsive.width(3.5, context),
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                vertical: Responsive.height(1.5, context),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),

        SizedBox(width: Responsive.width(2, context)),

        // Botão Ver Detalhes
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Get.toNamed('/order-map', arguments: {
                'orderModel': orderModel.id.toString(),
              });
            },
            icon: Icon(Icons.info_outline, size: Responsive.width(4.5, context)),
            label: Text(
              'Detalhes',
              style: GoogleFonts.poppins(
                fontSize: Responsive.width(3.5, context),
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary, width: 1.5),
              padding: EdgeInsets.symmetric(
                vertical: Responsive.height(1.5, context),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
