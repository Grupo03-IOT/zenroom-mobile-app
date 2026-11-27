import '../../../core/network/cloud_client.dart';
import '../domain/discomfort_report.dart';

/// Reportes de incomodidad en Cloud (PLAN-02 §3).
class CloudDiscomfortRepository implements DiscomfortRepository {
  CloudDiscomfortRepository(this.client);
  final CloudClient client;

  static const _base = '/api/v1/discomfort-reports';

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
    try {
      final data = await client.request(
        'POST',
        _base,
        token: token,
        body: {
          'roomId': roomId,
          'category': category.code,
          if (text.isNotEmpty) 'comment': text,
        },
      );
      return DiscomfortReport.fromJson(Map<String, dynamic>.from(data as Map));
    } on CloudException catch (error) {
      if (error.code == 'MONITORING_DISCOMFORT_TOO_FREQUENT' ||
          error.statusCode == 409) {
        throw const DiscomfortException(
          'You already reported this in this room less than 10 minutes ago.',
        );
      }
      if (error.code == 'MONITORING_ROOM_NOT_FOUND' ||
          error.statusCode == 404) {
        throw const DiscomfortException('This room no longer exists.');
      }
      rethrow;
    }
  }

  @override
  Future<List<DiscomfortReport>> reports(
    String token, {
    String? roomId,
    DiscomfortCategory? category,
    DateTime? from,
    DateTime? to,
    bool discrepancyOnly = false,
  }) async => _reports(
    _path(_base, {
      if (roomId != null && roomId.isNotEmpty) 'room_id': roomId,
      if (category != null) 'category': category.code,
      if (discrepancyOnly) 'discrepancy': 'true',
      ..._range(from, to),
    }),
    token,
  );

  @override
  Future<List<DiscomfortReport>> mine(String token) =>
      _reports('$_base/mine', token);

  @override
  Future<List<DiscomfortSummary>> summary(
    String token, {
    DateTime? from,
    DateTime? to,
  }) async {
    final data = await client.request(
      'GET',
      _path('$_base/summary', _range(from, to)),
      token: token,
    );
    return (data as List? ?? const [])
        .map(
          (item) => DiscomfortSummary.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<List<DiscomfortReport>> _reports(String path, String token) async {
    final data = await client.request('GET', path, token: token);
    return (data as List? ?? const [])
        .map(
          (item) =>
              DiscomfortReport.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  static Map<String, String> _range(DateTime? from, DateTime? to) => {
    if (from != null) 'from': from.toUtc().toIso8601String(),
    if (to != null) 'to': to.toUtc().toIso8601String(),
  };

  static String _path(String path, Map<String, String> query) =>
      Uri(path: path, queryParameters: query.isEmpty ? null : query).toString();
}
