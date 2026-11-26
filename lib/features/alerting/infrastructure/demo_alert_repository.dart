import '../domain/alert.dart';
import '../domain/alert_repository.dart';

/// Alertas de ejemplo en memoria para el modo demo. Sigue las mismas reglas que Cloud.
class DemoAlertRepository implements AlertRepository {
  DemoAlertRepository({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now {
    final now = _clock().toUtc();
    _items.addAll([
      Alert(
        id: 'demo-alert-1',
        roomId: 'booth-1',
        roomCode: 'booth-1',
        rule: 'sustained_noise',
        severity: 'warning',
        message: 'Noise above 60 dBA for 2 min',
        status: AlertStatus.open,
        value: 66.4,
        openedAt: now.subtract(const Duration(minutes: 7)),
      ),
      Alert(
        id: 'demo-alert-2',
        roomId: 'focus-1',
        roomCode: 'focus-1',
        rule: 'discomfort',
        severity: 'warning',
        message: 'PPD above 20 %',
        status: AlertStatus.open,
        value: 23.0,
        openedAt: now.subtract(const Duration(minutes: 29)),
      ),
      Alert(
        id: 'demo-alert-3',
        roomId: 'booth-2',
        roomCode: 'booth-2',
        rule: 'sustained_noise',
        severity: 'warning',
        message: 'Noise above 60 dBA for 2 min',
        status: AlertStatus.closed,
        value: 63.1,
        openedAt: now.subtract(const Duration(hours: 3)),
        closedAt: now.subtract(const Duration(hours: 2, minutes: 40)),
        closedBy: 'AUTO',
        acknowledgedAt: now.subtract(const Duration(hours: 2, minutes: 50)),
        correctiveAction: 'Asked the team in the booth to lower their voices.',
      ),
    ]);
  }

  final DateTime Function() _clock;
  final List<Alert> _items = [];

  @override
  Future<List<Alert>> alerts(
    String token, {
    AlertStatus? status,
    String? roomId,
    DateTime? from,
    DateTime? to,
    bool? hasAction,
  }) async {
    final result = _items.where((alert) {
      if (status != null && alert.status != status) return false;
      if (roomId != null && alert.roomId != roomId) return false;
      final opened = alert.openedAt;
      if (from != null && opened != null && opened.isBefore(from)) return false;
      if (to != null && opened != null && opened.isAfter(to)) return false;
      if (hasAction != null && (alert.correctiveAction != null) != hasAction) {
        return false;
      }
      return true;
    }).toList();
    result.sort(
      (a, b) =>
          (b.openedAt ?? DateTime(0)).compareTo(a.openedAt ?? DateTime(0)),
    );
    return result;
  }

  @override
  Future<Alert> alert(String token, String id) async =>
      _items.firstWhere((alert) => alert.id == id);

  @override
  Future<Alert> acknowledge(
    String token,
    String id,
    String correctiveAction,
  ) async {
    final error = CorrectiveAction.validate(correctiveAction);
    if (error != null) throw AlertingException(error);
    final index = _items.indexWhere((alert) => alert.id == id);
    if (index < 0 || !_items[index].isOpen) {
      throw const AlertingException(
        'This alert is no longer open. Refresh the list.',
      );
    }
    final updated = _items[index].copyWith(
      status: AlertStatus.acknowledged,
      acknowledgedAt: _clock().toUtc(),
      acknowledgedBy: 'demo',
      correctiveAction: correctiveAction.trim(),
    );
    _items[index] = updated;
    return updated;
  }
}
