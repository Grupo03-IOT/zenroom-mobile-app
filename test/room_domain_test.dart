import 'package:flutter_test/flutter_test.dart';
import 'package:zenroom/features/monitoring/domain/room.dart';

void main() {
  _reasonTests();
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

  test('latest reading exposes a separate temperature forecast', () {
    final room = Room.fromJson({
      'id': 'room-3', 'code': 'sala-03', 'displayName': 'Studio',
      'floor': '1', 'classified': true,
      'latest': {
        'ts': '2026-10-06T10:00:00Z',
        'laeq': 42,
        'tempC': 23.2,
        'rhPct': 52,
        'occupiedPct': 70,
        'complete': true,
        'forecast': {
          'probability': 0.91,
          'horizonMin': 15,
          'temperatureLimitC': 25.0,
          'modelVersion': 'zenroom-5x16x16-v1',
          'generatedAt': '2026-10-06T10:00:00Z',
        },
      },
    });

    expect(room.latest?.forecast?.probability, 0.91);
    expect(room.latest?.forecast?.horizonMin, 15);
    expect(room.status, RoomStatus.optimal);
  });
}

void _reasonTests() {
  Room room(Map<String, dynamic> latest) => Room.fromJson({
    'id': 'r', 'code': 'sala-03', 'displayName': 'Sala 03', 'floor': '1',
    'classified': true, 'latest': latest,
  });

  test('attention reason follows the metric, not a fixed noise sentence', () {
    final thermal = room({'laeq': 48, 'tempC': 29.4, 'ppd': 45});
    expect(thermal.status, RoomStatus.bad);
    expect(thermal.attentionReason, 'Thermal discomfort (PPD above 20 %)');
    final noisy = room({'laeq': 65, 'tempC': 22, 'ppd': 5});
    expect(noisy.attentionReason, 'Noise above 60 dB(A)');
    final warm = room({'laeq': 40, 'tempC': 26, 'ppd': 10});
    expect(warm.attentionReason, 'Temperature above 25 °C');
    expect(room({'laeq': 40, 'tempC': 22, 'ppd': 5}).attentionReason, isNull);
  });
}
