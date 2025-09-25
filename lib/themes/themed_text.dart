// lib/widgets/themed_text.dart - Widget para textos temáticos

import 'package:driver/themes/app_colors.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ThemedText extends StatelessWidget {
  final String text;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final bool? isSecondary;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextStyle? style;

  const ThemedText(
      this.text, {
        Key? key,
        this.fontSize,
        this.fontWeight,
        this.color,
        this.isSecondary = false,
        this.textAlign,
        this.maxLines,
        this.overflow,
        this.style,
      }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDarkMode = themeChange.getThem();

    // Determina a cor do texto
    Color textColor;
    if (color != null) {
      textColor = color!;
    } else if (isSecondary == true) {
      textColor = AppColors.getSecondaryTextColor(isDarkMode);
    } else {
      textColor = AppColors.getTextColor(isDarkMode);
    }

    return Text(
      text,
      style: style?.copyWith(color: textColor) ?? GoogleFonts.poppins(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: textColor,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

// Widgets específicos para casos comuns
class ThemedHeading extends StatelessWidget {
  final String text;
  final double? fontSize;
  final TextAlign? textAlign;
  final int? maxLines;

  const ThemedHeading(
      this.text, {
        Key? key,
        this.fontSize = 18,
        this.textAlign,
        this.maxLines,
      }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ThemedText(
      text,
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      textAlign: textAlign,
      maxLines: maxLines,
    );
  }
}

class ThemedSubtitle extends StatelessWidget {
  final String text;
  final double? fontSize;
  final TextAlign? textAlign;
  final int? maxLines;

  const ThemedSubtitle(
      this.text, {
        Key? key,
        this.fontSize = 14,
        this.textAlign,
        this.maxLines,
      }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ThemedText(
      text,
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      isSecondary: true,
      textAlign: textAlign,
      maxLines: maxLines,
    );
  }
}

class ThemedBody extends StatelessWidget {
  final String text;
  final double? fontSize;
  final FontWeight? fontWeight;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ThemedBody(
      this.text, {
        Key? key,
        this.fontSize = 16,
        this.fontWeight = FontWeight.w400,
        this.textAlign,
        this.maxLines,
        this.overflow,
      }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ThemedText(
      text,
      fontSize: fontSize,
      fontWeight: fontWeight,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}