import 'package:flutter_test/flutter_test.dart';
import 'package:zenroom/app/widgets/zen_widgets.dart';
import 'package:zenroom/core/time/utc_time.dart';
import 'package:zenroom/features/alerting/domain/alert.dart';

void main() {
  test('timestamps with Z, offset or no zone are all read as UTC instants', () {
    final z = parseUtc('2026-11-27T16:59:00Z')!;
    expect(z.isUtc, isTrue);
    expect(parseUtc('2026-11-27T16:59:00'), z);
    expect(parseUtc('2026-11-27T11:59:00-05:00'), z);
    expect(parseUtc(null), isNull);
    expect(parseUtc(''), isNull);
    expect(parseUtc('nope'), isNull);
  });

  test('alert times are displayed in the device local time', () {
    final alert = Alert.fromJson({
      'id': '1', 'rule': 'thermal_discomfort', 'status': 'OPEN',
      'openedAt': '2026-11-27T16:59:00',
    });
    final local = alert.openedAt!.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    expect(
      formatLocalDateTime(alert.openedAt),
      '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}',
    );
    expect(alert.openedAt!.isUtc, isTrue);
  });
}
