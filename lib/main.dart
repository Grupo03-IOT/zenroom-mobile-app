import 'package:flutter/material.dart';
import 'app/zenroom_app.dart';
import 'core/l10n/language_preference.dart';
import 'core/l10n/zenroom_i18n.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // La app no sigue el idioma del sistema: inglés mientras no se elija otro.
  final language = await readSavedLanguage() ?? AppLanguage.english;
  runApp(ZenroomApp(language: language));
}
