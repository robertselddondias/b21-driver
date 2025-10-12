// ignore_for_file: file_names

import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';

class Preferences {
  static const isFinishOnBoardingKey = "isFinishOnBoardingKey";
  static const languageCodeKey = "languageCodeKey";
  static const themKey = "themKey";

  static late SharedPreferences pref;
  static bool _isInitialized = false;

  /// Inicializa o SharedPreferences com retry
  static Future<void> initPref() async {
    if (_isInitialized) {
      log('SharedPreferences já foi inicializado');
      return;
    }

    try {
      pref = await SharedPreferences.getInstance();
      _isInitialized = true;
      log('SharedPreferences inicializado com sucesso');

      // Força reload para garantir que os dados estão sincronizados
      await pref.reload();
    } catch (e) {
      log('Erro ao inicializar SharedPreferences: $e');
      // Retry após 1 segundo
      await Future.delayed(const Duration(seconds: 1));
      try {
        pref = await SharedPreferences.getInstance();
        _isInitialized = true;
        log('SharedPreferences inicializado com sucesso no retry');
      } catch (e2) {
        log('Erro crítico ao inicializar SharedPreferences: $e2');
        rethrow;
      }
    }
  }

  /// Verifica se foi inicializado
  static Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initPref();
    }
  }

  /// Recarrega os valores do SharedPreferences
  static Future<void> reload() async {
    await _ensureInitialized();
    await pref.reload();
    log('SharedPreferences recarregado');
  }

  // ==================== BOOLEAN ====================

  static bool getBoolean(String key) {
    if (!_isInitialized) {
      log('⚠️ SharedPreferences não inicializado ao tentar ler boolean: $key');
      return false;
    }
    return pref.getBool(key) ?? false;
  }

  static Future<bool> setBoolean(String key, bool value) async {
    await _ensureInitialized();
    try {
      final result = await pref.setBool(key, value);
      if (result) {
        // Força commit para garantir gravação
        await pref.reload();
        log('✅ Boolean salvo com sucesso: $key = $value');
      } else {
        log('❌ Falha ao salvar boolean: $key = $value');
      }
      return result;
    } catch (e) {
      log('❌ Erro ao salvar boolean $key: $e');
      return false;
    }
  }

  // ==================== STRING ====================

  static String getString(String key) {
    if (!_isInitialized) {
      log('⚠️ SharedPreferences não inicializado ao tentar ler string: $key');
      return "";
    }
    final value = pref.getString(key) ?? "";
    log('📖 Lendo string: $key = $value');
    return value;
  }

  static Future<bool> setString(String key, String value) async {
    await _ensureInitialized();
    try {
      final result = await pref.setString(key, value);
      if (result) {
        // Força commit para garantir gravação
        await pref.reload();

        // Verifica se foi realmente salvo
        final savedValue = pref.getString(key);
        if (savedValue == value) {
          log('✅ String salva com sucesso: $key = $value');
        } else {
          log('⚠️ String salva mas verificação falhou: $key = $value (lido: $savedValue)');
        }
      } else {
        log('❌ Falha ao salvar string: $key = $value');
      }
      return result;
    } catch (e) {
      log('❌ Erro ao salvar string $key: $e');
      return false;
    }
  }

  // ==================== INTEGER ====================

  static int getInt(String key) {
    if (!_isInitialized) {
      log('⚠️ SharedPreferences não inicializado ao tentar ler int: $key');
      return 0;
    }
    return pref.getInt(key) ?? 0;
  }

  static Future<bool> setInt(String key, int value) async {
    await _ensureInitialized();
    try {
      final result = await pref.setInt(key, value);
      if (result) {
        // Força commit para garantir gravação
        await pref.reload();
        log('✅ Int salvo com sucesso: $key = $value');
      } else {
        log('❌ Falha ao salvar int: $key = $value');
      }
      return result;
    } catch (e) {
      log('❌ Erro ao salvar int $key: $e');
      return false;
    }
  }

  // ==================== DOUBLE ====================

  static double getDouble(String key) {
    if (!_isInitialized) {
      log('⚠️ SharedPreferences não inicializado ao tentar ler double: $key');
      return 0.0;
    }
    return pref.getDouble(key) ?? 0.0;
  }

  static Future<bool> setDouble(String key, double value) async {
    await _ensureInitialized();
    try {
      final result = await pref.setDouble(key, value);
      if (result) {
        await pref.reload();
        log('✅ Double salvo com sucesso: $key = $value');
      } else {
        log('❌ Falha ao salvar double: $key = $value');
      }
      return result;
    } catch (e) {
      log('❌ Erro ao salvar double $key: $e');
      return false;
    }
  }

  // ==================== STRING LIST ====================

  static List<String> getStringList(String key) {
    if (!_isInitialized) {
      log('⚠️ SharedPreferences não inicializado ao tentar ler string list: $key');
      return [];
    }
    return pref.getStringList(key) ?? [];
  }

  static Future<bool> setStringList(String key, List<String> value) async {
    await _ensureInitialized();
    try {
      final result = await pref.setStringList(key, value);
      if (result) {
        await pref.reload();
        log('✅ String list salva com sucesso: $key = $value');
      } else {
        log('❌ Falha ao salvar string list: $key');
      }
      return result;
    } catch (e) {
      log('❌ Erro ao salvar string list $key: $e');
      return false;
    }
  }

  // ==================== CLEAR ====================

  static Future<bool> clearSharPreference() async {
    await _ensureInitialized();
    try {
      final result = await pref.clear();
      if (result) {
        log('✅ SharedPreferences limpo com sucesso');
      } else {
        log('❌ Falha ao limpar SharedPreferences');
      }
      return result;
    } catch (e) {
      log('❌ Erro ao limpar SharedPreferences: $e');
      return false;
    }
  }

  static Future<bool> clearKeyData(String key) async {
    await _ensureInitialized();
    try {
      final result = await pref.remove(key);
      if (result) {
        await pref.reload();
        log('✅ Chave removida com sucesso: $key');
      } else {
        log('❌ Falha ao remover chave: $key');
      }
      return result;
    } catch (e) {
      log('❌ Erro ao remover chave $key: $e');
      return false;
    }
  }

  // ==================== UTILITY ====================

  /// Verifica se uma chave existe
  static bool containsKey(String key) {
    if (!_isInitialized) {
      log('⚠️ SharedPreferences não inicializado ao verificar chave: $key');
      return false;
    }
    return pref.containsKey(key);
  }

  /// Retorna todas as chaves
  static Set<String> getKeys() {
    if (!_isInitialized) {
      log('⚠️ SharedPreferences não inicializado ao buscar chaves');
      return {};
    }
    return pref.getKeys();
  }

  /// Debug: Imprime todos os valores salvos
  static void printAllValues() {
    if (!_isInitialized) {
      log('⚠️ SharedPreferences não inicializado');
      return;
    }

    log('========== SharedPreferences Debug ==========');
    final keys = pref.getKeys();
    for (var key in keys) {
      final value = pref.get(key);
      log('$key: $value (${value.runtimeType})');
    }
    log('=============================================');
  }
}