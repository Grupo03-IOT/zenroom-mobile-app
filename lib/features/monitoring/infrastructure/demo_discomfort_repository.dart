import '../domain/discomfort_report.dart';

/// Reportes de ejemplo en memoria para el modo demo, con el mismo limite de frecuencia que Cloud.
class DemoDiscomfortRepository implements DiscomfortRepository {
  DemoDiscomfortRepository({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  static const minInterval = Duration(minutes: 10);

  final DateTime Function() _clock;
  final List<DiscomfortReport> _items = [];
  int _sequence = 0;

  @override
  Future<DiscomfortReport> file(
    String token, {
    required String roomId,
    required DiscomfortCategory category,
    String? comment,
  }) async {
    final text = comment?.trim() ?? '';
    if (text.length > DiscomfortComment.maxLength) {
      throw const DiscomfortException(
        'The comment can have up to 500 characters.',
      );
    }
    final now = _clock().toUtc();
    final tooFrequent = _items.any(
      (report) =>
          report.roomId == roomId &&
          report.category == category &&
          report.createdAt != null &&
          now.difference(report.createdAt!) < minInterval,
    );
    if (tooFrequent) {
      throw const DiscomfortException(
        'You already reported this in this room less than 10 minutes ago.',
      );
    }
    final report = DiscomfortReport(
      id: 'demo-report-${++_sequence}',
      roomId: roomId,
      roomCode: roomId,
      category: category,
      comment: text.isEmpty ? null : text,
      createdAt: now,
    );
    _items.insert(0, report);
    return report;
  }

  @override
  Future<List<DiscomfortReport>> reports(
    String token, {
    String? roomId,
    DiscomfortCategory? category,
    DateTime? from,
    DateTime? to,
    bool discrepancyOnly = false,
  }) async => _items
      .where(
        (report) =>
            (roomId == null || report.roomId == roomId) &&
            (category == null || report.category == category) &&
            (!discrepancyOnly || report.discrepancy),
      )
      .toList();

  @override
  Future<List<DiscomfortReport>> mine(String token) async => List.of(_items);

  @override
  Future<List<DiscomfortSummary>> summary(
    String token, {
    DateTime? from,
    DateTime? to,
  }) async {
    final byRoom = <String, List<DiscomfortReport>>{};
    for (final report in _items) {
      byRoom.putIfAbsent(report.roomId, () => []).add(report);
    }
    int count(List<DiscomfortReport> list, DiscomfortCategory category) =>
        list.where((report) => report.category == category).length;
    final result = byRoom.entries
        .map(
          (entry) => DiscomfortSummary(
            roomId: entry.key,
            roomCode: entry.value.first.roomCode,
            noise: count(entry.value, DiscomfortCategory.noise),
            warm: count(entry.value, DiscomfortCategory.warm),
            cold: count(entry.value, DiscomfortCategory.cold),
            total: entry.value.length,
            discrepancies: entry.value.where((r) => r.discrepancy).length,
          ),
        )
        .toList();
    result.sort((a, b) => b.total.compareTo(a.total));
    return result;
  }
}
