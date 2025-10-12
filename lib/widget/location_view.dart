// lib/widget/location_view.dart - Versão com cores temáticas corretas
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/responsive.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dash/flutter_dash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class LocationView extends StatelessWidget {
  final String? sourceLocation;
  final String? destinationLocation;

  const LocationView({super.key, this.sourceLocation, this.destinationLocation});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDarkMode = themeChange.getThem();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Coluna com ícones e linha tracejada
        Column(
          children: [
            // Ícone de origem
            Container(
              padding: EdgeInsets.all(Responsive.width(2, context)),
              decoration: BoxDecoration(
                color: AppColors.getPrimaryColor(isDarkMode).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.my_location,
                color: AppColors.getPrimaryColor(isDarkMode),
                size: Responsive.width(4, context),
              ),
            ),

            // Linha tracejada
            Container(
              margin: EdgeInsets.symmetric(vertical: Responsive.height(0.5, context)),
              child: Dash(
                direction: Axis.vertical,
                length: Responsive.height(6, context),
                dashLength: 6,
                dashGap: 3,
                dashColor: isDarkMode
                    ? Colors.white.withOpacity(0.4)
                    : AppColors.dottedDivider,
                dashThickness: 2,
              ),
            ),

            // Ícone de destino
            Container(
              padding: EdgeInsets.all(Responsive.width(2, context)),
              decoration: BoxDecoration(
                color: AppColors.getErrorColor(isDarkMode).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.location_on,
                color: AppColors.getErrorColor(isDarkMode),
                size: Responsive.width(4, context),
              ),
            ),
          ],
        ),

        SizedBox(width: Responsive.width(3, context)),

        // Coluna com os textos das localizações
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Localização de origem
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.width(3, context),
                  vertical: Responsive.height(1.2, context),
                ),
                decoration: BoxDecoration(
                  color: AppColors.getContainerColor(isDarkMode),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.getBorderColor(isDarkMode),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Origem',
                      style: GoogleFonts.poppins(
                        fontSize: Responsive.width(2.8, context),
                        fontWeight: FontWeight.w500,
                        color: isDarkMode
                            ? const Color(0xffB0B0B0)
                            : AppColors.subTitleColor,
                      ),
                    ),
                    SizedBox(height: Responsive.height(0.3, context)),
                    Text(
                      sourceLocation?.toString() ?? 'Localização não informada',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: Responsive.width(3.5, context),
                        fontWeight: FontWeight.w400,
                        color: isDarkMode ? Colors.white : Colors.black,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: Responsive.height(1.5, context)),

              // Localização de destino
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.width(3, context),
                  vertical: Responsive.height(1.2, context),
                ),
                decoration: BoxDecoration(
                  color: AppColors.getContainerColor(isDarkMode),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.getBorderColor(isDarkMode),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Destino',
                      style: GoogleFonts.poppins(
                        fontSize: Responsive.width(2.8, context),
                        fontWeight: FontWeight.w500,
                        color: isDarkMode
                            ? const Color(0xffB0B0B0)
                            : AppColors.subTitleColor,
                      ),
                    ),
                    SizedBox(height: Responsive.height(0.3, context)),
                    Text(
                      destinationLocation?.toString() ?? 'Destino não informado',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: Responsive.width(3.5, context),
                        fontWeight: FontWeight.w400,
                        color: isDarkMode ? Colors.white : Colors.black,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}