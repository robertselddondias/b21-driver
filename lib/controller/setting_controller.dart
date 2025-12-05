import 'package:driver/constant/constant.dart';
import 'package:driver/model/language_model.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:driver/utils/Preferences.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

class SettingController extends GetxController {
  @override
  void onInit() {
    // TODO: implement onInit
    getLanguage();
    super.onInit();
  }

  RxBool isLoading = true.obs;
  RxList<LanguageModel> languageList = <LanguageModel>[].obs;
  RxList<String> modeList = <String>['Light mode', 'Dark mode', 'System'].obs;
  Rx<LanguageModel> selectedLanguage = LanguageModel().obs;
  Rx<String> selectedMode = "".obs;

  getLanguage() async {
    await FireStoreUtils.getLanguage().then((value) {
      if (value != null) {
        languageList.value = value;
        if (Preferences.getString(Preferences.languageCodeKey)
            .toString()
            .isNotEmpty) {
          LanguageModel pref = Constant.getLanguage();

          for (var element in languageList) {
            if (element.id == pref.id) {
              selectedLanguage.value = element;
            }
          }
        }
      }
    });

    // Carrega o tema salvo das preferências
    if (Preferences.getString(Preferences.themKey).toString().isNotEmpty) {
      selectedMode.value =
          Preferences.getString(Preferences.themKey).toString();
    } else {
      // Define um valor padrão se não houver tema salvo
      selectedMode.value = "System";
    }

    isLoading.value = false;
    update();
  }

  /// Método para atualizar o tema selecionado
  void updateThemeMode(String newMode, BuildContext context) async {
    selectedMode.value = newMode;

    // Salva nas preferências
    await Preferences.setString(Preferences.themKey, newMode);

    // Atualiza o DarkThemeProvider
    final themeProvider =
        Provider.of<DarkThemeProvider>(context, listen: false);

    if (newMode == "Dark mode") {
      themeProvider.darkTheme = 0;
    } else if (newMode == "Light mode") {
      themeProvider.darkTheme = 1;
    } else {
      // System
      themeProvider.darkTheme = 2;
    }

    update();
  }

  /// Método para carregar o tema inicial do DarkThemeProvider
  void loadThemeFromProvider(BuildContext context) {
    final themeProvider =
        Provider.of<DarkThemeProvider>(context, listen: false);

    // Converte o valor numérico do provider para string
    switch (themeProvider.darkTheme) {
      case 0:
        selectedMode.value = "Dark mode";
        break;
      case 1:
        selectedMode.value = "Light mode";
        break;
      case 2:
        selectedMode.value = "System";
        break;
      default:
        selectedMode.value = "System";
    }
    update();
  }
}
