import 'package:flutter_test/flutter_test.dart';
import 'package:zenroom/features/monitoring/domain/room.dart';

Room _room({int? capacity, required double occupied, required DateTime ts}) =>
    Room.fromJson({
      'id': 'r1',
      'code': 'sala-01',
      'displayName': 'Focus',
      'floor': '1',
      'capacity': capacity,
      'classified': true,
      'latest': {
        'ts': ts.toUtc().toIso8601String(),
        'occupiedPct': occupied,
        'complete': true,
      },
    });

void main() {
  final now = DateTime.now();
  final fresh = now.subtract(const Duration(minutes: 1));

  test('room parses capacity', () {
    expect(_room(capacity: 4, occupied: 100, ts: fresh).capacity, 4);
  });

  test('occupied and fresh shows capacity people', () {
    final room = _room(capacity: 4, occupied: 100, ts: fresh);
    expect(room.occupancyPeople(now), 4);
    expect(room.occupancyPeopleLabel(now), '4 people');
  });

  test('occupied with null capacity counts one person', () {
    final room = _room(occupied: 100, ts: fresh);
    expect(room.occupancyPeopleLabel(now), '1 person');
  });

  test('free and fresh shows 0 people', () {
    final room = _room(capacity: 4, occupied: 0, ts: fresh);
    expect(room.occupancyPeople(now), 0);
    expect(room.occupancyPeopleLabel(now), '0 people');
  });

  test('stale reading shows occupancy not available', () {
    final room = _room(
      capacity: 4,
      occupied: 100,
      ts: now.subtract(const Duration(minutes: 6)),
    );
    expect(room.occupancyPeople(now), isNull);
    expect(room.occupancyPeopleLabel(now), 'Occupancy not available');
  });
}
