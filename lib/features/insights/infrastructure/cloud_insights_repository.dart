import '../../../core/network/cloud_client.dart';

class CloudInsightsRepository {
  CloudInsightsRepository(this.client);
  final CloudClient client;
  Future<Map<String, dynamic>> roomInsights(
    String token,
    String roomId,
    DateTime from,
    DateTime to,
  ) async {
    final query = Uri(
      queryParameters: {
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
      },
    ).query;
    return Map<String, dynamic>.from(
      await client.request(
            'GET',
            '/api/v1/insights/rooms/$roomId?$query',
            token: token,
          )
          as Map,
    );
  }
}
