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
}
