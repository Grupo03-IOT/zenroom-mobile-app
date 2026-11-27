import 'package:flutter_test/flutter_test.dart';
import 'package:zenroom/app/app_controller.dart';
import 'package:zenroom/features/alerting/domain/alert.dart';
import 'package:zenroom/features/identity/domain/session.dart';
import 'package:zenroom/features/monitoring/domain/discomfort_report.dart';

void main() {
  test('admin sees the open alert count and acknowledging lowers it', () async {
    final controller = AppController();
    addTearDown(controller.dispose);
    await controller.signIn('admin@example.com', '', demoRole: UserRole.admin);
    expect(controller.openAlerts, 2);

    final open = await controller.alerts.alerts(
      controller.token,
      status: AlertStatus.open,
    );
    await expectLater(
      controller.acknowledgeAlert(open.first.id, 'no'),
      throwsA(isA<AlertingException>()),
    );
    final updated = await controller.acknowledgeAlert(
      open.first.id,
      'Asked for silence in the room',
    );
    expect(updated.status, AlertStatus.acknowledged);
    expect(controller.openAlerts, 1);

    final withAction = await controller.alerts.alerts(
      controller.token,
      hasAction: true,
    );
    expect(withAction.map((a) => a.id), contains(open.first.id));
    await expectLater(
      controller.acknowledgeAlert(open.first.id, 'Again, twice'),
      throwsA(isA<AlertingException>()),
    );
  });

  test(
    'member files a report and the same reason is limited for 10 minutes',
    () async {
      final controller = AppController();
      addTearDown(controller.dispose);
      await controller.signIn(
        'member@example.com',
        '',
        demoRole: UserRole.member,
      );
      expect(controller.myReportCount, 0);
      final room = controller.visibleRooms.first.id;

      await controller.fileReport(
        roomId: room,
        category: DiscomfortCategory.warm,
      );
      expect(controller.myReportCount, 1);
      await expectLater(
        controller.fileReport(roomId: room, category: DiscomfortCategory.warm),
        throwsA(isA<DiscomfortException>()),
      );
      await controller.fileReport(
        roomId: room,
        category: DiscomfortCategory.cold,
      );
      expect(controller.myReportCount, 2);

      final summary = await controller.discomfort.summary(controller.token);
      expect(summary.single.warm, 1);
      expect(summary.single.cold, 1);
      expect(summary.single.total, 2);
    },
  );
}
