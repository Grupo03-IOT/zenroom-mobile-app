import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zenroom/core/network/cloud_client.dart';
import 'package:zenroom/features/monitoring/domain/discomfort_report.dart';
import 'package:zenroom/features/monitoring/infrastructure/cloud_discomfort_repository.dart';

const _report = {
  'id': 'd1',
  'room_id': 'r1',
  'room_code': 'sala-03',
  'user_id': 'u1',
  'category': 'WARM',
  'comment': 'Hace calor cerca de la ventana',
  'created_at': '2026-11-08T14:10:00Z',
  'reading': {
    'ts': '2026-11-08T14:09:00Z',
    'laeq': 52.1,
    'temp_c': 24.9,
    'rh_pct': 58.0,
    'occupied_pct': 100.0,
  },
};

void main() {
  late List<http.Request> requests;
  late http.Response Function(http.Request) respond;
  late CloudDiscomfortRepository repository;

  setUp(() {
    requests = [];
    respond = (_) => http.Response(jsonEncode(_report), 201);
    repository = CloudDiscomfortRepository(
      CloudClient(
        httpClient: MockClient((request) async {
          requests.add(request);
          return respond(request);
        }),
      ),
    );
  });

  test('file posts room, category code and comment', () async {
    final report = await repository.file(
      'tok',
      roomId: 'r1',
      category: DiscomfortCategory.warm,
      comment: ' Hace calor cerca de la ventana ',
    );
    expect(requests.single.method, 'POST');
    expect(requests.single.url.path, '/api/v1/discomfort-reports');
    expect(jsonDecode(requests.single.body), {
      'room_id': 'r1',
      'category': 'WARM',
      'comment': 'Hace calor cerca de la ventana',
    });
    expect(report.category, DiscomfortCategory.warm);
    expect(report.reading?.temperature, 24.9);
    expect(report.reading?.humidity, 58.0);
    expect(report.reading?.occupancy, 100.0);
    expect(report.reading?.noise, 52.1);
  });

  test('file omits an empty comment', () async {
    await repository.file(
      'tok',
      roomId: 'r1',
      category: DiscomfortCategory.noise,
      comment: '   ',
    );
    expect(jsonDecode(requests.single.body), {
      'room_id': 'r1',
      'category': 'NOISE',
    });
  });

  test('file rejects a comment over 500 characters locally', () async {
    await expectLater(
      repository.file(
        'tok',
        roomId: 'r1',
        category: DiscomfortCategory.cold,
        comment: 'a' * 501,
      ),
      throwsA(isA<DiscomfortException>()),
    );
    expect(requests, isEmpty);
  });

  test('409 MONITORING_DISCOMFORT_TOO_FREQUENT becomes a readable error', () async {
    respond = (_) => http.Response(
      jsonEncode({
        'code': 'MONITORING_DISCOMFORT_TOO_FREQUENT',
        'message': 'too frequent',
      }),
      409,
    );
    await expectLater(
      repository.file('tok', roomId: 'r1', category: DiscomfortCategory.warm),
      throwsA(
        isA<DiscomfortException>().having(
          (e) => e.message,
          'message',
          contains('10 minutes'),
        ),
      ),
    );
  });

  test('admin list sends filters; mine and summary use their paths', () async {
    respond = (request) => request.url.path.endsWith('/summary')
        ? http.Response(
            jsonEncode([
              {
                'room_id': 'r1',
                'room_code': 'sala-03',
                'noise': 3,
                'warm': 5,
                'cold': 0,
                'total': 8,
              },
            ]),
            200,
          )
        : http.Response(
            jsonEncode([
              _report,
              {..._report, 'reading': null},
            ]),
            200,
          );

    final list = await repository.reports(
      'tok',
      roomId: 'r1',
      category: DiscomfortCategory.warm,
    );
    expect(requests.last.url.path, '/api/v1/discomfort-reports');
    expect(requests.last.url.queryParameters, {
      'room_id': 'r1',
      'category': 'WARM',
    });
    expect(list, hasLength(2));
    expect(list.last.reading, isNull);

    await repository.mine('tok');
    expect(requests.last.url.path, '/api/v1/discomfort-reports/mine');

    final summary = await repository.summary('tok');
    expect(requests.last.url.path, '/api/v1/discomfort-reports/summary');
    expect(summary.single.warm, 5);
    expect(summary.single.total, 8);
  });
}
