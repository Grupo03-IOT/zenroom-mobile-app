import '../domain/monitoring_repository.dart';
import '../domain/room.dart';

class DemoMonitoringRepository implements MonitoringRepository {
  final List<Site> _sites = [
    const Site(
      id: 'demo-site',
      code: 'miraflores',
      name: 'Miraflores Hub',
      address: 'Lima, Peru',
    ),
  ];
  final List<RoomType> _types = [
    const RoomType(
      id: 'call-booth',
      code: 'call-booth',
      name: 'Call booth',
      description: 'Private calls',
    ),
    const RoomType(
      id: 'meeting-room',
      code: 'meeting-room',
      name: 'Meeting room',
      description: 'Team meetings',
    ),
    const RoomType(
      id: 'open-area',
      code: 'open-area',
      name: 'Open area',
      description: 'Shared work',
    ),
  ];
  final List<Room> _rooms = [
    Room(
      id: 'focus-1',
      code: 'focus-1',
      name: 'Focus Room',
      floor: 'Floor 3 · open area',
      latest: LatestReading(
        timestamp: DateTime.now(),
        noise: 38,
        temperature: 22.8,
        humidity: 55,
        occupancy: 0,
      ),
    ),
    Room(
      id: 'booth-1',
      code: 'booth-1',
      name: 'Call Booth 1',
      floor: 'Floor 2 · call booth',
      latest: LatestReading(
        timestamp: DateTime.now(),
        noise: 42,
        temperature: 23.1,
        humidity: 53,
        occupancy: 0,
      ),
    ),
    Room(
      id: 'booth-2',
      code: 'booth-2',
      name: 'Call Booth 2',
      floor: 'Floor 2 · call booth',
      latest: LatestReading(
        timestamp: DateTime.now(),
        noise: 51,
        temperature: 25.4,
        humidity: 58,
        occupancy: 100,
      ),
    ),
    Room(
      id: 'meeting-a',
      code: 'meeting-a',
      name: 'Meeting Room A',
      floor: 'Floor 1 · meeting room',
      latest: LatestReading(
        timestamp: DateTime.now(),
        noise: 64,
        temperature: 24.1,
        humidity: 50,
        occupancy: 80,
      ),
    ),
    Room(
      id: 'open-north',
      code: 'open-north',
      name: 'Open Area North',
      floor: 'Floor 2 · open area',
      latest: LatestReading(
        timestamp: DateTime.now(),
        noise: 54,
        temperature: 23.5,
        humidity: 56,
        occupancy: 40,
      ),
    ),
    Room(
      id: 'lounge',
      code: 'lounge',
      name: 'Lounge',
      floor: 'Floor 1 · lounge',
      classified: false,
      latest: null,
    ),
    ...[
      (
        'meeting-b',
        'Meeting Room B',
        'Floor 2 · meeting room',
        39.0,
        22.4,
        90.0,
      ),
      (
        'open-south',
        'Open Area South',
        'Floor 1 · open area',
        43.0,
        23.0,
        70.0,
      ),
      ('room-307', 'Room 3-07', 'Floor 3 · focus room', 37.0, 22.1, 100.0),
      ('quiet-pod', 'Quiet Pod', 'Floor 3 · focus room', 35.0, 22.6, 80.0),
      (
        'workshop',
        'Workshop Room',
        'Floor 1 · meeting room',
        44.0,
        23.4,
        100.0,
      ),
      ('study', 'Study Room', 'Floor 2 · study room', 36.0, 22.2, 0.0),
    ].map(
      (data) => Room(
        id: data.$1,
        code: data.$1,
        name: data.$2,
        floor: data.$3,
        classified: data.$1 != 'room-307',
        latest: LatestReading(
          timestamp: DateTime.now(),
          noise: data.$4,
          temperature: data.$5,
          humidity: 53,
          occupancy: data.$6,
        ),
      ),
    ),
  ];
  @override
  Future<List<Room>> rooms(String token) async => List.unmodifiable(_rooms);
  @override
  Future<List<Site>> sites(String token) async => List.unmodifiable(_sites);
  @override
  Future<List<RoomType>> roomTypes(String token, String siteId) async =>
      List.unmodifiable(_types);
  @override
  Future<Room> room(String token, String id) async =>
      _rooms.firstWhere((e) => e.id == id);
  @override
  Future<List<Reading>> readings(
    String token,
    String roomId,
    DateTime from,
    DateTime to,
  ) async => List.generate(
    6,
    (i) => Reading(
      timestamp: DateTime.now().subtract(Duration(hours: 10 - i * 2)),
      noise: [38, 42, 51, 46, 40, 43][i].toDouble(),
      temperature: 22.8,
      humidity: 55,
      occupancy: 20,
    ),
  );
  @override
  Future<Site> createSite(String token, Map<String, dynamic> site) async {
    final result = Site(
      id: 'demo-${_sites.length + 1}',
      code: '${site['code']}',
      name: '${site['name']}',
      address: '${site['address'] ?? ''}',
    );
    _sites.add(result);
    return result;
  }

  @override
  Future<RoomType> createRoomType(
    String token,
    String siteId,
    Map<String, dynamic> type,
  ) async {
    final result = RoomType(
      id: 'demo-${_types.length + 1}',
      code: '${type['code']}',
      name: '${type['displayName']}',
      description: '${type['description'] ?? ''}',
    );
    _types.add(result);
    return result;
  }

  @override
  Future<Room> classifyRoom(String token, String roomId, String typeId) async {
    final index = _rooms.indexWhere((item) => item.id == roomId);
    if (index < 0) throw StateError('Room not found');
    final previous = _rooms[index];
    final updated = Room(
      id: previous.id,
      code: previous.code,
      name: previous.name,
      floor: previous.floor,
      capacity: previous.capacity,
      classified: true,
      latest: previous.latest,
    );
    _rooms[index] = updated;
    return updated;
  }
}
