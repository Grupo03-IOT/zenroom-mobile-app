import '../../../core/network/cloud_client.dart';

/// Estado de la flota (US34, US35, TS24), cuentas (US10) y credenciales de maquina. Todo sale de Cloud.
class CloudFleetRepository {
  CloudFleetRepository(this.client);
  final CloudClient client;

  Future<List<Map<String, dynamic>>> _list(String path, String token) async {
    final data = await client.request('GET', path, token: token);
    return (data as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> devices(String token) =>
      _list('/api/v1/devices', token);
  Future<List<Map<String, dynamic>>> edges(String token) =>
      _list('/api/v1/edges', token);
  Future<List<Map<String, dynamic>>> users(String token) =>
      _list('/api/v1/users', token);
  Future<List<Map<String, dynamic>>> credentials(String token) =>
      _list('/api/v1/credentials', token);

  Future<void> setUserActive(String token, String id, bool active) =>
      client.request('PATCH', '/api/v1/users/$id', token: token, body: {'active': active});

  Future<void> revokeCredential(String token, String id) =>
      client.request('DELETE', '/api/v1/credentials/$id', token: token);
}
