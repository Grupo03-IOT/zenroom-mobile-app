import '../../../core/network/cloud_client.dart';
import '../domain/alert.dart';
import '../domain/alert_repository.dart';

/// Alertas de Cloud (PLAN-01 §3 «Cloud → apps»). Rol ADMIN.
class CloudAlertRepository implements AlertRepository {
  CloudAlertRepository(this.client);
  final CloudClient client;

  static const _base = '/api/v1/alerts';

  @override
  Future<List<Alert>> alerts(
    String token, {
    AlertStatus? status,
    String? roomId,
    DateTime? from,
    DateTime? to,
    bool? hasAction,
  }) async {
    final query = <String, String>{
      if (status != null) 'status': status.code,
      if (roomId != null && roomId.isNotEmpty) 'room_id': roomId,
      if (from != null) 'from': from.toUtc().toIso8601String(),
      if (to != null) 'to': to.toUtc().toIso8601String(),
      if (hasAction != null) 'has_action': '$hasAction',
    };
    final path = Uri(
      path: _base,
      queryParameters: query.isEmpty ? null : query,
    ).toString();
    final data = await client.request('GET', path, token: token);
    return (data as List? ?? const [])
        .map((item) => Alert.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  @override
  Future<Alert> alert(String token, String id) async => Alert.fromJson(
    Map<String, dynamic>.from(
      await client.request(
            'GET',
            '$_base/${Uri.encodeComponent(id)}',
            token: token,
          )
          as Map,
    ),
  );

  @override
  Future<Alert> acknowledge(
    String token,
    String id,
    String correctiveAction,
  ) async {
    final error = CorrectiveAction.validate(correctiveAction);
    if (error != null) throw AlertingException(error);
    try {
      final data = await client.request(
        'PATCH',
        '$_base/${Uri.encodeComponent(id)}/acknowledge',
        token: token,
        body: {'correctiveAction': correctiveAction.trim()},
      );
      return Alert.fromJson(Map<String, dynamic>.from(data as Map));
    } on CloudException catch (error) {
      if (error.statusCode == 409) {
        throw const AlertingException(
          'This alert is no longer open. Refresh the list.',
        );
      }
      rethrow;
    }
  }
}
