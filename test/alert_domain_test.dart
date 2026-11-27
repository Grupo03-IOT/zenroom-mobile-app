import 'package:flutter_test/flutter_test.dart';
import 'package:zenroom/features/alerting/domain/alert.dart';

void main() {
  group('CorrectiveAction.validate', () {
    test('requires between 3 and 500 characters after trimming', () {
      expect(CorrectiveAction.validate('ok'), isNotNull);
      expect(CorrectiveAction.validate('   ab   '), isNotNull);
      expect(CorrectiveAction.validate('abc'), isNull);
      expect(CorrectiveAction.validate('a' * 500), isNull);
      expect(CorrectiveAction.validate('a' * 501), isNotNull);
    });
  });

  test('Alert.fromJson reads the Cloud resource', () {
    final alert = Alert.fromJson({
      'id': 'a1',
      'roomId': 'r1',
      'roomCode': 'sala-03',
      'rule': 'sustained_noise',
      'severity': 'warning',
      'message': 'Noise above 60 dBA for 2 min',
      'value': 66.4,
      'status': 'ACKNOWLEDGED',
      'openedAt': '2026-11-08T14:10:00Z',
      'closedAt': '2026-11-08T14:25:00Z',
      'closedBy': 'AUTO',
      'acknowledgedAt': '2026-11-08T14:12:00Z',
      'correctiveAction': 'Asked for silence',
    });
    expect(alert.status, AlertStatus.acknowledged);
    expect(alert.isOpen, isFalse);
    expect(alert.isNoise, isTrue);
    expect(alert.value, 66.4);
    expect(alert.durationAt(DateTime.utc(2030)), const Duration(minutes: 15));
    expect(alert.correctiveAction, 'Asked for silence');
  });

  test('unknown status falls back to OPEN', () {
    expect(AlertStatus.fromCode(null), AlertStatus.open);
    expect(AlertStatus.fromCode('closed'), AlertStatus.closed);
  });
}
