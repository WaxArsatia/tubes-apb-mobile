import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tubes_apb_mobile/src/data/api_client.dart';
import 'package:tubes_apb_mobile/src/domain/models.dart';

void main() {
  test('refreshes tokens and retries once after 401', () async {
    final seenPaths = <String>[];
    var protectedCallCount = 0;
    AuthTokens? refreshedTokens;
    final client = ApiClient(
      baseUrl: 'https://api.finu.test',
      onTokensRefreshed: (tokens) async => refreshedTokens = tokens,
      client: MockClient((request) async {
        seenPaths.add(request.url.path);
        if (request.url.path == '/profile' && protectedCallCount++ == 0) {
          return http.Response(
            '{"error":{"code":"UNAUTHENTICATED","message":"Expired"}}',
            401,
          );
        }
        if (request.url.path == '/auth/refresh') {
          return http.Response(
            '{"data":{"tokens":{"accessToken":"new-access","refreshToken":"new-refresh"}}}',
            200,
          );
        }
        return http.Response(
          '{"data":{"id":"user-1","name":"Alya","email":"alya@example.com","budgetNotificationEnabled":true}}',
          200,
        );
      }),
    )..tokens = const AuthTokens(accessToken: 'old-access', refreshToken: 'old-refresh');

    final envelope = await client.getJson('/profile');

    expect(seenPaths, ['/profile', '/auth/refresh', '/profile']);
    expect(refreshedTokens?.accessToken, 'new-access');
    expect(
      (envelope['data'] as Map<String, dynamic>)['email'],
      'alya@example.com',
    );
  });

  test(
    'profile photo upload refreshes tokens and retries once after 401',
    () async {
      final tempDir = await Directory.systemTemp.createTemp('finu-api-test-');
      final file = File('${tempDir.path}/photo.png');
      await file.writeAsBytes(<int>[137, 80, 78, 71]);
      final seenPaths = <String>[];
      final authHeaders = <String?>[];
      var uploadCallCount = 0;
      AuthTokens? refreshedTokens;

      late final MockClient mockClient;
      mockClient = MockClient((request) async {
        seenPaths.add(request.url.path);
        authHeaders.add(request.headers[HttpHeaders.authorizationHeader]);
        if (request.url.path == '/profile/photo' && uploadCallCount++ == 0) {
          return http.Response(
            '{"error":{"code":"UNAUTHENTICATED","message":"Expired"}}',
            401,
          );
        }
        if (request.url.path == '/auth/refresh') {
          return http.Response(
            '{"data":{"tokens":{"accessToken":"new-access","refreshToken":"new-refresh"}}}',
            200,
          );
        }
        return http.Response(
          '{"data":{"id":"user-1","name":"Alya","email":"alya@example.com","profilePhotoUrl":"https://cdn.finu.test/profile.png"}}',
          200,
        );
      });
      final client =
          ApiClient(
              baseUrl: 'https://api.finu.test',
              client: mockClient,
              onTokensRefreshed: (tokens) async => refreshedTokens = tokens,
            )
            ..tokens = const AuthTokens(
              accessToken: 'old-access',
              refreshToken: 'old-refresh',
            );

      try {
        final envelope = await http.runWithClient(
          () => client.uploadProfilePhoto(file.path),
          () => mockClient,
        );

        expect(seenPaths, [
          '/profile/photo',
          '/auth/refresh',
          '/profile/photo',
        ]);
        expect(refreshedTokens?.accessToken, 'new-access');
        expect(authHeaders[0], 'Bearer old-access');
        expect(authHeaders[2], 'Bearer new-access');
        expect(
          (envelope['data'] as Map<String, dynamic>)['profilePhotoUrl'],
          'https://cdn.finu.test/profile.png',
        );
      } finally {
        await tempDir.delete(recursive: true);
      }
    },
  );
}
