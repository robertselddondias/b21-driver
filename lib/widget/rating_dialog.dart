import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/send_notification.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/model/order_model.dart';
import 'package:driver/model/review_model.dart';
import 'package:driver/model/user_model.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/responsive.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class RatingDialog extends StatefulWidget {
  final OrderModel orderModel;
  final VoidCallback? onComplete;

  const RatingDialog({
    super.key,
    required this.orderModel,
    this.onComplete,
  });

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> with TickerProviderStateMixin {
  double _rating = 5.0;
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false;
  UserModel? _customer;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _loadCustomerData();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomerData() async {
    final customer = await FireStoreUtils.getCustomer(widget.orderModel.userId.toString());
    if (mounted) {
      setState(() {
        _customer = customer;
      });
    }
  }

  /// Finaliza a corrida (tanto para pular quanto para após avaliar)
  Future<void> _completeRide() async {
    try {
      widget.orderModel.status = Constant.rideComplete;
      widget.orderModel.paymentStatus = true;

      await FireStoreUtils.getCustomer(widget.orderModel.userId.toString()).then((value) async {
        if (value != null) {
          if (value.fcmToken != null) {
            Map<String, dynamic> playLoad = <String, dynamic>{
              "type": "city_order_complete",
              "orderId": widget.orderModel.id
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

      await FireStoreUtils.setOrder(widget.orderModel).then((value) {
        if (value == true) {
          ShowToastDialog.showToast("Ride Complete successfully".tr);
          widget.onComplete?.call();
        }
      });
    } catch (error) {
      ShowToastDialog.showToast("Erro ao finalizar corrida: $error");
    }
  }

  /// Pular avaliação
  Future<void> _skipRating() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _completeRide();
      Get.back();
    } catch (error) {
      ShowToastDialog.showToast("Erro ao finalizar corrida: $error");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Submeter avaliação
  Future<void> _submitRating() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      ReviewModel reviewModel = ReviewModel();
      reviewModel.id = widget.orderModel.id;
      reviewModel.customerId = widget.orderModel.userId;
      reviewModel.driverId = FireStoreUtils.getCurrentUid();
      reviewModel.rating = _rating.toString();
      reviewModel.comment = _commentController.text.trim();
      reviewModel.type = "customer";
      reviewModel.date = Timestamp.now();

      bool? reviewSuccess = await FireStoreUtils.setReview(reviewModel);

      if (reviewSuccess == true) {
        if (_customer != null) {
          UserModel updatedCustomer = _customer!;
          double currentSum = double.parse(updatedCustomer.reviewsSum ?? '0.0');
          double currentCount = double.parse(updatedCustomer.reviewsCount ?? '0.0');
          updatedCustomer.reviewsSum = (currentSum + _rating).toString();
          updatedCustomer.reviewsCount = (currentCount + 1).toString();
          await FireStoreUtils.updateUser(updatedCustomer);
        }

        ShowToastDialog.showToast("Review submit successfully".tr);
        await _completeRide();
        Get.back();
      } else {
        throw Exception("Falha ao salvar avaliação");
      }
    } catch (error) {
      ShowToastDialog.showToast("Erro ao enviar avaliação: $error");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Adaptação de tamanhos baseada na largura da tela
    final bool isSmallScreen = screenWidth < 360;
    final bool isLargeScreen = screenWidth > 600;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: AlertDialog(
        backgroundColor: themeChange.getThem()
            ? AppColors.darkContainerBackground
            : AppColors.containerBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
        ),
        contentPadding: EdgeInsets.zero,
        insetPadding: EdgeInsets.symmetric(
          horizontal: isSmallScreen
              ? Responsive.width(4, context)
              : Responsive.width(8, context),
          vertical: isSmallScreen
              ? Responsive.height(2, context)
              : Responsive.height(4, context),
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isLargeScreen ? 500 : screenWidth * 0.92,
            maxHeight: screenHeight * (isSmallScreen ? 0.85 : 0.80),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                _buildHeader(context, themeChange, isSmallScreen, isLargeScreen),

                // Conteúdo
                Padding(
                  padding: EdgeInsets.all(
                    isSmallScreen
                        ? Responsive.width(4, context)
                        : Responsive.width(5, context),
                  ),
                  child: Column(
                    children: [
                      // Info do passageiro
                      _buildCustomerInfo(context, themeChange, isSmallScreen, isLargeScreen),

                      SizedBox(
                        height: isSmallScreen
                            ? Responsive.height(1.5, context)
                            : Responsive.height(2, context),
                      ),

                      // Rating
                      _buildRatingSection(context, themeChange, isSmallScreen, isLargeScreen),

                      SizedBox(
                        height: isSmallScreen
                            ? Responsive.height(2, context)
                            : Responsive.height(2.5, context),
                      ),

                      // Campo de comentário
                      _buildCommentField(context, themeChange, isSmallScreen, isLargeScreen),

                      SizedBox(
                        height: isSmallScreen
                            ? Responsive.height(2, context)
                            : Responsive.height(3, context),
                      ),

                      // Botões
                      _buildActionButtons(context, themeChange, isSmallScreen, isLargeScreen),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context,
      DarkThemeProvider themeChange,
      bool isSmallScreen,
      bool isLargeScreen,
      ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        isSmallScreen
            ? Responsive.width(4, context)
            : Responsive.width(5, context),
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isSmallScreen ? 16 : 20),
          topRight: Radius.circular(isSmallScreen ? 16 : 20),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(
              isSmallScreen
                  ? Responsive.width(2.5, context)
                  : Responsive.width(3, context),
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.star,
              color: AppColors.primary,
              size: isSmallScreen
                  ? Responsive.width(7, context)
                  : (isLargeScreen
                  ? Responsive.width(6, context)
                  : Responsive.width(8, context)),
            ),
          ),
          SizedBox(
            height: isSmallScreen
                ? Responsive.height(0.8, context)
                : Responsive.height(1, context),
          ),
          Text(
            'Avaliar Passageiro',
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen
                  ? Responsive.width(4.5, context)
                  : (isLargeScreen
                  ? Responsive.width(4, context)
                  : Responsive.width(5, context)),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: Responsive.height(0.5, context)),
          Text(
            'Como foi sua experiência?',
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen
                  ? Responsive.width(3, context)
                  : (isLargeScreen
                  ? Responsive.width(2.8, context)
                  : Responsive.width(3.5, context)),
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo(
      BuildContext context,
      DarkThemeProvider themeChange,
      bool isSmallScreen,
      bool isLargeScreen,
      ) {
    final avatarSize = isSmallScreen
        ? Responsive.width(11, context)
        : (isLargeScreen
        ? Responsive.width(10, context)
        : Responsive.width(12, context));

    return Container(
      padding: EdgeInsets.all(
        isSmallScreen
            ? Responsive.width(3, context)
            : Responsive.width(4, context),
      ),
      decoration: BoxDecoration(
        color: themeChange.getThem()
            ? AppColors.darkTextField
            : AppColors.lightGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeChange.getThem()
              ? AppColors.darkTextFieldBorder
              : AppColors.textFieldBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary,
                width: 2,
              ),
            ),
            child: Icon(
              Icons.person,
              color: AppColors.primary,
              size: isSmallScreen
                  ? Responsive.width(5.5, context)
                  : Responsive.width(6, context),
            ),
          ),
          SizedBox(
            width: isSmallScreen
                ? Responsive.width(2.5, context)
                : Responsive.width(3, context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _customer?.fullName ?? 'Passageiro',
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen
                        ? Responsive.width(3.5, context)
                        : (isLargeScreen
                        ? Responsive.width(3.2, context)
                        : Responsive.width(4, context)),
                    fontWeight: FontWeight.w600,
                    color: themeChange.getThem() ? Colors.white : Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: Responsive.height(0.3, context)),
                Text(
                  'ID: ${widget.orderModel.id?.substring(0, 8) ?? ''}...',
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen
                        ? Responsive.width(2.6, context)
                        : (isLargeScreen
                        ? Responsive.width(2.4, context)
                        : Responsive.width(3, context)),
                    color: AppColors.subTitleColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection(
      BuildContext context,
      DarkThemeProvider themeChange,
      bool isSmallScreen,
      bool isLargeScreen,
      ) {
    final starSize = isSmallScreen
        ? Responsive.width(8.5, context)
        : (isLargeScreen
        ? Responsive.width(7, context)
        : Responsive.width(10, context));

    return Column(
      children: [
        Text(
          'Dê sua avaliação',
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen
                ? Responsive.width(3.5, context)
                : (isLargeScreen
                ? Responsive.width(3.2, context)
                : Responsive.width(4, context)),
            fontWeight: FontWeight.w600,
            color: themeChange.getThem() ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(
          height: isSmallScreen
              ? Responsive.height(1.2, context)
              : Responsive.height(1.5, context),
        ),
        RatingBar.builder(
          initialRating: _rating,
          minRating: 1,
          direction: Axis.horizontal,
          allowHalfRating: false,
          itemCount: 5,
          itemSize: starSize,
          itemPadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 2.0 : 4.0,
          ),
          itemBuilder: (context, _) => const Icon(
            Icons.star,
            color: AppColors.ratingColour,
          ),
          onRatingUpdate: (rating) {
            setState(() {
              _rating = rating;
            });
          },
        ),
        SizedBox(
          height: isSmallScreen
              ? Responsive.height(0.8, context)
              : Responsive.height(1, context),
        ),
        Text(
          _getRatingText(_rating),
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen
                ? Responsive.width(3, context)
                : (isLargeScreen
                ? Responsive.width(2.8, context)
                : Responsive.width(3.5, context)),
            color: AppColors.subTitleColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCommentField(
      BuildContext context,
      DarkThemeProvider themeChange,
      bool isSmallScreen,
      bool isLargeScreen,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comentário (opcional)',
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen
                ? Responsive.width(3.5, context)
                : (isLargeScreen
                ? Responsive.width(3.2, context)
                : Responsive.width(4, context)),
            fontWeight: FontWeight.w600,
            color: themeChange.getThem() ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(
          height: isSmallScreen
              ? Responsive.height(0.8, context)
              : Responsive.height(1, context),
        ),
        Container(
          decoration: BoxDecoration(
            color: themeChange.getThem()
                ? AppColors.darkTextField
                : AppColors.textField,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: themeChange.getThem()
                  ? AppColors.darkTextFieldBorder
                  : AppColors.textFieldBorder,
              width: 1,
            ),
          ),
          child: TextField(
            controller: _commentController,
            maxLines: isSmallScreen ? 2 : 3,
            maxLength: 200,
            decoration: InputDecoration(
              hintText: "Como foi sua experiência com o passageiro?",
              hintStyle: GoogleFonts.poppins(
                color: AppColors.subTitleColor,
                fontSize: isSmallScreen
                    ? Responsive.width(3, context)
                    : (isLargeScreen
                    ? Responsive.width(2.8, context)
                    : Responsive.width(3.5, context)),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(
                isSmallScreen
                    ? Responsive.width(3, context)
                    : Responsive.width(4, context),
              ),
              counterStyle: GoogleFonts.poppins(
                fontSize: isSmallScreen
                    ? Responsive.width(2.5, context)
                    : Responsive.width(2.8, context),
                color: AppColors.subTitleColor,
              ),
            ),
            style: GoogleFonts.poppins(
              color: themeChange.getThem() ? Colors.white : Colors.black,
              fontSize: isSmallScreen
                  ? Responsive.width(3.2, context)
                  : (isLargeScreen
                  ? Responsive.width(3, context)
                  : Responsive.width(3.8, context)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
      BuildContext context,
      DarkThemeProvider themeChange,
      bool isSmallScreen,
      bool isLargeScreen,
      ) {
    final buttonHeight = isSmallScreen
        ? Responsive.height(5.5, context)
        : Responsive.height(6, context);

    final fontSize = isSmallScreen
        ? Responsive.width(3.5, context)
        : (isLargeScreen
        ? Responsive.width(3.2, context)
        : Responsive.width(4, context));

    return Row(
      children: [
        // Botão Pular
        Expanded(
          child: Container(
            height: buttonHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.subTitleColor,
                width: 1.5,
              ),
            ),
            child: TextButton(
              onPressed: _isLoading ? null : _skipRating,
              child: _isLoading
                  ? SizedBox(
                width: isSmallScreen
                    ? Responsive.width(3.5, context)
                    : Responsive.width(4, context),
                height: isSmallScreen
                    ? Responsive.width(3.5, context)
                    : Responsive.width(4, context),
                child: const CircularProgressIndicator(
                  color: AppColors.subTitleColor,
                  strokeWidth: 2,
                ),
              )
                  : Text(
                'Pular',
                style: GoogleFonts.poppins(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: AppColors.subTitleColor,
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          width: isSmallScreen
              ? Responsive.width(2.5, context)
              : Responsive.width(3, context),
        ),
        // Botão Avaliar
        Expanded(
          flex: 2,
          child: Container(
            height: buttonHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primary],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextButton(
              onPressed: _isLoading ? null : _submitRating,
              child: _isLoading
                  ? SizedBox(
                width: isSmallScreen
                    ? Responsive.width(4, context)
                    : Responsive.width(5, context),
                height: isSmallScreen
                    ? Responsive.width(4, context)
                    : Responsive.width(5, context),
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : Text(
                'Avaliar',
                style: GoogleFonts.poppins(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getRatingText(double rating) {
    if (rating >= 4.5) return '😍 Excelente!';
    if (rating >= 3.5) return '😊 Muito bom!';
    if (rating >= 2.5) return '😐 Regular';
    if (rating >= 1.5) return '😔 Ruim';
    return '😡 Muito ruim';
  }
}