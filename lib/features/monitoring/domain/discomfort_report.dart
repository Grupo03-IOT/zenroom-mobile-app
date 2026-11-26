/// Reporte de incomodidad de un miembro con la lectura de la sala en ese momento (US27, US28).
enum DiscomfortCategory {
  noise('NOISE', 'Too noisy'),
  warm('WARM', 'Too warm'),
  cold('COLD', 'Too cold');

  const DiscomfortCategory(this.code, this.label);
  final String code;

  /// Texto fuente de la interfaz; se traduce con `tr`.
  final String label;

  static DiscomfortCategory fromCode(String? code) =>
      DiscomfortCategory.values.firstWhere(
        (category) => category.code == code?.toUpperCase(),
        orElse: () => DiscomfortCategory.noise,
      );
}

/// Error de negocio de los reportes con un mensaje apto para la interfaz.
class DiscomfortException implements Exception {
  const DiscomfortException(this.message);
  final String message;
  @override
  String toString() => message;
}

class DiscomfortComment {
  static const maxLength = 500;
}

class ReportReading {
  const ReportReading({
    this.timestamp,
    this.noise,
    this.temperature,
    this.humidity,
    this.occupancy,
  });
  final DateTime? timestamp;
  final double? noise;
  final double? temperature;
  final double? humidity;
  final double? occupancy;

  factory ReportReading.fromJson(Map<String, dynamic> json) => ReportReading(
    timestamp: DateTime.tryParse('${json['ts'] ?? ''}'),
    noise: (json['laeq'] as num?)?.toDouble(),
    temperature: (json['tempC'] as num?)?.toDouble(),
    humidity: (json['rhPct'] as num?)?.toDouble(),
    occupancy: (json['occupiedPct'] as num?)?.toDouble(),
  );
}

class DiscomfortReport {
  const DiscomfortReport({
    required this.id,
    required this.roomId,
    required this.roomCode,
    required this.category,
    this.comment,
    this.createdAt,
    this.reading,
  });
  final String id;
  final String roomId;
  final String roomCode;
  final DiscomfortCategory category;
  final String? comment;
  final DateTime? createdAt;
  final ReportReading? reading;

  factory DiscomfortReport.fromJson(Map<String, dynamic> json) =>
      DiscomfortReport(
        id: '${json['id']}',
        roomId: '${json['roomId'] ?? ''}',
        roomCode: '${json['roomCode'] ?? ''}',
        category: DiscomfortCategory.fromCode(json['category'] as String?),
        comment: (json['comment'] as String?)?.trim().isEmpty ?? true
            ? null
            : json['comment'] as String,
        createdAt: DateTime.tryParse('${json['createdAt'] ?? ''}'),
        reading: json['reading'] is Map
            ? ReportReading.fromJson(
                Map<String, dynamic>.from(json['reading'] as Map),
              )
            : null,
      );
}

/// Conteo de reportes por sala y motivo para priorizar (US28).
class DiscomfortSummary {
  const DiscomfortSummary({
    required this.roomId,
    required this.roomCode,
    required this.noise,
    required this.warm,
    required this.cold,
    required this.total,
  });
  final String roomId;
  final String roomCode;
  final int noise;
  final int warm;
  final int cold;
  final int total;

  factory DiscomfortSummary.fromJson(Map<String, dynamic> json) =>
      DiscomfortSummary(
        roomId: '${json['roomId'] ?? ''}',
        roomCode: '${json['roomCode'] ?? ''}',
        noise: (json['noise'] as num?)?.toInt() ?? 0,
        warm: (json['warm'] as num?)?.toInt() ?? 0,
        cold: (json['cold'] as num?)?.toInt() ?? 0,
        total: (json['total'] as num?)?.toInt() ?? 0,
      );
}

abstract interface class DiscomfortRepository {
  /// Lanza [DiscomfortException] si el mismo motivo se reporto hace menos de 10 minutos.
  Future<DiscomfortReport> file(
    String token, {
    required String roomId,
    required DiscomfortCategory category,
    String? comment,
  });
  Future<List<DiscomfortReport>> reports(
    String token, {
    String? roomId,
    DiscomfortCategory? category,
    DateTime? from,
    DateTime? to,
  });
  Future<List<DiscomfortReport>> mine(String token);
  Future<List<DiscomfortSummary>> summary(
    String token, {
    DateTime? from,
    DateTime? to,
  });
}
