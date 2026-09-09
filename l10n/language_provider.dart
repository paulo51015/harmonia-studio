import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provedor de Estado reativo para seleção de idiomas (i18n).
class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'harmonia_selected_language';
  Locale _currentLocale = const Locale('pt', 'BR');

  Locale get currentLocale => _currentLocale;

  LanguageProvider() {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_languageKey);
      if (savedCode != null) {
        if (savedCode == 'en') {
          _currentLocale = const Locale('en', 'US');
        } else if (savedCode == 'es') {
          _currentLocale = const Locale('es', 'ES');
        } else {
          _currentLocale = const Locale('pt', 'BR');
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setLanguage(String languageCode) async {
    if (languageCode == 'en') {
      _currentLocale = const Locale('en', 'US');
    } else if (languageCode == 'es') {
      _currentLocale = const Locale('es', 'ES');
    } else {
      _currentLocale = const Locale('pt', 'BR');
    }
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
    } catch (_) {}
  }
}
