import 'package:flutter_test/flutter_test.dart';
import 'package:zenroom/features/monitoring/domain/room.dart';

void main() {
  test('Cloud room JSON maps snake-normalized keys and comfort status', () {
    final room = Room.fromJson({
      'id': 'room-1',
      'code': 'sala-01',
      'displayName': 'Focus Room',
      'floor': '3',
      'classified': true,
      'latest': {
        'ts': '2026-10-06T10:00:00Z',
        'laeq': 51,
        'tempC': 22.8,
        'rhPct': 55,
        'occupiedPct': 0,
        'complete': true,
      }
    });
    expect(room.name, 'Focus Room');
    expect(room.status, RoomStatus.moderate);
    expect(room.isFree, isTrue);
  });

  test('a room without a reading is explicitly no data', () {
    final room = Room.fromJson({
      'id': 'room-2', 'code': 'sala-02', 'displayName': 'Lounge',
      'floor': '2', 'classified': false, 'latest': null,
    });
    expect(room.status, RoomStatus.noData);
  });
}
