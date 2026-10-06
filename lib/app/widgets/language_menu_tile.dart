import 'package:flutter/material.dart';

import '../../core/l10n/zenroom_i18n.dart';
import '../../core/theme/zenroom_theme.dart';
import '../app_controller.dart';
import 'zen_widgets.dart';

class LanguageMenuTile extends StatelessWidget {
  const LanguageMenuTile({super.key, required this.controller, this.iconColor});

  final AppController controller;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: ZenIcon('help', size: 20, color: iconColor),
    title: const LText('Language'),
    trailing: Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: ZenColors.background,
        border: Border.all(color: ZenColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final language in [AppLanguage.spanish, AppLanguage.english])
            Semantics(
              button: true,
              selected: controller.language == language,
              label: language == AppLanguage.spanish ? 'Español' : 'English',
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: () => controller.setLanguage(language),
                child: Container(
                  width: 37,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: controller.language == language
                        ? ZenColors.blue
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    language == AppLanguage.spanish ? 'ES' : 'EN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: controller.language == language
                          ? Colors.white
                          : ZenColors.muted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
    shape: const Border(bottom: BorderSide(color: ZenColors.border)),
  );
}
