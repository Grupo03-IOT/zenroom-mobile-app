import 'alert.dart';

abstract interface class AlertRepository {
  /// Lista mas reciente primero. Todos los filtros son opcionales.
  Future<List<Alert>> alerts(
    String token, {
    AlertStatus? status,
    String? roomId,
    DateTime? from,
    DateTime? to,
    bool? hasAction,
  });
  Future<Alert> alert(String token, String id);

  /// Solo desde OPEN. Lanza [AlertingException] si la alerta ya no esta abierta.
  Future<Alert> acknowledge(String token, String id, String correctiveAction);
}
