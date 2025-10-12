// lib/ui/home_screens/active_order_screen.dart - Versão corrigida e otimizada
import 'package:cached_network_image/cached_network_image.dart';
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
import 'package:driver/themes/responsive.dart';
import 'package:driver/ui/chat_screen/chat_screen.dart';
import 'package:driver/ui/home_screens/live_tracking_screen.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:driver/utils/utils.dart';
import 'package:driver/widget/rating_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dash/flutter_dash.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
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
              .where('status', whereIn: [Constant.rideInProgress, Constant.rideActive])
              .snapshots(),
          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              return _buildErrorState(context, themeChange);
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Constant.loader(context);
            }

            if (snapshot.data!.docs.isEmpty) {
              return _buildEmptyState(context, themeChange);
            }

            return _buildOrdersList(context, snapshot, controller, themeChange);
          },
        );
      },
    );
  }

  Widget _buildErrorState(BuildContext context, DarkThemeProvider themeChange) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: Responsive.width(20, context),
            color: Colors.red,
          ),
          SizedBox(height: Responsive.height(2, context)),
          Text(
            'Something went wrong'.tr,
            style: GoogleFonts.poppins(
              fontSize: Responsive.width(4.5, context),
              fontWeight: FontWeight.w600,
              color: themeChange.getThem() ? Colors.white : Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, DarkThemeProvider themeChange) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.drive_eta_outlined,
            size: Responsive.width(25, context),
            color: themeChange.getThem() ? Colors.white54 : Colors.black54,
          ),
          SizedBox(height: Responsive.height(2, context)),
          Text(
            "No active rides Found".tr,
            style: GoogleFonts.poppins(
              fontSize: Responsive.width(5, context),
              fontWeight: FontWeight.w600,
              color: themeChange.getThem() ? Colors.white : Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot,
      ActiveOrderController controller, DarkThemeProvider themeChange) {
    return ListView.builder(
      padding: EdgeInsets.all(Responsive.width(4, context)),
      itemCount: snapshot.data!.docs.length,
      itemBuilder: (context, index) {
        OrderModel orderModel = OrderModel.fromJson(
            snapshot.data!.docs[index].data() as Map<String, dynamic>
        );

        return _buildOrderCard(context, orderModel, controller, themeChange);
      },
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel orderModel,
      ActiveOrderController controller, DarkThemeProvider themeChange) {
    return Container(
      margin: EdgeInsets.only(bottom: Responsive.height(2, context)),
      decoration: BoxDecoration(
        color: themeChange.getThem()
            ? AppColors.darkContainerBackground
            : AppColors.containerBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeChange.getThem()
              ? AppColors.darkContainerBorder
              : AppColors.containerBorder,
          width: 1,
        ),
        boxShadow: themeChange.getThem()
            ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ]
            : [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToTracking(orderModel, context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(Responsive.width(4, context)),
            child: Column(
              children: [
                // Linha 1: Passageiro e Valor
                Row(
                  children: [
                    // Avatar
                    _buildAvatar(context, orderModel, themeChange),

                    SizedBox(width: Responsive.width(3, context)),

                    // Nome do passageiro
                    Expanded(
                      child: _buildPassengerName(context, orderModel, themeChange),
                    ),

                    // Valor
                    _buildPrice(context, orderModel, themeChange),
                  ],
                ),

                SizedBox(height: Responsive.height(2, context)),

                // Linha 2: Origem e Destino (simplificado)
                _buildSimpleRoute(context, orderModel, themeChange),

                SizedBox(height: Responsive.height(2.5, context)),

                // Linha 3: Botões de ação
                _buildActionButtons(context, orderModel, controller, themeChange),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, OrderModel orderModel, DarkThemeProvider themeChange) {
    return FutureBuilder<UserModel?>(
      future: FireStoreUtils.getCustomer(orderModel.userId.toString()),
      builder: (context, snapshot) {
        UserModel? user = snapshot.data;

        return Container(
          width: Responsive.width(12, context),
          height: Responsive.width(12, context),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: themeChange.getThem() ? AppColors.darkModePrimary : AppColors.primary,
          ),
          child: user?.profilePic != null && user!.profilePic!.isNotEmpty
              ? ClipRRect(
            borderRadius: BorderRadius.circular(Responsive.width(6, context)),
            child: CachedNetworkImage(
              imageUrl: user.profilePic!,
              fit: BoxFit.cover,
              placeholder: (context, url) => Icon(
                Icons.person,
                color: Colors.white,
                size: Responsive.width(7, context),
              ),
              errorWidget: (context, url, error) => Icon(
                Icons.person,
                color: Colors.white,
                size: Responsive.width(7, context),
              ),
            ),
          )
              : Icon(
            Icons.person,
            color: Colors.white,
            size: Responsive.width(7, context),
          ),
        );
      },
    );
  }

  Widget _buildPassengerName(BuildContext context, OrderModel orderModel, DarkThemeProvider themeChange) {
    return FutureBuilder<UserModel?>(
      future: FireStoreUtils.getCustomer(orderModel.userId.toString()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: Responsive.height(3, context),
            width: Responsive.width(30, context),
            decoration: BoxDecoration(
              color: themeChange.getThem() ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }

        UserModel? user = snapshot.data;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user?.fullName ?? 'Passageiro',
              style: GoogleFonts.poppins(
                fontSize: Responsive.width(4.2, context),
                fontWeight: FontWeight.w600,
                color: themeChange.getThem() ? Colors.white : Colors.black,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              orderModel.status == Constant.rideInProgress ? 'Em andamento' : 'Aguardando',
              style: GoogleFonts.poppins(
                fontSize: Responsive.width(3.2, context),
                color: orderModel.status == Constant.rideInProgress
                    ? Colors.orange
                    : Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPrice(BuildContext context, OrderModel orderModel, DarkThemeProvider themeChange) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _formatAmount(orderModel.finalRate),
          style: GoogleFonts.poppins(
            fontSize: Responsive.width(4.5, context),
            fontWeight: FontWeight.w700,
            color: Colors.green,
          ),
        ),
        Text(
          _formatDistance(orderModel.distance, orderModel.distanceType),
          style: GoogleFonts.poppins(
            fontSize: Responsive.width(3, context),
            color: themeChange.getThem() ? Colors.white70 : Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleRoute(BuildContext context, OrderModel orderModel, DarkThemeProvider themeChange) {
    return Row(
      children: [
        // Ícones da rota
        Column(
          children: [
            Icon(
              Icons.circle,
              color: themeChange.getThem() ? AppColors.darkModePrimary : AppColors.primary,
              size: Responsive.width(3, context),
            ),
            Container(
              margin: EdgeInsets.symmetric(vertical: Responsive.height(0.3, context)),
              child: Dash(
                direction: Axis.vertical,
                length: Responsive.height(4, context),
                dashLength: 3,
                dashGap: 1,
                dashColor: themeChange.getThem() ? Colors.white54 : Colors.black26,
                dashThickness: 1.5,
              ),
            ),
            Icon(
              Icons.circle,
              color: Colors.red,
              size: Responsive.width(3, context),
            ),
          ],
        ),

        SizedBox(width: Responsive.width(3, context)),

        // Endereços
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                orderModel.sourceLocationName?.toString() ?? 'Origem não informada',
                style: GoogleFonts.poppins(
                  fontSize: Responsive.width(3.5, context),
                  color: themeChange.getThem() ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              SizedBox(height: Responsive.height(1.5, context)),

              Text(
                orderModel.destinationLocationName?.toString() ?? 'Destino não informado',
                style: GoogleFonts.poppins(
                  fontSize: Responsive.width(3.5, context),
                  color: themeChange.getThem() ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, OrderModel orderModel,
      ActiveOrderController controller, DarkThemeProvider themeChange) {
    return Row(
      children: [
        // Botão principal
        Expanded(
          child: Container(
            height: Responsive.height(6, context),
            decoration: BoxDecoration(
              color: themeChange.getThem() ? AppColors.darkModePrimary : AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (orderModel.status == Constant.rideInProgress) {
                    _showRatingDialog(context, orderModel, controller, themeChange);
                  } else {
                    _pickupCustomer(orderModel);
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Center(
                  child: Text(
                    orderModel.status == Constant.rideInProgress
                        ? "Finalizar Corrida"
                        : "Buscar Passageiro",
                    style: GoogleFonts.poppins(
                      fontSize: Responsive.width(3.8, context),
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Botões Chat e Call apenas para corridas ativas
        if (orderModel.status == Constant.rideActive) ...[
          SizedBox(width: Responsive.width(3, context)),

          // Botão Chat
          Container(
            width: Responsive.width(12, context),
            height: Responsive.height(6, context),
            decoration: BoxDecoration(
              border: Border.all(
                color: themeChange.getThem() ? AppColors.darkModePrimary : AppColors.primary,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _openChat(orderModel),
                borderRadius: BorderRadius.circular(8),
                child: Icon(
                  Icons.chat,
                  color: themeChange.getThem() ? AppColors.darkModePrimary : AppColors.primary,
                  size: Responsive.width(5, context),
                ),
              ),
            ),
          ),

          SizedBox(width: Responsive.width(2, context)),

          // Botão Call
          Container(
            width: Responsive.width(12, context),
            height: Responsive.height(6, context),
            decoration: BoxDecoration(
              border: Border.all(
                color: themeChange.getThem() ? AppColors.darkModePrimary : AppColors.primary,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _makeCall(orderModel),
                borderRadius: BorderRadius.circular(8),
                child: Icon(
                  Icons.call,
                  color: themeChange.getThem() ? AppColors.darkModePrimary : AppColors.primary,
                  size: Responsive.width(5, context),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Helper methods
  String _formatAmount(String? amount) {
    try {
      if (amount == null || amount.isEmpty || amount == 'null') {
        return "R\$ 0.00";
      }
      double value = double.tryParse(amount) ?? 0.0;
      return Constant.amountShow(amount: value.toString());
    } catch (e) {
      return "R\$ 0.00";
    }
  }

  String _formatDistance(String? distance, String? distanceType) {
    try {
      if (distance == null || distance.isEmpty || distance == 'null') {
        return "0.0 km";
      }
      double value = double.tryParse(distance) ?? 0.0;
      return "${value.toStringAsFixed(1)} ${distanceType ?? 'km'}";
    } catch (e) {
      return "0.0 km";
    }
  }

  void _navigateToTracking(OrderModel orderModel, BuildContext context) {
    // Mostrar sheet com opções de navegação
    _showMapOptionsSheet(context, orderModel);
  }

  void _showMapOptionsSheet(BuildContext context, OrderModel orderModel) {
    final themeChange = Provider.of<DarkThemeProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: themeChange.getThem()
                ? AppColors.darkContainerBackground
                : AppColors.containerBackground,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(Responsive.width(6, context)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Indicador de arraste
                Container(
                  width: Responsive.width(12, context),
                  height: 4,
                  decoration: BoxDecoration(
                    color: themeChange.getThem() ? Colors.white24 : Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                SizedBox(height: Responsive.height(3, context)),

                // Título
                Text(
                  'Escolha o mapa para navegação',
                  style: GoogleFonts.poppins(
                    fontSize: Responsive.width(5, context),
                    fontWeight: FontWeight.w600,
                    color: themeChange.getThem() ? Colors.white : Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: Responsive.height(4, context)),

                // Opção Mapa Local
                _buildMapOption(
                  context,
                  'Google Maps',
                  'Abrir no Google Maps',
                  Icons.map,
                  themeChange.getThem() ? AppColors.darkModePrimary : AppColors.primary,
                      () {
                    Navigator.pop(context);
                    if (orderModel.status == Constant.rideInProgress) {
                      // Se a corrida está em progresso, navegue para o destino
                      Utils.redirectMap(
                        mapType: "google",
                        latitude: orderModel.destinationLocationLAtLng!.latitude!,
                        longLatitude: orderModel.destinationLocationLAtLng!.longitude!,
                        name: orderModel.destinationLocationName.toString(),
                      );
                    } else {
                      // Se a corrida está ativa (aguardando), navegue para a origem
                      Utils.redirectMap(
                        mapType: "google",
                        latitude: orderModel.sourceLocationLAtLng!.latitude!,
                        longLatitude: orderModel.sourceLocationLAtLng!.longitude!,
                        name: orderModel.sourceLocationName.toString(),
                      );
                    }
                  },
                  themeChange,
                ),

                SizedBox(height: Responsive.height(2, context)),

                // Opção Waze
                _buildMapOption(
                  context,
                  'Waze',
                  'Abrir no aplicativo Waze',
                  Icons.navigation,
                  Colors.blue,
                      () {
                    Navigator.pop(context);
                    if (orderModel.status == Constant.rideInProgress) {
                      Utils.redirectMap(
                        mapType: "waze",
                        latitude: orderModel.destinationLocationLAtLng!.latitude!,
                        longLatitude: orderModel.destinationLocationLAtLng!.longitude!,
                        name: orderModel.destinationLocationName.toString(),
                      );
                    } else {
                      Utils.redirectMap(
                        mapType: "waze",
                        latitude: orderModel.sourceLocationLAtLng!.latitude!,
                        longLatitude: orderModel.sourceLocationLAtLng!.longitude!,
                        name: orderModel.sourceLocationName.toString(),
                      );
                    }
                  },
                  themeChange,
                ),

                SizedBox(height: Responsive.height(3, context)),

                // Botão cancelar
                Container(
                  width: double.infinity,
                  height: Responsive.height(6, context),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: themeChange.getThem() ? Colors.white24 : Colors.black26,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Center(
                        child: Text(
                          'Cancelar',
                          style: GoogleFonts.poppins(
                            fontSize: Responsive.width(4, context),
                            fontWeight: FontWeight.w500,
                            color: themeChange.getThem() ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: Responsive.height(2, context)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapOption(BuildContext context, String title, String subtitle,
      IconData icon, Color color, VoidCallback onTap, DarkThemeProvider themeChange) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: themeChange.getThem()
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeChange.getThem()
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(Responsive.width(4, context)),
            child: Row(
              children: [
                Container(
                  width: Responsive.width(12, context),
                  height: Responsive.width(12, context),
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

                SizedBox(width: Responsive.width(4, context)),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: Responsive.width(4.5, context),
                          fontWeight: FontWeight.w600,
                          color: themeChange.getThem() ? Colors.white : Colors.black,
                        ),
                      ),
                      SizedBox(height: Responsive.height(0.5, context)),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: Responsive.width(3.5, context),
                          color: themeChange.getThem() ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),

                Icon(
                  Icons.arrow_forward_ios,
                  color: themeChange.getThem() ? Colors.white54 : Colors.black38,
                  size: Responsive.width(4, context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openChat(OrderModel orderModel) async {
    UserModel? customer = await FireStoreUtils.getCustomer(orderModel.userId.toString());
    Get.to(const ChatScreens(), arguments: {
      "orderId": orderModel.id.toString(),
      "customerId": orderModel.userId.toString(),
      "driverId": FireStoreUtils.getCurrentUid(),
      "customerName": customer?.fullName ?? '',
      "customerProfilePic": customer?.profilePic ?? '',
    });
  }

  void _makeCall(OrderModel orderModel) async {
    UserModel? customer = await FireStoreUtils.getCustomer(orderModel.userId.toString());
    if (customer != null) {
      Constant.makePhoneCall("${customer.countryCode}${customer.phoneNumber}");
    }
  }

  void _showRatingDialog(BuildContext context, OrderModel orderModel,
      ActiveOrderController controller, DarkThemeProvider themeChange) {
    Get.dialog(
      RatingDialog(
        orderModel: orderModel,
        onComplete: () async {
          await _completeRide(orderModel, controller);
        },
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _completeRide(OrderModel orderModel, ActiveOrderController controller) async {
    try {
      orderModel.status = Constant.rideComplete;
      orderModel.paymentStatus = true;

      await FireStoreUtils.getCustomer(orderModel.userId.toString()).then((value) async {
        if (value != null) {
          if (value.fcmToken != null) {
            Map<String, dynamic> playLoad = <String, dynamic>{
              "type": "city_order_complete",
              "orderId": orderModel.id
            };

            await SendNotification.sendOneNotification(
              token: value.fcmToken.toString(),
              title: 'Ride complete!'.tr,
              body: 'Ride Complete successfully.'.tr,
              payload: playLoad,
            );
          }
        }
      });

      await FireStoreUtils.setOrder(orderModel).then((value) {
        if (value == true) {
          ShowToastDialog.showToast("Ride Complete successfully".tr);
          controller.homeController.selectedIndex.value = 1; // Changed from 3 to 1 (Order screen)
        }
      });
    } catch (error) {
      ShowToastDialog.showToast("Erro ao completar corrida: $error");
    }
  }

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
            payload: {},
          );
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