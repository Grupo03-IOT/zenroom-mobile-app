import '../../../core/network/cloud_client.dart';
import '../domain/monitoring_repository.dart';
import '../domain/room.dart';

class CloudMonitoringRepository implements MonitoringRepository {
  CloudMonitoringRepository(this.client);
  final CloudClient client;
  @override
  Future<List<Room>> rooms(String token) async =>
      (await client.request('GET', '/api/v1/rooms', token: token) as List)
          .map((e) => Room.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
  @override
  Future<List<Site>> sites(String token) async =>
      (await client.request('GET', '/api/v1/sites', token: token) as List)
          .map((e) => Site.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
  @override
  Future<List<RoomType>> roomTypes(String token, String siteId) async =>
      (await client.request(
                'GET',
                '/api/v1/sites/$siteId/room-types',
                token: token,
              )
              as List)
          .map((e) => RoomType.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
  @override
  Future<Room> room(String token, String id) async => Room.fromJson(
    Map<String, dynamic>.from(
      await client.request('GET', '/api/v1/rooms/$id', token: token) as Map,
    ),
  );
  @override
  Future<List<Reading>> readings(
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
    return (await client.request(
              'GET',
              '/api/v1/rooms/$roomId/readings?$query',
              token: token,
            )
            as List)
        .map((e) => Reading.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<Site> createSite(String token, Map<String, dynamic> site) async =>
      Site.fromJson(
        Map<String, dynamic>.from(
          await client.request(
                'POST',
                '/api/v1/sites',
                token: token,
                body: site,
              )
              as Map,
        ),
      );
  @override
  Future<RoomType> createRoomType(
    String token,
    String siteId,
    Map<String, dynamic> type,
  ) async => RoomType.fromJson(
    Map<String, dynamic>.from(
      await client.request(
            'POST',
            '/api/v1/sites/$siteId/room-types',
            token: token,
            body: type,
          )
          as Map,
    ),
  );
  @override
  Future<Room> classifyRoom(String token, String roomId, String typeId) async =>
      Room.fromJson(
        Map<String, dynamic>.from(
          await client.request(
                'PATCH',
                '/api/v1/rooms/$roomId',
                token: token,
                body: {'roomTypeId': typeId},
              )
              as Map,
        ),
      );
}
