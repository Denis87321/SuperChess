import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsLocaleKey = 'app_locale'; // '' | 'ru' | 'en'

/// Holds user language preference. Empty = follow device.
class LocaleController extends ChangeNotifier {
  LocaleController();

  String? _overrideCode; // null or '' = system
  Locale _resolved = const Locale('en');

  Locale get locale => _resolved;

  /// 'system' | 'ru' | 'en'
  String get preference {
    final code = _overrideCode;
    if (code == null || code.isEmpty) return 'system';
    return code;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _overrideCode = prefs.getString(_prefsLocaleKey);
    _resolve();
    notifyListeners();
  }

  Future<void> setPreference(String preference) async {
    final prefs = await SharedPreferences.getInstance();
    if (preference == 'system') {
      _overrideCode = '';
      await prefs.setString(_prefsLocaleKey, '');
    } else {
      _overrideCode = preference;
      await prefs.setString(_prefsLocaleKey, preference);
    }
    _resolve();
    notifyListeners();
  }

  void onSystemLocalesChanged() {
    if (_overrideCode == null || _overrideCode!.isEmpty) {
      _resolve();
      notifyListeners();
    }
  }

  void _resolve() {
    final override = _overrideCode;
    if (override != null && override.isNotEmpty) {
      _resolved = Locale(override);
      return;
    }
    final platform = WidgetsBinding.instance.platformDispatcher.locale;
    final code = platform.languageCode.toLowerCase();
    const supported = {
      'ru', 'en', 'es', 'de', 'fr', 'pt', 'uk', 'pl', 'tr', 'it',
      'zh', 'ja', 'ko', 'vi', 'ar', 'hi',
    };
    if (supported.contains(code)) {
      _resolved = Locale(code);
    } else {
      _resolved = const Locale('en');
    }
  }
}
