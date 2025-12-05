// lib/widget/user_view.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/model/user_model.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/responsive.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserView extends StatelessWidget {
  final String? userId;
  final String? amount;
  final String? distance;
  final String? distanceType;

  const UserView({
    super.key,
    this.userId,
    this.amount,
    this.distance,
    this.distanceType,
  });

  /// Método seguro para formatar valores monetários
  String _safeAmountShow(String? amount) {
    try {
      if (amount == null || amount.isEmpty || amount == 'null') {
        return Constant.currencyModel?.symbol != null
            ? "${Constant.currencyModel!.symbol} 0.00"
            : "R\$ 0.00";
      }

      double value = double.tryParse(amount) ?? 0.0;
      return Constant.amountShow(amount: value.toString());
    } catch (e) {
      debugPrint('❌ Erro ao formatar valor: $amount - $e');
      return Constant.currencyModel?.symbol != null
          ? "${Constant.currencyModel!.symbol} 0.00"
          : "R\$ 0.00";
    }
  }

  /// Método seguro para formatar distância
  String _safeDistanceShow(String? distance, String? distanceType) {
    try {
      if (distance == null || distance.isEmpty || distance == 'null') {
        return "0.0 ${distanceType ?? 'km'}";
      }

      double value = double.tryParse(distance) ?? 0.0;
      int decimalDigits = Constant.currencyModel?.decimalDigits ?? 2;
      return "${value.toStringAsFixed(decimalDigits)} ${distanceType ?? 'km'}";
    } catch (e) {
      debugPrint('❌ Erro ao formatar distância: $distance - $e');
      return "0.0 ${distanceType ?? 'km'}";
    }
  }

  /// Método seguro para calcular avaliações
  String _safeCalculateReview(String? reviewCount, String? reviewSum) {
    try {
      if (reviewCount == null ||
          reviewSum == null ||
          reviewCount.isEmpty ||
          reviewSum.isEmpty ||
          reviewCount == 'null' ||
          reviewSum == 'null') {
        return "0.0";
      }

      return Constant.calculateReview(
        reviewCount: reviewCount,
        reviewSum: reviewSum,
      );
    } catch (e) {
      debugPrint('❌ Erro ao calcular avaliação: $e');
      return "0.0";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsividade baseada na largura da tela
    final bool isSmallScreen = screenWidth < 360;
    final bool isMediumScreen = screenWidth >= 360 && screenWidth < 400;

    final double avatarSize = isSmallScreen ? 45 : (isMediumScreen ? 50 : 55);
    final double iconSize = isSmallScreen ? 14 : 16;
    final double starSize = isSmallScreen ? 16 : 18;
    final double spacing = isSmallScreen ? 6 : 8;

    return FutureBuilder<UserModel?>(
      future: FireStoreUtils.getCustomer(userId.toString()),
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return _buildLoadingState(context, avatarSize);

          case ConnectionState.done:
            if (snapshot.hasError) {
              return _buildErrorState(context, snapshot.error.toString());
            }

            if (snapshot.data == null) {
              return _buildUserCard(
                context: context,
                userName: "Usuário",
                profilePic: Constant.userPlaceHolder,
                rating: "0.0",
                avatarSize: avatarSize,
                iconSize: iconSize,
                starSize: starSize,
                spacing: spacing,
              );
            }

            UserModel userModel = snapshot.data!;
            return _buildUserCard(
              context: context,
              userName: userModel.fullName?.isNotEmpty == true
                  ? userModel.fullName!
                  : "Usuário",
              profilePic: userModel.profilePic?.isNotEmpty == true
                  ? userModel.profilePic!
                  : Constant.userPlaceHolder,
              rating: _safeCalculateReview(
                userModel.reviewsCount,
                userModel.reviewsSum,
              ),
              avatarSize: avatarSize,
              iconSize: iconSize,
              starSize: starSize,
              spacing: spacing,
            );

          default:
            return _buildErrorState(context, 'Erro desconhecido');
        }
      },
    );
  }

  Widget _buildLoadingState(BuildContext context, double avatarSize) {
    return Container(
      padding: EdgeInsets.all(Responsive.width(3, context)),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(Responsive.width(3, context)),
      ),
      child: Row(
        children: [
          Container(
            height: avatarSize,
            width: avatarSize,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(Responsive.width(2.5, context)),
            ),
            child: Center(
              child: SizedBox(
                width: Responsive.width(5, context),
                height: Responsive.width(5, context),
                child: CircularProgressIndicator(strokeWidth: Responsive.width(0.5, context)),
              ),
            ),
          ),
          SizedBox(width: Responsive.width(3, context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: Responsive.height(2, context),
                  width: Responsive.width(30, context),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(Responsive.width(1, context)),
                  ),
                ),
                SizedBox(height: Responsive.height(1, context)),
                Container(
                  height: Responsive.height(1.8, context),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(Responsive.width(1, context)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Container(
      padding: EdgeInsets.all(Responsive.width(3, context)),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(Responsive.width(3, context)),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            size: Responsive.width(6, context),
          ),
          SizedBox(width: Responsive.width(3, context)),
          Expanded(
            child: Text(
              'Erro ao carregar usuário',
              style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.error,
                fontSize: Responsive.width(3.5, context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard({
    required BuildContext context,
    required String userName,
    required String profilePic,
    required String rating,
    required double avatarSize,
    required double iconSize,
    required double starSize,
    required double spacing,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing + 4,
        vertical: spacing + 6,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [
            theme.colorScheme.surface,
            theme.colorScheme.surface.withOpacity(0.8),
          ]
              : [
            theme.colorScheme.primaryContainer.withOpacity(0.3),
            theme.colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(Responsive.width(4, context)),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: Responsive.width(0.25, context),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            blurRadius: Responsive.width(3, context),
            offset: Offset(0, Responsive.height(0.5, context)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Linha superior: Avatar + Nome
          Row(
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Responsive.width(3, context)),
                    child: CachedNetworkImage(
                      height: avatarSize,
                      width: avatarSize,
                      imageUrl: profilePic,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Center(
                          child: SizedBox(
                            width: Responsive.width(5, context),
                            height: Responsive.width(5, context),
                            child: CircularProgressIndicator(
                              strokeWidth: Responsive.width(0.5, context),
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.person,
                          size: avatarSize * 0.5,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: Responsive.width(0.5, context),
                    right: Responsive.width(0.5, context),
                    child: Container(
                      width: Responsive.width(2.5, context),
                      height: Responsive.width(2.5, context),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.surface,
                          width: Responsive.width(0.5, context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: spacing + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: Responsive.width(4, context),
                        color: theme.colorScheme.onSurface,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: Responsive.height(0.25, context)),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: iconSize,
                          color: AppColors.ratingColour,
                        ),
                        SizedBox(width: Responsive.width(1, context)),
                        Text(
                          rating,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: Responsive.width(3.2, context),
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: spacing + 4),
          // Linha inferior: Informações principais em cards separados
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  context: context,
                  icon: Icons.attach_money,
                  label: 'Valor',
                  value: _safeAmountShow(amount),
                  color: theme.colorScheme.primary,
                  iconSize: iconSize + 2,
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: _buildInfoCard(
                  context: context,
                  icon: Icons.location_on,
                  label: 'Distância',
                  value: _safeDistanceShow(distance, distanceType),
                  color: theme.colorScheme.secondary,
                  iconSize: iconSize + 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required double iconSize,
  }) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 360;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.width(2.5, context),
        vertical: Responsive.width(2.5, context),
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(Responsive.width(3, context)),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: Responsive.width(0.25, context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(Responsive.width(1, context)),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(Responsive.width(1.5, context)),
                ),
                child: Icon(
                  icon,
                  size: iconSize,
                  color: color,
                ),
              ),
              SizedBox(width: Responsive.width(1.5, context)),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: Responsive.width(2.7, context),
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.height(0.5, context)),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: Responsive.width(3.5, context),
              color: theme.colorScheme.onSurface,
              letterSpacing: 0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}