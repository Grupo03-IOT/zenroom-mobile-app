import 'dart:convert';

enum UserRole { admin, member }

class Session {
  const Session({
    required this.token,
    required this.email,
    required this.name,
    required this.role,
    required this.expiresAt,
  });
  final String token;
  final String email;
  final String name;
  final UserRole role;
  final DateTime expiresAt;

  bool get isExpired => !DateTime.now().isBefore(expiresAt);

  factory Session.fromJwt(String token, int expiresIn) {
    final parts = token.split('.');
    if (parts.length < 2) throw const FormatException('Token inválido.');
    final payload =
        jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))))
            as Map<String, dynamic>;
    final roles =
        (payload['roles'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final email = '${payload['email'] ?? payload['sub'] ?? ''}';
    return Session(
      token: token,
      email: email,
      name: '${payload['name'] ?? email}',
      role: roles.contains('ADMIN') ? UserRole.admin : UserRole.member,
      expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
    );
  }
}
