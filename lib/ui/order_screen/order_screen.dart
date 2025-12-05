import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/constant/collection_name.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/send_notification.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/controller/order_controller.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/model/order_model.dart';
import 'package:driver/model/user_model.dart';
import 'package:driver/model/wallet_transaction_model.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/button_them.dart';
import 'package:driver/themes/responsive.dart';
import 'package:driver/ui/chat_screen/chat_screen.dart';
import 'package:driver/ui/order_screen/complete_order_screen.dart';
import 'package:driver/ui/review/review_screen.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:driver/widget/location_view.dart';
import 'package:driver/widget/user_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class OrderScreen extends StatelessWidget {
  const OrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return GetX<OrderController>(
      init: OrderController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: themeChange.getThem()
              ? AppColors.darkBackground
              : AppColors.background,
          appBar: _buildAppBar(context, themeChange),
          body: controller.isLoading.value
              ? Constant.loader(context)
              : _buildOrderList(context, themeChange),
        );
      },
    );
  }

  /// AppBar responsiva com design consistente
  PreferredSizeWidget _buildAppBar(
      BuildContext context, DarkThemeProvider themeChange) {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      title: Text(
        'Minhas Corridas'.tr,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: Responsive.width(4.5, context),
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      automaticallyImplyLeading: false,
    );
  }

  /// Lista de pedidos com StreamBuilder
  Widget _buildOrderList(BuildContext context, DarkThemeProvider themeChange) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(CollectionName.orders)
          .where('driverId', isEqualTo: FireStoreUtils.getCurrentUid())
          .orderBy("createdDate", descending: true)
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

        return _buildOrderCards(context, snapshot, themeChange);
      },
    );
  }

  /// Estado de erro
  Widget _buildErrorState(BuildContext context, DarkThemeProvider themeChange) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: Responsive.width(15, context),
            color: themeChange.getThem() ? Colors.white54 : Colors.black54,
          ),
          SizedBox(height: Responsive.height(2, context)),
          Text(
            'Something went wrong'.tr,
            style: GoogleFonts.poppins(
              fontSize: Responsive.width(4, context),
              color: themeChange.getThem() ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  /// Estado vazio
  Widget _buildEmptyState(BuildContext context, DarkThemeProvider themeChange) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.drive_eta_outlined,
            size: Responsive.width(20, context),
            color: themeChange.getThem() ? Colors.white54 : Colors.black54,
          ),
          SizedBox(height: Responsive.height(2, context)),
          Text(
            "No Ride found".tr,
            style: GoogleFonts.poppins(
              fontSize: Responsive.width(4.5, context),
              fontWeight: FontWeight.w500,
              color: themeChange.getThem() ? Colors.white : Colors.black,
            ),
          ),
          SizedBox(height: Responsive.height(1, context)),
          Text(
            'Suas corridas aparecerão aqui'.tr,
            style: GoogleFonts.poppins(
              fontSize: Responsive.width(3.5, context),
              color: themeChange.getThem() ? Colors.white54 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  /// Lista de cards de pedidos
  Widget _buildOrderCards(BuildContext context,
      AsyncSnapshot<QuerySnapshot> snapshot, DarkThemeProvider themeChange) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        // Implementar refresh se necessário
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(Responsive.width(3, context)),
        itemCount: snapshot.data!.docs.length,
        itemBuilder: (context, index) {
          OrderModel orderModel = OrderModel.fromJson(
              snapshot.data!.docs[index].data() as Map<String, dynamic>);
          return _buildOrderCard(context, orderModel, themeChange);
        },
      ),
    );
  }

  /// Card individual do pedido
  Widget _buildOrderCard(BuildContext context, OrderModel orderModel,
      DarkThemeProvider themeChange) {
    return Padding(
      padding: EdgeInsets.only(bottom: Responsive.height(2, context)),
      child: InkWell(
        onTap: () {
          Get.to(const CompleteOrderScreen(), arguments: {
            "orderModel": orderModel,
          });
        },
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: BoxDecoration(
            color: themeChange.getThem()
                ? AppColors.darkContainerBackground
                : AppColors.containerBackground,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: themeChange.getThem()
                  ? AppColors.darkContainerBorder
                  : AppColors.containerBorder,
              width: 1,
            ),
            boxShadow: themeChange.getThem()
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Padding(
            padding: EdgeInsets.all(Responsive.width(4, context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informações do usuário
                UserView(
                  userId: orderModel.userId,
                  amount: orderModel.finalRate,
                  distance: orderModel.distance,
                  distanceType: orderModel.distanceType,
                ),

                SizedBox(height: Responsive.height(1.5, context)),

                // Informações de localização
                LocationView(
                  sourceLocation: orderModel.sourceLocationName.toString(),
                  destinationLocation:
                      orderModel.destinationLocationName.toString(),
                ),

                SizedBox(height: Responsive.height(1.5, context)),

                // Status do pedido
                _buildStatusContainer(context, orderModel, themeChange),

                SizedBox(height: Responsive.height(1.5, context)),

                // Botões de ação
                _buildActionButtons(context, orderModel, themeChange),

                SizedBox(height: Responsive.height(1, context)),

                // Botão de pagamento
                _buildPaymentButton(context, orderModel, themeChange),

                // Botão de confirmar pagamento em dinheiro (se necessário)
                if (orderModel.paymentStatus == false) ...[
                  SizedBox(height: Responsive.height(1, context)),
                  _buildCashPaymentButton(context, orderModel, themeChange),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Container de status responsivo
  Widget _buildStatusContainer(BuildContext context, OrderModel orderModel,
      DarkThemeProvider themeChange) {
    final isCompleteOrActive = orderModel.status == Constant.rideComplete ||
        orderModel.status == Constant.rideActive;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.width(3, context),
        vertical: Responsive.height(1.5, context),
      ),
      decoration: BoxDecoration(
        color: themeChange.getThem() ? AppColors.darkGray : AppColors.gray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: isCompleteOrActive
          ? Row(
              children: [
                Expanded(
                  child: Text(
                    orderModel.status.toString(),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: Responsive.width(3.5, context),
                      color:
                          themeChange.getThem() ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Text(
                  Constant().formatTimestamp(orderModel.createdDate),
                  style: GoogleFonts.poppins(
                    fontSize: Responsive.width(3, context),
                    color:
                        themeChange.getThem() ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.access_time_outlined,
                  size: Responsive.width(4, context),
                  color: themeChange.getThem() ? Colors.white : Colors.black87,
                ),
                SizedBox(width: Responsive.width(2, context)),
                Text(
                  Constant().formatTimestamp(orderModel.createdDate),
                  style: GoogleFonts.poppins(
                    fontSize: Responsive.width(3.5, context),
                    color:
                        themeChange.getThem() ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
    );
  }

  /// Botões de ação (Review, Chat, Telefone)
  Widget _buildActionButtons(BuildContext context, OrderModel orderModel,
      DarkThemeProvider themeChange) {
    return Row(
      children: [
        // Botão Review
        Expanded(
          child: ButtonThem.buildBorderButton(
            context,
            title: "Review".tr,
            btnHeight: Responsive.height(5.5, context),
            txtSize: Responsive.width(3.5, context),
            iconVisibility: false,
            onPress: () async {
              Get.to(const ReviewScreen(), arguments: {
                "type": "orderModel",
                "orderModel": orderModel,
              });
            },
          ),
        ),

        SizedBox(width: Responsive.width(3, context)),

        // Botões de Chat e Telefone (se a corrida não estiver completa)
        if (orderModel.status != Constant.rideComplete) ...[
          _buildActionIconButton(
            context,
            icon: Icons.chat,
            themeChange: themeChange,
            onTap: () async {
              UserModel? customer = await FireStoreUtils.getCustomer(
                  orderModel.userId.toString());
              DriverUserModel? driver = await FireStoreUtils.getDriverProfile(
                  orderModel.driverId.toString());

              Get.to(ChatScreens(
                driverId: driver!.id,
                customerId: customer!.id,
                customerName: customer.fullName,
                customerProfileImage: customer.profilePic,
                driverName: driver.fullName,
                driverProfileImage: driver.profilePic,
                orderId: orderModel.id,
                token: customer.fcmToken,
              ));
            },
          ),
          SizedBox(width: Responsive.width(2, context)),
          _buildActionIconButton(
            context,
            icon: Icons.call,
            themeChange: themeChange,
            onTap: () async {
              UserModel? customer = await FireStoreUtils.getCustomer(
                  orderModel.userId.toString());
              Constant.makePhoneCall(
                  "${customer!.countryCode}${customer.phoneNumber}");
            },
          ),
        ],
      ],
    );
  }

  /// Botão de ação com ícone
  Widget _buildActionIconButton(
    BuildContext context, {
    required IconData icon,
    required DarkThemeProvider themeChange,
    required VoidCallback onTap,
  }) {
    final buttonSize = Responsive.height(5.5, context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: buttonSize,
        width: buttonSize,
        decoration: BoxDecoration(
          color: themeChange.getThem()
              ? AppColors.darkModePrimary
              : AppColors.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: themeChange.getThem() ? Colors.black : Colors.white,
          size: Responsive.width(5, context),
        ),
      ),
    );
  }

  /// Botão de status de pagamento
  Widget _buildPaymentButton(BuildContext context, OrderModel orderModel,
      DarkThemeProvider themeChange) {
    return ButtonThem.buildButton(
      context,
      title: orderModel.paymentStatus == true
          ? "Payment completed".tr
          : "Payment Pending".tr,
      btnHeight: Responsive.height(5.5, context),
      txtSize: Responsive.width(3.5, context),
      onPress: () async {},
    );
  }

  /// Botão para confirmar pagamento em dinheiro
  Widget _buildCashPaymentButton(BuildContext context, OrderModel orderModel,
      DarkThemeProvider themeChange) {
    return ButtonThem.buildButton(
      context,
      title: "Conform cash payment".tr,
      btnHeight: Responsive.height(5.5, context),
      txtSize: Responsive.width(3.5, context),
      onPress: () async {
        await _handleCashPaymentConfirmation(orderModel);
      },
    );
  }

  /// Manipula a confirmação do pagamento em dinheiro
  Future<void> _handleCashPaymentConfirmation(OrderModel orderModel) async {
    ShowToastDialog.showLoader("Please wait..".tr);

    try {
      orderModel.paymentStatus = true;
      orderModel.status = Constant.rideComplete;
      orderModel.updateDate = Timestamp.now();

      String? couponAmount = "0.0";
      if (orderModel.coupon != null && orderModel.coupon?.code != null) {
        if (orderModel.coupon!.type == "fix") {
          couponAmount = orderModel.coupon!.amount.toString();
        } else {
          couponAmount = ((double.parse(orderModel.finalRate.toString()) *
                      double.parse(orderModel.coupon!.amount.toString())) /
                  100)
              .toString();
        }
      }

      // CÁLCULO CORRETO: Valor que o motorista recebe
      double finalRateDouble = double.parse(orderModel.finalRate.toString());
      double couponAmountDouble = double.parse(couponAmount.toString());
      double rideValue = finalRateDouble - couponAmountDouble;

      // Calcular comissão do admin
      double adminCommissionAmount = Constant.calculateAdminCommission(
        amount: rideValue.toString(),
        adminCommission: orderModel.adminCommission
      );

      // Valor líquido que o motorista recebe (valor da corrida - comissão)
      double driverNetAmount = rideValue - adminCommissionAmount;

      // 1. ADICIONAR valor da corrida à carteira do motorista
      WalletTransactionModel driverEarningTransaction = WalletTransactionModel(
        id: Constant.getUuid(),
        amount: rideValue.toString(), // Valor total da corrida
        createdDate: Timestamp.now(),
        paymentType: "cash".tr,
        transactionId: orderModel.id,
        orderType: "city",
        userType: "driver",
        userId: orderModel.driverId.toString(),
        note: "Ganho da corrida #${orderModel.id}".tr,
      );

      await FireStoreUtils.setWalletTransaction(driverEarningTransaction)
          .then((value) async {
        if (value == true) {
          // Adiciona valor da corrida à carteira
          await FireStoreUtils.updatedDriverWallet(amount: rideValue.toString());
        }
      });

      // 2. SUBTRAIR comissão do admin
      WalletTransactionModel adminCommissionWallet = WalletTransactionModel(
        id: Constant.getUuid(),
        amount: "-$adminCommissionAmount",
        createdDate: Timestamp.now(),
        paymentType: "wallet".tr,
        transactionId: orderModel.id,
        orderType: "city",
        userType: "driver",
        userId: orderModel.driverId.toString(),
        note: "Comissão B21 (${ orderModel.adminCommission?.type == "fix" ? "R\$ ${orderModel.adminCommission?.amount}" : "${orderModel.adminCommission?.amount}%" })".tr,
      );

      await FireStoreUtils.setWalletTransaction(adminCommissionWallet)
          .then((value) async {
        if (value == true) {
          // Subtrai comissão da carteira
          await FireStoreUtils.updatedDriverWallet(amount: "-$adminCommissionAmount");
        }
      });

      // Enviar notificação para o cliente
      await FireStoreUtils.getCustomer(orderModel.userId.toString())
          .then((value) async {
        if (value != null) {
          await SendNotification.sendOneNotification(
            token: value.fcmToken.toString(),
            title: 'Cash Payment conformed'.tr,
            body: 'Driver has conformed your cash payment'.tr,
            payload: {},
          );
        }
      });

      // Atualizar valor de referência
      await FireStoreUtils.getFirestOrderOrNOt(orderModel).then((value) async {
        if (value == true) {
          await FireStoreUtils.updateReferralAmount(orderModel);
        }
      });

      // Salvar pedido atualizado
      await FireStoreUtils.setOrder(orderModel).then((value) {
        if (value == true) {
          ShowToastDialog.closeLoader();
          ShowToastDialog.showToast("Payment Conform successfully".tr);
        }
      });
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Error confirming payment".tr);
    }
  }
}
