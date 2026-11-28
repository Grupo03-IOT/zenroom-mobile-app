import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../core/l10n/zenroom_i18n.dart';
import '../core/theme/zenroom_theme.dart';
import 'app_controller.dart';
import 'screens/auth_screen.dart';
import 'screens/home_shell.dart';

class ZenroomApp extends StatefulWidget {
  const ZenroomApp({super.key, this.language = AppLanguage.english});

  /// Idioma inicial: el que eligió el usuario o inglés.
  final AppLanguage language;

  @override
  State<ZenroomApp> createState() => _ZenroomAppState();
}

class _ZenroomAppState extends State<ZenroomApp> {
  late final AppController controller = AppController(
    language: widget.language,
  );
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<AppLanguage>(
    valueListenable: controller.languageNotifier,
    builder: (context, language, _) => MaterialApp(
      title: 'Zenroom · SenseWork',
      debugShowCheckedModeBanner: false,
      theme: zenroomTheme(),
      locale: language.locale,
      supportedLocales: [
        for (final supported in AppLanguage.values) supported.locale,
      ],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) => ZenroomI18n(
        language: language,
        child: child ?? const SizedBox.shrink(),
      ),
      home: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => controller.signedIn
            ? HomeShell(controller: controller)
            : AuthScreen(controller: controller),
      ),
    ),
  );
}
