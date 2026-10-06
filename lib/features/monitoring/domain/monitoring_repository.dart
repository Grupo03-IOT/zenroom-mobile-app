import 'room.dart';

abstract interface class MonitoringRepository {
  Future<List<Room>> rooms(String token);
  Future<List<Site>> sites(String token);
  Future<List<RoomType>> roomTypes(String token, String siteId);
  Future<Room> room(String token, String id);
  Future<List<Reading>> readings(
    String token,
    String roomId,
    DateTime from,
    DateTime to,
  );
  Future<Site> createSite(String token, Map<String, dynamic> site);
  Future<RoomType> createRoomType(
    String token,
    String siteId,
    Map<String, dynamic> type,
  );
  Future<Room> classifyRoom(String token, String roomId, String typeId);
}
