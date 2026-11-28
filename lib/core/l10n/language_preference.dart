import 'package:shared_preferences/shared_preferences.dart';

import 'zenroom_i18n.dart';

const languagePreferenceKey = 'sensework-language';

/// Idioma que el usuario eligió; null si nunca eligió uno.
Future<AppLanguage?> readSavedLanguage() async {
  try {
    final preferences = await SharedPreferences.getInstance();
    return switch (preferences.getString(languagePreferenceKey)) {
      'es' => AppLanguage.spanish,
      'en' => AppLanguage.english,
      _ => null,
    };
  } catch (_) {
    return null; // Sin almacenamiento se usa el idioma por defecto.
  }
}

Future<void> saveLanguage(AppLanguage language) async {
  try {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(languagePreferenceKey, language.code);
  } catch (_) {
    // La elección se mantiene mientras la app está abierta.
  }
}
