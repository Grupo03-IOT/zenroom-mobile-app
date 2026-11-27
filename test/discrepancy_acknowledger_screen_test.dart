import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenroom/app/app_controller.dart';
import 'package:zenroom/app/screens/admin_features.dart';
import 'package:zenroom/app/screens/admin_screens.dart';
import 'package:zenroom/core/l10n/zenroom_i18n.dart';
import 'package:zenroom/features/alerting/domain/alert.dart';
import 'package:zenroom/features/identity/domain/session.dart';
import 'package:zenroom/features/monitoring/domain/discomfort_report.dart';
import 'package:zenroom/features/monitoring/infrastructure/demo_discomfort_repository.dart';

const _flagged = DiscomfortReport(
  id: 'flagged',
  roomId: 'r1',
  roomCode: 'sala-01',
  category: DiscomfortCategory.noise,
  discrepancy: true,
  discrepancyReason: 'NOISE_WITHIN_RANGE',
);

const _plain = DiscomfortReport(
  id: 'plain',
  roomId: 'r1',
  roomCode: 'sala-01',
  category: DiscomfortCategory.warm,
);

class _FakeDiscomfortRepository extends DemoDiscomfortRepository {
  final filters = <bool>[];

  @override
  Future<List<DiscomfortReport>> reports(
    String token, {
    String? roomId,
    DiscomfortCategory? category,
    DateTime? from,
    DateTime? to,
    bool discrepancyOnly = false,
  }) async {
    filters.add(discrepancyOnly);
    return discrepancyOnly ? [_flagged] : [_flagged, _plain];
  }

  @override
  Future<List<DiscomfortSummary>> summary(
    String token, {
    DateTime? from,
    DateTime? to,
  }) async => const [
    DiscomfortSummary(
      roomId: 'r1',
      roomCode: 'sala-01',
      noise: 1,
      warm: 1,
      cold: 0,
      total: 2,
      discrepancies: 1,
    ),
  ];
}

Widget _host(Widget child, [AppLanguage language = AppLanguage.english]) =>
    MaterialApp(
      builder: (context, home) =>
          ZenroomI18n(language: language, child: home!),
      home: Scaffold(body: child),
    );

Future<AppController> _admin([DiscomfortRepository? discomfort]) async {
  final controller = AppController(discomfort: discomfort);
  addTearDown(controller.dispose);
  await controller.signIn('admin@example.com', '', demoRole: UserRole.admin);
  return controller;
}

void main() {
  for (final name in ['Ana Torres', null]) {
    testWidgets('alert detail shows the acknowledger (${name ?? 'absent'})', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final controller = await _admin();
      await tester.pumpWidget(
        _host(
          AlertDetailScreen(
            controller: controller,
            alert: Alert(
              id: 'a1',
              roomId: 'r1',
              roomCode: 'sala-01',
              rule: 'sustained_noise',
              severity: 'warning',
              message: '',
              status: AlertStatus.closed,
              closedAt: DateTime.utc(2026, 11, 27),
              acknowledgedByName: name,
              correctiveAction: 'Asked for silence',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Asked for silence'), findsOneWidget);
      expect(find.text('Acknowledged by'), findsOneWidget);
      expect(find.text(name ?? '—'), findsWidgets);
    });
  }

  testWidgets('admin reports show the badge, the count and filter', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repository = _FakeDiscomfortRepository();
    final controller = await _admin(repository);
    await tester.pumpWidget(
      _host(
        SingleChildScrollView(child: ReportsContent(controller: controller)),
        AppLanguage.spanish,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Discrepancias'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('discrepancy-badge-flagged')),
      findsOneWidget,
    );
    expect(
      find.text('Discrepancia: el ruido estaba dentro del umbral'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('discrepancy-badge-plain')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('discomfort-report-plain')),
      findsOneWidget,
    );

    final chip = find.byKey(const ValueKey('discrepancy-filter'));
    await tester.ensureVisible(chip);
    await tester.tap(chip);
    await tester.pumpAndSettle();

    expect(repository.filters, [false, true]);
    expect(find.byKey(const ValueKey('discomfort-report-plain')), findsNothing);
    expect(
      find.byKey(const ValueKey('discomfort-report-flagged')),
      findsOneWidget,
    );
  });
}
