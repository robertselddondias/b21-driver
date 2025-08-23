// lib/widget/user_view.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/model/user_model.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserView extends StatelessWidget {
  final String? userId;
  final String? amount;
  final String? distance;
  final String? distanceType;

  const UserView({super.key, this.userId, this.amount, this.distance, this.distanceType});

  /// Método seguro para formatar valores monetários
  String _safeAmountShow(String? amount) {
    try {
      if (amount == null || amount.isEmpty || amount == 'null') {
        return Constant.currencyModel?.symbol != null
            ? "${Constant.currencyModel!.symbol} 0.00"
            : "R\$ 0.00";
      }

      // Tenta converter para double primeiro
      double value = double.tryParse(amount) ?? 0.0;
      return Constant.amountShow(amount: value.toString());
    } catch (e) {
      print('❌ Erro ao formatar valor: $amount - $e');
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
      print('❌ Erro ao formatar distância: $distance - $e');
      return "0.0 ${distanceType ?? 'km'}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
        future: FireStoreUtils.getCustomer(userId.toString()),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return const SizedBox();
            case ConnectionState.done:
              if (snapshot.hasError) {
                return Text('Erro: ${snapshot.error}');
              } else {
                if (snapshot.data == null) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.all(Radius.circular(10)),
                        child: CachedNetworkImage(
                          height: 50,
                          width: 50,
                          imageUrl: Constant.userPlaceHolder,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Constant.loader(context),
                          errorWidget: (context, url, error) => Image.network(
                              'https://firebasestorage.googleapis.com/v0/b/goride-1a752.appspot.com/o/placeholderImages%2Fuser-placeholder.jpeg?alt=media&token=34a73d67-ba1d-4fe4-a29f-271d3e3ca115'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                "Usuário",
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  flex: 2,
                                  child: Text(
                                    _safeAmountShow(amount),
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  flex: 2,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 2),
                                      Expanded(
                                        child: Text(
                                          _safeDistanceShow(distance, distanceType),
                                          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  flex: 1,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        size: 18,
                                        color: AppColors.ratingColour,
                                      ),
                                      const SizedBox(width: 2),
                                      Expanded(
                                        child: Text(
                                          "0.0",
                                          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  );
                }

                UserModel userModel = snapshot.data!;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                      child: CachedNetworkImage(
                        height: 50,
                        width: 50,
                        imageUrl: userModel.profilePic?.isNotEmpty == true
                            ? userModel.profilePic!
                            : Constant.userPlaceHolder,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Constant.loader(context),
                        errorWidget: (context, url, error) => Image.network(
                            'https://firebasestorage.googleapis.com/v0/b/goride-1a752.appspot.com/o/placeholderImages%2Fuser-placeholder.jpeg?alt=media&token=34a73d67-ba1d-4fe4-a29f-271d3e3ca115'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              userModel.fullName?.isNotEmpty == true
                                  ? userModel.fullName!
                                  : "Usuário",
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                flex: 2,
                                child: Text(
                                  _safeAmountShow(amount),
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                flex: 2,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 2),
                                    Expanded(
                                      child: Text(
                                        _safeDistanceShow(distance, distanceType),
                                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                flex: 1,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      size: 18,
                                      color: AppColors.ratingColour,
                                    ),
                                    const SizedBox(width: 2),
                                    Expanded(
                                      child: Text(
                                        _safeCalculateReview(
                                            userModel.reviewsCount,
                                            userModel.reviewsSum
                                        ),
                                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                );
              }
            default:
              return const Text('Erro');
          }
        });
  }

  /// Método seguro para calcular avaliações
  String _safeCalculateReview(String? reviewCount, String? reviewSum) {
    try {
      if (reviewCount == null || reviewSum == null ||
          reviewCount.isEmpty || reviewSum.isEmpty ||
          reviewCount == 'null' || reviewSum == 'null') {
        return "0.0";
      }

      return Constant.calculateReview(
          reviewCount: reviewCount,
          reviewSum: reviewSum
      );
    } catch (e) {
      print('❌ Erro ao calcular avaliação: $e');
      return "0.0";
    }
  }
}