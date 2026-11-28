import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenroom/app/app_controller.dart';
import 'package:zenroom/app/screens/admin_screens.dart';
import 'package:zenroom/app/screens/legal_screen.dart';
import 'package:zenroom/app/screens/member_screens.dart';
import 'package:zenroom/app/zenroom_app.dart';
import 'package:zenroom/core/l10n/zenroom_i18n.dart';
import 'package:zenroom/core/legal/legal_document.dart';
import 'package:zenroom/features/identity/domain/session.dart';

const _documents = {'Terms of Service': 'terms', 'Privacy Policy': 'privacy'};

Widget _host(AppLanguage language, Widget child) => MaterialApp(
  builder: (context, home) => ZenroomI18n(language: language, child: home!),
  home: child,
);

/// La lectura del asset es asíncrona real, fuera del reloj simulado del test.
Future<void> _waitForDocument(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final language in AppLanguage.values) {
    for (final MapEntry(key: title, value: kind) in _documents.entries) {
      testWidgets('$title renders in ${language.code}', (tester) async {
        final document = (await tester.runAsync(
          LegalDocuments.load,
        ))!.of(kind, language);

        await tester.pumpWidget(_host(language, LegalScreen(title: title)));
        await _waitForDocument(tester);

        expect(find.text(translate(language, title)), findsOneWidget);
        expect(document.title, translate(language, title));
        expect(find.text(document.effective), findsOneWidget);
        expect(
          find.text(language == AppLanguage.spanish ? 'Contenido' : 'Contents'),
          findsOneWidget,
        );
        expect(document.sections.length, 12);
        for (final section in document.sections) {
          // Una vez en el índice y otra como encabezado.
          expect(find.text(section.heading), findsNWidgets(2));
        }
        expect(find.byType(SelectionArea), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('the contents list scrolls to the chosen section', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(AppLanguage.english, const LegalScreen(title: 'Privacy Policy')),
    );
    await _waitForDocument(tester);
    final heading = find.text('Your rights').last;
    expect(tester.getTopLeft(heading).dy, greaterThan(600));

    await tester.tap(find.byKey(const ValueKey('legal-contents-rights')));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(heading).dy, lessThan(200));
  });

  testWidgets('the sign-in footer opens both documents', (tester) async {
    await tester.pumpWidget(const ZenroomApp());
    await tester.pumpAndSettle();

    for (final title in _documents.keys) {
      await tester.ensureVisible(find.text(title));
      await tester.pumpAndSettle();
      await tester.tap(find.text(title));
      await tester.pump();
      await _waitForDocument(tester);
      expect(find.byType(LegalScreen), findsOneWidget);
      expect(find.text('Effective date: November 2026'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
    }
  });

  for (final role in UserRole.values) {
    testWidgets('the ${role.name} menu opens both documents', (tester) async {
      // The existing menus draw their ListTile inside a coloured card, which
      // debug builds report; it is unrelated to the legal documents.
      final report = FlutterError.onError!;
      FlutterError.onError = (details) {
        if (!details.exceptionAsString().startsWith('ListTile background')) {
          report(details);
        }
      };

      final controller = AppController();
      addTearDown(controller.dispose);
      await controller.signIn('user@example.com', '', demoRole: role);
      await tester.pumpWidget(
        _host(
          AppLanguage.english,
          Scaffold(
            body: role == UserRole.admin
                ? AdminMoreScreen(controller: controller)
                : ProfileScreen(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final title in _documents.keys) {
        await tester.ensureVisible(find.text(title));
        await tester.pumpAndSettle();
        await tester.tap(find.text(title));
        await tester.pump();
        await _waitForDocument(tester);
        expect(find.byType(LegalScreen), findsOneWidget);
        expect(find.text('Effective date: November 2026'), findsOneWidget);

        await tester.pageBack();
        await tester.pumpAndSettle();
      }
      FlutterError.onError = report;
    });
  }
}
