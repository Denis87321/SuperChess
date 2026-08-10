import 'package:flutter/material.dart';

/// Shell UI locales. RU/EN: full AppStrings. Other locales: ARB subset for
/// common shell keys + English fallback for the rest.
const List<Locale> kSupportedLocales = [
  Locale('en'),
  Locale('ru'),
  Locale('es'),
  Locale('de'),
  Locale('fr'),
  Locale('pt'),
  Locale('uk'),
  Locale('pl'),
  Locale('tr'),
  Locale('it'),
  Locale('zh'),
  Locale('ja'),
  Locale('ko'),
  Locale('vi'),
  Locale('ar'),
  Locale('hi'),
];

const Map<String, String> kLocaleLabels = {
  'system': 'System',
  'en': 'English',
  'ru': 'Русский',
  'es': 'Español',
  'de': 'Deutsch',
  'fr': 'Français',
  'pt': 'Português',
  'uk': 'Українська',
  'pl': 'Polski',
  'tr': 'Türkçe',
  'it': 'Italiano',
  'zh': '中文',
  'ja': '日本語',
  'ko': '한국어',
  'vi': 'Tiếng Việt',
  'ar': 'العربية',
  'hi': 'हिन्दी',
};
