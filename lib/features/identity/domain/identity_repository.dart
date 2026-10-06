import 'session.dart';

abstract interface class IdentityRepository {
  Future<Session> signIn(String email, String password);
  Future<void> signUp(String name, String email, String password);
  Future<String> createEdgeCredential(String token, String code);
}
