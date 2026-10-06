import '../../../core/network/cloud_client.dart';
import '../domain/threshold.dart';

class CloudThresholdRepository {
  CloudThresholdRepository(this.client);
  final CloudClient client;
  Future<List<Threshold>> list(String token, String typeId) async =>
      (await client.request(
                'GET',
                '/api/v1/room-types/$typeId/thresholds',
                token: token,
              )
              as List)
          .map((e) => Threshold.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
  Future<Threshold> save(
    String token,
    String typeId,
    Threshold threshold,
  ) async => Threshold.fromJson(
    Map<String, dynamic>.from(
      await client.request(
            'PUT',
            '/api/v1/room-types/$typeId/thresholds/${threshold.metric}',
            token: token,
            body: threshold.toJson(),
          )
          as Map,
    ),
  );
}
