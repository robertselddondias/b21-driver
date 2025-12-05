import 'package:cached_network_image/cached_network_image.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/model/user_model.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/responsive.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserDriverView extends StatelessWidget {
  final String? userId;
  final String? amount;

  const UserDriverView({super.key, this.userId, this.amount});

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
                return Text(snapshot.error.toString());
              } else {
                if (snapshot.data == null) {
                  // User not found - show placeholder
                  return _buildUserCard(
                    context: context,
                    imageUrl: Constant.userPlaceHolder,
                    name: "Asynchronous user",
                    reviewCount: "0.0",
                    reviewSum: "0.0",
                  );
                } else {
                  // User found - show real data
                  UserModel driverModel = snapshot.data!;
                  return _buildUserCard(
                    context: context,
                    imageUrl: driverModel.profilePic.toString(),
                    name: driverModel.fullName.toString(),
                    reviewCount: driverModel.reviewsCount.toString(),
                    reviewSum: driverModel.reviewsSum.toString(),
                  );
                }
              }
            default:
              return const Text('Error');
          }
        });
  }

  /// RESPONSIVO: Card de informações do usuário
  Widget _buildUserCard({
    required BuildContext context,
    required String imageUrl,
    required String name,
    required String reviewCount,
    required String reviewSum,
  }) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar responsivo
            ClipRRect(
              borderRadius: BorderRadius.all(
                Radius.circular(Responsive.width(2.5, context)),
              ),
              child: CachedNetworkImage(
                height: Responsive.width(12, context),
                width: Responsive.width(12, context),
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Constant.loader(context),
                errorWidget: (context, url, error) => Image.network(
                  Constant.userPlaceHolder,
                ),
              ),
            ),

            SizedBox(width: Responsive.width(2.5, context)),

            // Informações do usuário
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: Responsive.width(4, context),
                    ),
                  ),

                  // Rating e Valor
                  Row(
                    children: [
                      // Rating
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: Responsive.width(5, context),
                              color: AppColors.ratingColour,
                            ),
                            SizedBox(width: Responsive.width(1.2, context)),
                            Text(
                              Constant.calculateReview(
                                reviewCount: reviewCount,
                                reviewSum: reviewSum,
                              ),
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                                fontSize: Responsive.width(3.5, context),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Valor
                      Text(
                        Constant.amountShow(amount: amount),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: Responsive.width(4, context),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
