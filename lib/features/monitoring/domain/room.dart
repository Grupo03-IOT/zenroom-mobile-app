enum RoomStatus { optimal, moderate, bad, noData }

class LatestReading {
  const LatestReading({
    this.timestamp,
    this.noise,
    this.temperature,
    this.humidity,
    this.ppd,
    this.occupancy,
    this.complete = true,
  });
  final DateTime? timestamp;
  final double? noise;
  final double? temperature;
  final double? humidity;
  final double? ppd;
  final double? occupancy;
  final bool complete;

  factory LatestReading.fromJson(Map<String, dynamic> json) => LatestReading(
    timestamp: DateTime.tryParse('${json['ts'] ?? ''}'),
    noise: (json['laeq'] as num?)?.toDouble(),
    temperature: (json['tempC'] as num?)?.toDouble(),
    humidity: (json['rhPct'] as num?)?.toDouble(),
    ppd: (json['ppd'] as num?)?.toDouble(),
    occupancy: (json['occupiedPct'] as num?)?.toDouble(),
    complete: json['complete'] != false,
  );
}

class Room {
  const Room({
    required this.id,
    required this.code,
    required this.name,
    required this.floor,
    this.capacity,
    this.classified = true,
    this.latest,
  });
  final String id;
  final String code;
  final String name;
  final String floor;
  final int? capacity;
  final bool classified;
  final LatestReading? latest;

  bool get isFree => (latest?.occupancy ?? 0) < 50;
  RoomStatus get status {
    if (latest == null) return RoomStatus.noData;
    if ((latest!.noise ?? 0) >= 60 || (latest!.ppd ?? 0) >= 20)
      return RoomStatus.bad;
    if ((latest!.noise ?? 0) >= 50 || (latest!.temperature ?? 0) >= 25) {
      return RoomStatus.moderate;
    }
    return RoomStatus.optimal;
  }

  factory Room.fromJson(Map<String, dynamic> json) => Room(
    id: '${json['id'] ?? ''}',
    code: '${json['code'] ?? ''}',
    name: '${json['displayName'] ?? json['code'] ?? 'Room'}',
    floor: '${json['floor'] ?? ''}',
    capacity: (json['capacity'] as num?)?.toInt(),
    classified: json['classified'] == true,
    latest: json['latest'] is Map
        ? LatestReading.fromJson(
            Map<String, dynamic>.from(json['latest'] as Map),
          )
        : null,
  );
}

class Site {
  const Site({
    required this.id,
    required this.code,
    required this.name,
    this.address = '',
    this.timezone = 'America/Lima',
  });
  final String id;
  final String code;
  final String name;
  final String address;
  final String timezone;
  factory Site.fromJson(Map<String, dynamic> json) => Site(
    id: '${json['id'] ?? ''}',
    code: '${json['code'] ?? ''}',
    name: '${json['name'] ?? ''}',
    address: '${json['address'] ?? ''}',
    timezone: '${json['timezone'] ?? 'America/Lima'}',
  );
}

class RoomType {
  const RoomType({
    required this.id,
    required this.code,
    required this.name,
    this.description = '',
  });
  final String id;
  final String code;
  final String name;
  final String description;
  factory RoomType.fromJson(Map<String, dynamic> json) => RoomType(
    id: '${json['id'] ?? ''}',
    code: '${json['code'] ?? ''}',
    name: '${json['displayName'] ?? ''}',
    description: '${json['description'] ?? ''}',
  );
}

class Reading {
  const Reading({
    required this.timestamp,
    this.noise,
    this.temperature,
    this.humidity,
    this.occupancy,
  });
  final DateTime timestamp;
  final double? noise;
  final double? temperature;
  final double? humidity;
  final double? occupancy;
  factory Reading.fromJson(Map<String, dynamic> json) {
    final acoustic = json['acoustic'] as Map?;
    final climate = json['climate'] as Map?;
    final occupied = json['occupancy'] as Map?;
    return Reading(
      timestamp: DateTime.tryParse('${json['ts'] ?? ''}') ?? DateTime.now(),
      noise: (acoustic?['laeq'] as num?)?.toDouble(),
      temperature: (climate?['tempC'] as num?)?.toDouble(),
      humidity: (climate?['rhPct'] as num?)?.toDouble(),
      occupancy: (occupied?['occupiedPct'] as num?)?.toDouble(),
    );
  }
}
