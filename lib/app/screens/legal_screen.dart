import 'package:flutter/material.dart';
import '../../core/l10n/zenroom_i18n.dart';
import '../../core/theme/zenroom_theme.dart';
import '../app_controller.dart';
import '../widgets/zen_widgets.dart';
import 'home_shell.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.title, this.controller});
  final String title;
  final AppController? controller;
  @override
  Widget build(BuildContext context) {
    final localizedTitle = tr(context, title);
    final message = ZenroomI18n.languageOf(context) == AppLanguage.spanish
        ? 'SenseWork todavía no ha proporcionado el texto aprobado de $localizedTitle. '
              'Esta pantalla se completará cuando el equipo legal publique la versión oficial.'
        : 'SenseWork has not provided the approved $localizedTitle text yet. '
              'This screen will be completed when the legal team publishes the official version.';
    return Scaffold(
      appBar: AppBar(
        title: LText(title),
        backgroundColor: ZenColors.background,
      ),
      bottomNavigationBar: controller?.signedIn == true
          ? ZenBottomNav(controller: controller!)
          : null,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ZenCard(
          child: Text(message, style: const TextStyle(color: ZenColors.muted)),
        ),
      ),
    );
  }
}
