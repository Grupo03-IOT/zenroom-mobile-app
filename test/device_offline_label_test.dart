import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenroom/app/app_controller.dart';
import 'package:zenroom/app/screens/admin_screens.dart';
import 'package:zenroom/core/l10n/zenroom_i18n.dart';
import 'package:zenroom/features/alerting/domain/alert.dart';
import 'package:zenroom/features/alerting/domain/alert_repository.dart';
import 'package:zenroom/features/alerting/infrastructure/demo_alert_repository.dart';
import 'package:zenroom/features/identity/domain/session.dart';

class _OfflineAlerts extends DemoAlertRepository {
  @override
  Future<List<Alert>> alerts(
    String token, {
    AlertStatus? status,
    String? roomId,
    DateTime? from,
    DateTime? to,
    bool? hasAction,
  }) async => [
    Alert(
      id: 'offline-1',
      roomId: 'booth-1',
      roomCode: 'booth-1',
      rule: 'device_offline',
      severity: 'warning',
      message: 'Device offline',
      status: AlertStatus.open,
      openedAt: DateTime.now().toUtc().subtract(const Duration(minutes: 3)),
    ),
  ];
}

void main() {
  testWidgets('alerts list labels the device_offline rule', (tester) async {
    final controller = AppController(alerts: _OfflineAlerts());
    addTearDown(controller.dispose);
    await controller.signIn('admin@example.com', '', demoRole: UserRole.admin);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, home) =>
            ZenroomI18n(language: AppLanguage.english, child: home!),
        home: Scaffold(
          body: AnimatedBuilder(
            animation: controller,
            builder: (_, _) => AdminAlertsScreen(controller: controller),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Device offline'), findsWidgets);
    expect(find.text('device_offline'), findsNothing);
  });
}
