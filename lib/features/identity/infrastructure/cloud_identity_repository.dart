import '../../../core/network/cloud_client.dart';
import '../domain/identity_repository.dart';
import '../domain/session.dart';

class CloudIdentityRepository implements IdentityRepository {
  CloudIdentityRepository(this.client);
  final CloudClient client;

  @override
  Future<Session> signIn(String email, String password) async {
    final json =
        await client.request(
              'POST',
              '/api/v1/auth/login',
              body: {'email': email, 'password': password},
            )
            as Map;
    return Session.fromJwt(
      '${json['accessToken']}',
      (json['expiresIn'] as num?)?.toInt() ?? 3600,
    );
  }

  @override
  Future<void> signUp(String name, String email, String password) async {
    await client.request(
      'POST',
      '/api/v1/users',
      body: {'displayName': name, 'email': email, 'password': password},
    );
  }

  @override
  Future<String> createEdgeCredential(String token, String code) async {
    final json =
        await client.request(
              'POST',
              '/api/v1/credentials',
              token: token,
              body: {
                'code': code,
                'scopes': ['readings:write', 'thresholds:read', 'edges:heartbeat'],
              },
            )
            as Map;
    return '${json['apiKey'] ?? ''}';
  }
}
