import 'package:clipboard/clipboard.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/model/complete_order_controller.dart';
import 'package:driver/model/tax_model.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/responsive.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:driver/widget/location_view.dart';
import 'package:driver/widget/user_order_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CompleteOrderScreen extends StatelessWidget {
  const CompleteOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return GetX<CompleteOrderController>(
      init: CompleteOrderController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: AppColors.primary,
          appBar: _buildAppBar(context, themeChange),
          body: Column(
            children: [
              SizedBox(height: Responsive.height(4, context)),
              Expanded(
                child: controller.isLoading.value
                    ? Constant.loader(context)
                    : _buildMainContent(context, controller, themeChange),
              ),
            ],
          ),
        );
      },
    );
  }

  /// AppBar responsiva e temática
  PreferredSizeWidget _buildAppBar(BuildContext context, DarkThemeProvider themeChange) {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      title: Text(
        "Ride Details".tr,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: Responsive.width(4.5, context),
          fontWeight: FontWeight.w600,
        ),
      ),
      leading: InkWell(
        onTap: () => Get.back(),
        borderRadius: BorderRadius.circular(25),
        child: Container(
          margin: EdgeInsets.all(Responsive.width(2, context)),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: Responsive.width(5, context),
          ),
        ),
      ),
      centerTitle: true,
    );
  }

  /// Conteúdo principal com container responsivo
  Widget _buildMainContent(BuildContext context, CompleteOrderController controller, DarkThemeProvider themeChange) {
    return Container(
      decoration: BoxDecoration(
        color: themeChange.getThem() ? AppColors.darkBackground : AppColors.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(Responsive.width(5, context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com indicador visual
            _buildScreenHeader(context, themeChange),

            SizedBox(height: Responsive.height(2, context)),

            // Ride ID Card
            _buildRideIdCard(context, controller, themeChange),

            SizedBox(height: Responsive.height(2.5, context)),

            // Informações do usuário
            UserDriverView(
              userId: controller.orderModel.value.userId.toString(),
              amount: controller.orderModel.value.finalRate.toString(),
            ),

            _buildDivider(context, themeChange),

            // Seção de localizações
            _buildLocationsSection(context, controller, themeChange),

            SizedBox(height: Responsive.height(2, context)),

            // Status da corrida
            _buildRideStatus(context, controller, themeChange),

            SizedBox(height: Responsive.height(2, context)),

            // Resumo da reserva
            _buildBookingSummary(context, controller, themeChange),

            SizedBox(height: Responsive.height(2, context)),

            // Comissão do admin
            _buildAdminCommission(context, controller, themeChange),

            SizedBox(height: Responsive.height(3, context)),
          ],
        ),
      ),
    );
  }

  /// Header da tela com indicador visual
  Widget _buildScreenHeader(BuildContext context, DarkThemeProvider themeChange) {
    return Column(
      children: [
        // Indicador de arraste
        Container(
          width: Responsive.width(12, context),
          height: Responsive.height(0.6, context),
          decoration: BoxDecoration(
            color: themeChange.getThem() ? Colors.white24 : Colors.black26,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        SizedBox(height: Responsive.height(2, context)),

        // Título da seção
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(Responsive.width(2, context)),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.receipt_long,
                color: AppColors.primary,
                size: Responsive.width(6, context),
              ),
            ),
            SizedBox(width: Responsive.width(3, context)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detalhes da Corrida'.tr,
                    style: GoogleFonts.poppins(
                      fontSize: Responsive.width(5, context),
                      fontWeight: FontWeight.bold,
                      color: themeChange.getThem() ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    'Informações completas do pedido'.tr,
                    style: GoogleFonts.poppins(
                      fontSize: Responsive.width(3.2, context),
                      color: themeChange.getThem() ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Card do Ride ID com funcionalidade de cópia
  Widget _buildRideIdCard(BuildContext context, CompleteOrderController controller, DarkThemeProvider themeChange) {
    return Container(
      decoration: BoxDecoration(
        color: themeChange.getThem() ? AppColors.darkContainerBackground : AppColors.containerBackground,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: themeChange.getThem() ? AppColors.darkContainerBorder : AppColors.containerBorder,
          width: 1,
        ),
        boxShadow: _buildCardShadow(themeChange),
      ),
      child: Padding(
        padding: EdgeInsets.all(Responsive.width(4, context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.confirmation_number_outlined,
                  color: AppColors.primary,
                  size: Responsive.width(5.5, context),
                ),
                SizedBox(width: Responsive.width(2, context)),
                Expanded(
                  child: Text(
                    "Ride ID".tr,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: Responsive.width(4, context),
                      color: themeChange.getThem() ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                _buildCopyButton(context, controller, themeChange),
              ],
            ),
            SizedBox(height: Responsive.height(1.5, context)),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.width(3, context),
                vertical: Responsive.height(1, context),
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "#${controller.orderModel.value.id!.toUpperCase()}",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        fontSize: Responsive.width(3.5, context),
                        color: AppColors.primary,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.verified_outlined,
                    color: AppColors.primary,
                    size: Responsive.width(4, context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Botão de cópia com design moderno
  Widget _buildCopyButton(BuildContext context, CompleteOrderController controller, DarkThemeProvider themeChange) {
    return InkWell(
      onTap: () {
        FlutterClipboard.copy(controller.orderModel.value.id.toString()).then((value) {
          ShowToastDialog.showToast("OrderId copied".tr);
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.width(3, context),
          vertical: Responsive.height(0.8, context),
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: themeChange.getThem() ? AppColors.darkModePrimary : AppColors.primary,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.content_copy,
              color: themeChange.getThem() ? AppColors.darkModePrimary : AppColors.primary,
              size: Responsive.width(4, context),
            ),
            SizedBox(width: Responsive.width(1.5, context)),
            Text(
              "Copy".tr,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: Responsive.width(3.2, context),
                color: themeChange.getThem() ? AppColors.darkModePrimary : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Seção de localizações
  Widget _buildLocationsSection(BuildContext context, CompleteOrderController controller, DarkThemeProvider themeChange) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.location_on,
              color: AppColors.primary,
              size: Responsive.width(5.5, context),
            ),
            SizedBox(width: Responsive.width(2, context)),
            Text(
              "Pickup and drop-off locations".tr,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: Responsive.width(4, context),
                color: themeChange.getThem() ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        SizedBox(height: Responsive.height(1.5, context)),
        Container(
          decoration: BoxDecoration(
            color: themeChange.getThem() ? AppColors.darkContainerBackground : AppColors.containerBackground,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: themeChange.getThem() ? AppColors.darkContainerBorder : AppColors.containerBorder,
              width: 1,
            ),
            boxShadow: _buildCardShadow(themeChange),
          ),
          child: Padding(
            padding: EdgeInsets.all(Responsive.width(4, context)),
            child: LocationView(
              sourceLocation: controller.orderModel.value.sourceLocationName.toString(),
              destinationLocation: controller.orderModel.value.destinationLocationName.toString(),
            ),
          ),
        ),
      ],
    );
  }

  /// Status da corrida
  Widget _buildRideStatus(BuildContext context, CompleteOrderController controller, DarkThemeProvider themeChange) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.width(4, context),
        vertical: Responsive.height(2, context),
      ),
      decoration: BoxDecoration(
        color: themeChange.getThem() ? AppColors.darkGray : AppColors.gray,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(Responsive.width(2, context)),
            decoration: BoxDecoration(
              color: _getStatusColor(controller.orderModel.value.status.toString()),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getStatusIcon(controller.orderModel.value.status.toString()),
              color: Colors.white,
              size: Responsive.width(4.5, context),
            ),
          ),
          SizedBox(width: Responsive.width(3, context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.orderModel.value.status.toString(),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: Responsive.width(3.8, context),
                    color: themeChange.getThem() ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  Constant().formatTimestamp(controller.orderModel.value.createdDate),
                  style: GoogleFonts.poppins(
                    fontSize: Responsive.width(3.2, context),
                    color: themeChange.getThem() ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Resumo da reserva
  Widget _buildBookingSummary(BuildContext context, CompleteOrderController controller, DarkThemeProvider themeChange) {
    return Container(
      decoration: BoxDecoration(
        color: themeChange.getThem() ? AppColors.darkContainerBackground : AppColors.containerBackground,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: themeChange.getThem() ? AppColors.darkContainerBorder : AppColors.containerBorder,
          width: 1,
        ),
        boxShadow: _buildCardShadow(themeChange),
      ),
      child: Padding(
        padding: EdgeInsets.all(Responsive.width(4, context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt,
                  color: AppColors.primary,
                  size: Responsive.width(5.5, context),
                ),
                SizedBox(width: Responsive.width(2, context)),
                Text(
                  "Booking summary".tr,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: Responsive.width(4, context),
                    color: themeChange.getThem() ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            SizedBox(height: Responsive.height(1, context)),
            _buildDivider(context, themeChange),

            // Valor da corrida
            _buildSummaryRow(
              context,
              "Ride Amount".tr,
              Constant.amountShow(amount: controller.orderModel.value.finalRate.toString()),
              themeChange,
            ),

            _buildDivider(context, themeChange),

            // Lista de taxas
            if (controller.orderModel.value.taxList != null) ...[
              ...controller.orderModel.value.taxList!.map((taxModel) => Column(
                children: [
                  _buildSummaryRow(
                    context,
                    "${taxModel.title.toString()} (${taxModel.type == "fix" ? Constant.amountShow(amount: taxModel.tax) : "${taxModel.tax}%"})",
                    Constant.amountShow(
                      amount: Constant()
                          .calculateTax(
                        amount: (double.parse(controller.orderModel.value.finalRate.toString()) -
                            double.parse(controller.couponAmount.value.toString()))
                            .toString(),
                        taxModel: taxModel,
                      )
                          .toString(),
                    ),
                    themeChange,
                  ),
                  _buildDivider(context, themeChange),
                ],
              )).toList(),
            ],

            // Desconto
            _buildSummaryRow(
              context,
              "Discount".tr,
              "(-${controller.couponAmount.value == "0.0" ? Constant.amountShow(amount: "0.0") : Constant.amountShow(amount: controller.couponAmount.value)})",
              themeChange,
              valueColor: Colors.red,
            ),

            _buildDivider(context, themeChange),

            // Total a pagar
            Container(
              padding: EdgeInsets.symmetric(vertical: Responsive.height(1, context)),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _buildSummaryRow(
                context,
                "Payable amount".tr,
                Constant.amountShow(amount: controller.calculateAmount().toString()),
                themeChange,
                isBold: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Comissão do administrador
  Widget _buildAdminCommission(BuildContext context, CompleteOrderController controller, DarkThemeProvider themeChange) {
    return Container(
      decoration: BoxDecoration(
        color: themeChange.getThem() ? AppColors.darkContainerBackground : AppColors.containerBackground,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: themeChange.getThem() ? AppColors.darkContainerBorder : AppColors.containerBorder,
          width: 1,
        ),
        boxShadow: _buildCardShadow(themeChange),
      ),
      child: Padding(
        padding: EdgeInsets.all(Responsive.width(4, context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  color: Colors.orange,
                  size: Responsive.width(5.5, context),
                ),
                SizedBox(width: Responsive.width(2, context)),
                Text(
                  "Admin Commission".tr,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: Responsive.width(4, context),
                    color: themeChange.getThem() ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            SizedBox(height: Responsive.height(1.5, context)),

            _buildSummaryRow(
              context,
              "Admin commission".tr,
              "(-${Constant.amountShow(amount: Constant.calculateAdminCommission(amount: (double.parse(controller.orderModel.value.finalRate.toString()) - double.parse(controller.couponAmount.value.toString())).toString(), adminCommission: controller.orderModel.value.adminCommission).toString())})",
              themeChange,
              valueColor: Colors.red,
            ),

            SizedBox(height: Responsive.height(2, context)),

            Container(
              padding: EdgeInsets.all(Responsive.width(3, context)),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.red,
                    size: Responsive.width(5, context),
                  ),
                  SizedBox(width: Responsive.width(2, context)),
                  Expanded(
                    child: Text(
                      "Note : Admin commission will be debited from your wallet balance. \n Admin commission will apply on Ride Amount minus Discount(if applicable).".tr,
                      style: GoogleFonts.poppins(
                        color: Colors.red,
                        fontSize: Responsive.width(3, context),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget para linha do resumo
  Widget _buildSummaryRow(
      BuildContext context,
      String title,
      String value,
      DarkThemeProvider themeChange, {
        Color? valueColor,
        bool isBold = false,
      }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: Responsive.height(0.8, context)),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                color: isBold
                    ? (themeChange.getThem() ? Colors.white : Colors.black)
                    : AppColors.subTitleColor,
                fontSize: Responsive.width(3.5, context),
                fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: Responsive.width(3.5, context),
              color: valueColor ?? (themeChange.getThem() ? Colors.white : Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  /// Divisor responsivo
  Widget _buildDivider(BuildContext context, DarkThemeProvider themeChange) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: Responsive.height(1, context)),
      child: Divider(
        thickness: 1,
        color: themeChange.getThem() ? Colors.white24 : Colors.black12,
      ),
    );
  }

  /// Sombras dos cards
  List<BoxShadow> _buildCardShadow(DarkThemeProvider themeChange) {
    return themeChange.getThem()
        ? [
      BoxShadow(
        color: Colors.black.withOpacity(0.3),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ]
        : [
      BoxShadow(
        color: Colors.grey.withOpacity(0.2),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ];
  }

  /// Cor do status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'complete':
        return Colors.green;
      case 'active':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Ícone do status
  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'complete':
        return Icons.check_circle;
      case 'active':
        return Icons.directions_car;
      case 'pending':
        return Icons.schedule;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }
}