import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenroom/app/app_controller.dart';
import 'package:zenroom/app/screens/admin_screens.dart';
import 'package:zenroom/app/screens/home_shell.dart';
import 'package:zenroom/app/screens/member_screens.dart';
import 'package:zenroom/core/l10n/zenroom_i18n.dart';
import 'package:zenroom/features/identity/domain/session.dart';

Widget _host(AppController controller, Widget child) => MaterialApp(
  builder: (context, home) =>
      ZenroomI18n(language: AppLanguage.english, child: home!),
  home: Scaffold(
    body: AnimatedBuilder(animation: controller, builder: (_, _) => child),
  ),
);

void main() {
  testWidgets('admin acknowledges an open alert with a corrective action', (
    tester,
  ) async {
    final controller = AppController();
    addTearDown(controller.dispose);
    await controller.signIn('admin@example.com', '', demoRole: UserRole.admin);

    await tester.pumpWidget(
      _host(controller, AdminAlertsScreen(controller: controller)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Active (2)'), findsOneWidget);
    expect(find.byKey(const ValueKey('live-list-items')), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('alert-acknowledge-demo-alert-1')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('acknowledge-action-input')),
      'ok',
    );
    await tester.tap(find.byKey(const ValueKey('acknowledge-submit')));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'The corrective action must have between 3 and 500 characters.',
      ),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('acknowledge-action-input')),
      'Asked the booth to lower their voices',
    );
    await tester.tap(find.byKey(const ValueKey('acknowledge-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Active (1)'), findsOneWidget);
    expect(find.byKey(const ValueKey('alert-card-demo-alert-1')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('alerts-tab-ACKNOWLEDGED')));
    await tester.pumpAndSettle();
    expect(find.text('Asked the booth to lower their voices'), findsOneWidget);
  });

  testWidgets('member sends a discomfort report', (tester) async {
    final controller = AppController();
    addTearDown(controller.dispose);
    await controller.signIn(
      'member@example.com',
      '',
      demoRole: UserRole.member,
    );

    await tester.pumpWidget(
      _host(controller, ReportScreen(controller: controller)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('report-category-WARM')));
    await tester.enterText(
      find.byKey(const ValueKey('report-comment-input')),
      'Warm near the window',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('report-send')));
    await tester.tap(find.byKey(const ValueKey('report-send')));
    await tester.pumpAndSettle();
    expect(controller.myReportCount, 1);
    expect(find.text('Report sent. Thank you.'), findsOneWidget);

    final mine = await controller.discomfort.mine(controller.token);
    expect(mine.single.comment, 'Warm near the window');
  });

  testWidgets('the Alerts tab shows a badge with the open alert count', (
    tester,
  ) async {
    final controller = AppController();
    addTearDown(controller.dispose);
    await controller.signIn('admin@example.com', '', demoRole: UserRole.admin);

    await tester.pumpWidget(
      _host(
        controller,
        Column(
          children: [
            const Spacer(),
            ZenBottomNav(controller: controller),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    final badge = tester.widget<Badge>(
      find.byKey(const ValueKey('nav-badge-alerts')),
    );
    expect(badge.isLabelVisible, isTrue);
    expect(
      find.descendant(of: find.byWidget(badge), matching: find.text('2')),
      findsOneWidget,
    );
  });

  testWidgets('empty Active tab only says there are no open alerts', (
    tester,
  ) async {
    final controller = AppController();
    addTearDown(controller.dispose);
    await controller.signIn('admin@example.com', '', demoRole: UserRole.admin);
    await tester.pumpWidget(
      _host(controller, AdminAlertsScreen(controller: controller)),
    );
    await tester.pumpAndSettle();
    for (final id in ['demo-alert-1', 'demo-alert-2']) {
      await tester.tap(find.byKey(ValueKey('alert-acknowledge-$id')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('acknowledge-action-input')),
        'Corrective action done',
      );
      await tester.tap(find.byKey(const ValueKey('acknowledge-submit')));
      await tester.pumpAndSettle();
    }
    expect(find.text('No open alerts.'), findsOneWidget);
    expect(find.textContaining('thresholds'), findsNothing);
  });
}
