import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';

class DarkThemePreference {
  static const THEME_STATUS = "THEMESTATUS";

  /// Define o tema com verificação e retry
  Future<bool> setDarkTheme(int value) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final result = await prefs.setInt(THEME_STATUS, value);

      if (result) {
        // Força reload para garantir que foi salvo
        await prefs.reload();

        // Verifica se foi realmente salvo
        final savedValue = prefs.getInt(THEME_STATUS);
        if (savedValue == value) {
          log('✅ Tema salvo com sucesso: $value');
          return true;
        } else {
          log('⚠️ Tema salvo mas verificação falhou: esperado $value, lido $savedValue');
          // Tenta salvar novamente
          final retryResult = await prefs.setInt(THEME_STATUS, value);
          await prefs.reload();
          log('Retry resultado: $retryResult');
          return retryResult;
        }
      } else {
        log('❌ Falha ao salvar tema: $value');
        return false;
      }
    } catch (e) {
      log('❌ Erro ao salvar tema: $e');
      return false;
    }
  }

  /// Obtém o tema salvo
  Future<int> getTheme() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      // Força reload antes de ler
      await prefs.reload();

      final value = prefs.getInt(THEME_STATUS) ?? 2; // 2 = System default
      log('📖 Tema lido: $value');
      return value;
    } catch (e) {
      log('❌ Erro ao ler tema: $e');
      return 2; // Retorna System como padrão em caso de erro
    }
  }

  /// Verifica se o tema foi salvo
  Future<bool> hasTheme() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      return prefs.containsKey(THEME_STATUS);
    } catch (e) {
      log('❌ Erro ao verificar tema: $e');
      return false;
    }
  }

  /// Remove o tema salvo
  Future<bool> clearTheme() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final result = await prefs.remove(THEME_STATUS);
      if (result) {
        await prefs.reload();
        log('✅ Tema removido com sucesso');
      }
      return result;
    } catch (e) {
      log('❌ Erro ao remover tema: $e');
      return false;
    }
  }
}
