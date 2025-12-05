// lib/themes/app_colors.dart - Versão com cores otimizadas para visibilidade
import 'package:flutter/material.dart';

class AppColors {
  // ==================== CORES PRINCIPAIS ====================
  static const Color primary = Color(0xff000000);
  static const Color darkModePrimary = Color(0xff7DD321); // Verde mais vibrante

  // ==================== BACKGROUNDS PRINCIPAIS ====================
  static const Color background = Color(0xffFFFFFF);
  static const Color darkBackground =
      Color(0xff0F1114); // Mais escuro para melhor contraste

  // ==================== ÍCONES E ELEMENTOS ====================
  static const Color drawerIcon = Color(0xffC2C7D4);

  // ==================== CINZAS E NEUTROS ====================
  static const Color lightGray = Color(0xffF4F4F4);
  static const Color darkGray = Color(0xFF1A1D21); // Mais escuro

  static const Color gray = Color(0xffF6F6F6);
  static const Color ratingColour = Color(0xffECA700);
  static const Color dottedDivider = Color(0xff7D7D7D);

  // ==================== TEXTOS E SUBTÍTULOS ====================
  static const Color subTitleColor = Color(0xff888888);
  static const Color darkSubTitleColor =
      Color(0xffB8BCC2); // Muito mais claro no dark

  // ==================== CONTAINERS ====================
  static const Color containerBackground = Color(0xFFFFFFFF);
  static const Color darkContainerBackground =
      Color(0xFF1D2126); // Mais claro que o background

  static const Color containerBorder = Color(0xFFBFCED2);
  static const Color darkContainerBorder = Color(0xFF4A515A); // Bem mais claro

  // ==================== CAMPOS DE TEXTO ====================
  static const Color textField = Color(0xFFFDFDFF);
  static const Color darkTextField =
      Color(0xFF262B32); // Mais claro que container

  static const Color textFieldBorder = Color(0xFFB7C2DA);
  static const Color darkTextFieldBorder =
      Color(0xFF52596B); // Muito mais visível

  // ==================== SERVIÇOS E ESPECIAIS ====================
  static const Color darkService = Color(0xff343A42); // Mais claro
  static const Color onBoarding = Color(0xffE7E8EE);

  static const Color serviceColor1 = Color(0xffFFF9E3);
  static const Color serviceColor2 = Color(0xffF2F1FF);
  static const Color serviceColor3 = Color(0xffFFF5F5);

  // ==================== CORES DE STATUS ====================
  static const Color success = Color(0xff4CAF50);
  static const Color darkSuccess =
      Color(0xff7DD321); // Verde mais brilhante no dark

  static const Color warning = Color(0xffFF9800);
  static const Color darkWarning = Color(0xffFFB74D);

  static const Color error = Color(0xffF44336);
  static const Color darkError = Color(0xffEF5350);

  // ==================== MÉTODOS AUXILIARES ====================

  /// Retorna a cor de texto baseada no tema
  static Color getTextColor(bool isDarkMode) {
    return isDarkMode ? const Color(0xffE8EAED) : Colors.black;
  }

  /// Retorna a cor de texto secundário baseada no tema
  static Color getSecondaryTextColor(bool isDarkMode) {
    return isDarkMode ? darkSubTitleColor : subTitleColor;
  }

  /// Retorna a cor do container baseada no tema
  static Color getContainerColor(bool isDarkMode) {
    return isDarkMode ? darkContainerBackground : containerBackground;
  }

  /// Retorna a cor da borda baseada no tema
  static Color getBorderColor(bool isDarkMode) {
    return isDarkMode ? darkContainerBorder : containerBorder;
  }

  /// Retorna a cor do campo de texto baseada no tema
  static Color getTextFieldColor(bool isDarkMode) {
    return isDarkMode ? darkTextField : textField;
  }

  /// Retorna a cor da borda do campo de texto baseada no tema
  static Color getTextFieldBorderColor(bool isDarkMode) {
    return isDarkMode ? darkTextFieldBorder : textFieldBorder;
  }

  /// Retorna a cor principal baseada no tema
  static Color getPrimaryColor(bool isDarkMode) {
    return isDarkMode ? darkModePrimary : primary;
  }

  /// Retorna a cor de fundo baseada no tema
  static Color getBackgroundColor(bool isDarkMode) {
    return isDarkMode ? darkBackground : background;
  }

  /// Retorna a cor de sucesso baseada no tema
  static Color getSuccessColor(bool isDarkMode) {
    return isDarkMode ? darkSuccess : success;
  }

  /// Retorna a cor de aviso baseada no tema
  static Color getWarningColor(bool isDarkMode) {
    return isDarkMode ? darkWarning : warning;
  }

  /// Retorna a cor de erro baseada no tema
  static Color getErrorColor(bool isDarkMode) {
    return isDarkMode ? darkError : error;
  }

  // ==================== GRADIENTES ESPECIAIS ====================

  /// Gradiente principal para modo claro
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xff333333)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Gradiente principal para modo escuro
  static const LinearGradient darkPrimaryGradient = LinearGradient(
    colors: [darkModePrimary, Color(0xff5FB31A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Retorna o gradiente baseado no tema
  static LinearGradient getPrimaryGradient(bool isDarkMode) {
    return isDarkMode ? darkPrimaryGradient : primaryGradient;
  }

  // ==================== CORES DE OVERLAY ====================

  /// Overlay escuro para modals
  static const Color overlayDark = Color(0x80000000);

  /// Overlay claro para modals no modo escuro
  static const Color overlayLight = Color(0x40FFFFFF);

  /// Retorna a cor de overlay baseada no tema
  static Color getOverlayColor(bool isDarkMode) {
    return isDarkMode ? overlayLight : overlayDark;
  }

  // ==================== CORES SEMÂNTICAS ====================

  /// Cores para diferentes tipos de mensagens
  static const Color infoLight = Color(0xff2196F3);
  static const Color infoDark = Color(0xff42A5F5);

  /// Retorna a cor de informação baseada no tema
  static Color getInfoColor(bool isDarkMode) {
    return isDarkMode ? infoDark : infoLight;
  }
}
