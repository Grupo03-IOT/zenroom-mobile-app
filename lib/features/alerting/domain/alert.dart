import '../../../core/time/utc_time.dart';

/// Alerta de confort abierta por el Edge y guardada en Cloud (US20, US21, US22, US36, US37).
enum AlertStatus {
  open('OPEN'),
  acknowledged('ACKNOWLEDGED'),
  closed('CLOSED');

  const AlertStatus(this.code);
  final String code;

  static AlertStatus fromCode(String? code) => AlertStatus.values.firstWhere(
    (status) => status.code == code?.toUpperCase(),
    orElse: () => AlertStatus.open,
  );
}

/// Error de negocio del contexto de alertas con un mensaje apto para la interfaz.
class AlertingException implements Exception {
  const AlertingException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Regla de la accion correctiva: obligatoria, de 3 a 500 caracteres.
class CorrectiveAction {
  static const minLength = 3;
  static const maxLength = 500;

  /// Devuelve el mensaje de error, o null si el texto es valido.
  static String? validate(String text) {
    final length = text.trim().length;
    if (length < minLength || length > maxLength) {
      return 'The corrective action must have between 3 and 500 characters.';
    }
    return null;
  }
}

class Alert {
  const Alert({
    required this.id,
    required this.roomId,
    required this.roomCode,
    required this.rule,
    required this.severity,
    required this.message,
    required this.status,
    this.value,
    this.openedAt,
    this.closedAt,
    this.closedBy,
    this.acknowledgedAt,
    this.acknowledgedBy,
    this.correctiveAction,
  });

  final String id;
  final String roomId;
  final String roomCode;
  final String rule;
  final String severity;
  final String message;
  final AlertStatus status;
  final double? value;
  final DateTime? openedAt;
  final DateTime? closedAt;
  final String? closedBy;
  final DateTime? acknowledgedAt;
  final String? acknowledgedBy;
  final String? correctiveAction;

  bool get isOpen => status == AlertStatus.open;
  bool get isNoise => rule == 'sustained_noise';

  /// Tiempo que la condicion lleva (o llevo) activa.
  Duration? durationAt(DateTime now) {
    final start = openedAt;
    if (start == null) return null;
    return (closedAt ?? now).difference(start);
  }

  factory Alert.fromJson(Map<String, dynamic> json) => Alert(
    id: '${json['id']}',
    roomId: '${json['roomId'] ?? ''}',
    roomCode: '${json['roomCode'] ?? ''}',
    rule: '${json['rule'] ?? ''}',
    severity: '${json['severity'] ?? 'warning'}',
    message: '${json['message'] ?? ''}',
    status: AlertStatus.fromCode(json['status'] as String?),
    value: (json['value'] as num?)?.toDouble(),
    openedAt: _date(json['openedAt']),
    closedAt: _date(json['closedAt']),
    closedBy: json['closedBy'] as String?,
    acknowledgedAt: _date(json['acknowledgedAt']),
    acknowledgedBy: json['acknowledgedBy'] as String?,
    correctiveAction: json['correctiveAction'] as String?,
  );

  Alert copyWith({
    AlertStatus? status,
    DateTime? acknowledgedAt,
    String? acknowledgedBy,
    String? correctiveAction,
  }) => Alert(
    id: id,
    roomId: roomId,
    roomCode: roomCode,
    rule: rule,
    severity: severity,
    message: message,
    status: status ?? this.status,
    value: value,
    openedAt: openedAt,
    closedAt: closedAt,
    closedBy: closedBy,
    acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
    acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
    correctiveAction: correctiveAction ?? this.correctiveAction,
  );

  static DateTime? _date(dynamic value) => parseUtc(value);
}
