import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenroom/app/app_controller.dart';
import 'package:zenroom/app/zenroom_app.dart';
import 'package:zenroom/core/l10n/language_preference.dart';
import 'package:zenroom/core/l10n/zenroom_i18n.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('starts in en_US even on a Spanish device', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('es', '419')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(
      ZenroomApp(language: await readSavedLanguage() ?? AppLanguage.english),
    );
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.locale, const Locale('en', 'US'));
    expect(find.text('Sign in'), findsWidgets);
  });

  test('the chosen language is restored on the next start', () async {
    expect(await readSavedLanguage(), isNull);

    final controller = AppController();
    addTearDown(controller.dispose);
    expect(controller.language, AppLanguage.english);

    controller.setLanguage(AppLanguage.spanish);
    await pumpEventQueue();
    expect(await readSavedLanguage(), AppLanguage.spanish);

    controller.setLanguage(AppLanguage.english);
    await pumpEventQueue();
    expect(await readSavedLanguage(), AppLanguage.english);
  });

  test('connection errors are shown in English by default', () {
    expect(
      translate(AppLanguage.english, 'No se pudo conectar con Cloud API.'),
      'Could not connect to Cloud API.',
    );
    expect(
      translate(AppLanguage.english, 'Error 503 al consultar Cloud API.'),
      'Error 503 while querying Cloud API.',
    );
  });
}
