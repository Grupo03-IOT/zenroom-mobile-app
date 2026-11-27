import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zenroom/app/app_controller.dart';
import 'package:zenroom/core/l10n/zenroom_i18n.dart';
import 'package:zenroom/core/network/cloud_client.dart';
import 'package:zenroom/features/identity/infrastructure/cloud_identity_repository.dart';

http.Response _error(int status, String code) => http.Response(
  jsonEncode({'code': code, 'message': 'x', 'path': '/p', 'errors': []}),
  status,
);

CloudIdentityRepository _identity(http.Response response) =>
    CloudIdentityRepository(
      CloudClient(httpClient: MockClient((_) async => response)),
    );

void main() {
  group('login error mapping', () {
    test('401 IAM_INVALID_CREDENTIALS maps to the invalid credentials message',
        () async {
      await expectLater(
        _identity(_error(401, 'IAM_INVALID_CREDENTIALS')).signIn('a', 'b'),
        throwsA(
          isA<CloudException>()
              .having((e) => e.message, 'message', invalidCredentialsMessage)
              .having((e) => e.statusCode, 'status', 401),
        ),
      );
    });

    test('400 keeps the invalid credentials message', () async {
      await expectLater(
        _identity(_error(400, 'VALIDATION_ERROR')).signIn('a', 'b'),
        throwsA(
          isA<CloudException>().having(
            (e) => e.message,
            'message',
            invalidCredentialsMessage,
          ),
        ),
      );
    });

    test('401 IAM_ACCOUNT_DISABLED maps to the deactivated message', () async {
      await expectLater(
        _identity(_error(401, 'IAM_ACCOUNT_DISABLED')).signIn('a', 'b'),
        throwsA(
          isA<CloudException>().having(
            (e) => e.message,
            'message',
            accountDisabledMessage,
          ),
        ),
      );
    });

    test('other errors are not rewritten', () async {
      await expectLater(
        _identity(_error(500, 'INTERNAL')).signIn('a', 'b'),
        throwsA(isA<CloudException>().having((e) => e.message, 'm', 'x')),
      );
    });

    test('login 401 never fires the account disabled callback', () async {
      var fired = false;
      final client = CloudClient(
        httpClient: MockClient(
          (_) async => _error(401, 'IAM_ACCOUNT_DISABLED'),
        ),
        onAccountDisabled: () => fired = true,
      );
      await expectLater(
        CloudIdentityRepository(client).signIn('a', 'b'),
        throwsA(isA<CloudException>()),
      );
      expect(fired, isFalse);
    });
  });

  group('authenticated calls', () {
    test('401 IAM_ACCOUNT_DISABLED with a token fires the callback', () async {
      var fired = 0;
      final client = CloudClient(
        httpClient: MockClient(
          (_) async => _error(401, 'IAM_ACCOUNT_DISABLED'),
        ),
        onAccountDisabled: () => fired++,
      );
      await expectLater(
        client.request('GET', '/api/v1/rooms', token: 't'),
        throwsA(isA<CloudException>()),
      );
      expect(fired, 1);
    });

    test('other 401 codes do not fire the callback', () async {
      var fired = false;
      final client = CloudClient(
        httpClient: MockClient((_) async => _error(401, 'IAM_TOKEN_INVALID')),
        onAccountDisabled: () => fired = true,
      );
      await expectLater(
        client.request('GET', '/api/v1/rooms', token: 't'),
        throwsA(isA<CloudException>()),
      );
      expect(fired, isFalse);
    });
  });

  group('translations', () {
    test('both messages have English and Spanish texts', () {
      expect(
        translate(AppLanguage.spanish, invalidCredentialsMessage),
        invalidCredentialsMessage,
      );
      expect(
        translate(AppLanguage.english, invalidCredentialsMessage),
        'Invalid email or password.',
      );
      expect(
        translate(AppLanguage.english, accountDisabledMessage),
        'This account is deactivated. Contact an administrator.',
      );
    });
  });

  test('controller starts without a pending auth notice', () {
    final controller = AppController();
    expect(controller.authNotice, isNull);
    controller.dispose();
  });
}
