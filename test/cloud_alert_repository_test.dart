import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zenroom/core/network/cloud_client.dart';
import 'package:zenroom/features/alerting/domain/alert.dart';
import 'package:zenroom/features/alerting/infrastructure/cloud_alert_repository.dart';

const _resource = {
  'id': 'a1',
  'room_id': 'r1',
  'room_code': 'sala-03',
  'rule': 'sustained_noise',
  'severity': 'warning',
  'message': 'Noise above 60 dBA for 2 min',
  'value': 66.4,
  'status': 'OPEN',
  'opened_at': '2026-11-08T14:10:00Z',
  'closed_at': null,
  'closed_by': null,
  'acknowledged_at': null,
  'acknowledged_by': null,
  'corrective_action': null,
};

void main() {
  late List<http.Request> requests;
  late http.Response Function(http.Request) respond;
  late CloudAlertRepository repository;

  setUp(() {
    requests = [];
    respond = (_) => http.Response(jsonEncode([_resource]), 200);
    repository = CloudAlertRepository(
      CloudClient(
        httpClient: MockClient((request) async {
          requests.add(request);
          return respond(request);
        }),
      ),
    );
  });

  test('lists alerts with the contract filters and the bearer token', () async {
    final alerts = await repository.alerts(
      'tok',
      status: AlertStatus.open,
      roomId: 'r1',
      from: DateTime.utc(2026, 11, 1),
      hasAction: true,
    );
    final uri = requests.single.url;
    expect(requests.single.method, 'GET');
    expect(uri.path, '/api/v1/alerts');
    expect(uri.queryParameters, {
      'status': 'OPEN',
      'room_id': 'r1',
      'from': '2026-11-01T00:00:00.000Z',
      'has_action': 'true',
    });
    expect(requests.single.headers['Authorization'], 'Bearer tok');
    expect(alerts.single.roomCode, 'sala-03');
    expect(alerts.single.openedAt, DateTime.utc(2026, 11, 8, 14, 10));
  });

  test('lists without a query string when there are no filters', () async {
    await repository.alerts('tok');
    expect(requests.single.url.path, '/api/v1/alerts');
    expect(requests.single.url.hasQuery, isFalse);
  });

  test('acknowledge sends the corrective action in snake_case', () async {
    respond = (_) => http.Response(
      jsonEncode({
        ..._resource,
        'status': 'ACKNOWLEDGED',
        'corrective_action': 'Asked for silence',
      }),
      200,
    );
    final alert = await repository.acknowledge(
      'tok',
      'a1',
      '  Asked for silence ',
    );
    expect(requests.single.method, 'PATCH');
    expect(requests.single.url.path, '/api/v1/alerts/a1/acknowledge');
    expect(jsonDecode(requests.single.body), {
      'corrective_action': 'Asked for silence',
    });
    expect(alert.status, AlertStatus.acknowledged);
  });

  test('acknowledge rejects a short action without calling Cloud', () async {
    await expectLater(
      repository.acknowledge('tok', 'a1', 'ok'),
      throwsA(isA<AlertingException>()),
    );
    expect(requests, isEmpty);
  });

  test('409 ALERTING_ALERT_NOT_OPEN becomes a readable error', () async {
    respond = (_) => http.Response(
      jsonEncode({'code': 'ALERTING_ALERT_NOT_OPEN', 'message': 'not open'}),
      409,
    );
    await expectLater(
      repository.acknowledge('tok', 'a1', 'Asked for silence'),
      throwsA(
        isA<AlertingException>().having(
          (e) => e.message,
          'message',
          contains('no longer open'),
        ),
      ),
    );
  });
}
