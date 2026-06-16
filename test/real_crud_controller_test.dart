import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tubes_apb_mobile/src/data/api_client.dart';
import 'package:tubes_apb_mobile/src/data/app_controller.dart';
import 'package:tubes_apb_mobile/src/data/local_services.dart';
import 'package:tubes_apb_mobile/src/domain/models.dart';

void main() {
  test('real mode snapshot respects backend pagination limit contract', () async {
    final seen = <String>[];
    final controller = AppController(
      persistence: MemoryPersistenceService(),
      notifications: RecordingNotificationGateway(),
      imagePicker: FixedImagePickerGateway(null),
      apiClient: ApiClient(
        baseUrl: 'https://api.finu.test',
        client: MockClient((request) async {
          seen.add(request.url.toString());
          final pathAndQuery = request.url.hasQuery
              ? '${request.url.path}?${request.url.query}'
              : request.url.path;
          return switch (pathAndQuery) {
            '/profile' => http.Response(
              '{"data":{"id":"user-1","name":"Alya","email":"alya@example.com","budgetNotificationEnabled":true}}',
              200,
            ),
            '/categories?type=expense' => http.Response(
              '{"data":[{"id":"cat-food","type":"expense","name":"Makan","iconKey":"food","monthlyBudget":100000,"savingTarget":null}]}',
              200,
            ),
            '/categories?type=saving' => http.Response('{"data":[]}', 200),
            '/transactions?limit=100' => http.Response(
              '{"data":{"items":[{"id":"tx-1","name":"Makan","amount":25000,"categoryId":"cat-food","date":"2026-04-30","note":null}]}}',
              200,
            ),
            '/savings?limit=100' => http.Response('{"data":[]}', 200),
            _ => http.Response(
              '{"error":{"code":"NOT_FOUND","message":"Unexpected route"}}',
              404,
            ),
          };
        }),
      ),
    );
    controller.tokens = const AuthTokens(
      accessToken: 'access',
      refreshToken: 'refresh',
    );
    await controller.updateConfig(
      const AppConfig(apiBaseUrl: 'https://api.finu.test'),
    );

    await controller.loadRemoteSnapshot();

    expect(
      seen,
      containsAll([
        'https://api.finu.test/transactions?limit=100',
        'https://api.finu.test/savings?limit=100',
      ]),
    );
    expect(controller.activeTransactions.single.id, 'tx-1');
  });

  test(
    'real mode category create posts API payload and upserts response',
    () async {
      late http.Request captured;
      final controller = AppController(
        persistence: MemoryPersistenceService(),
        notifications: RecordingNotificationGateway(),
        imagePicker: FixedImagePickerGateway(null),
        apiClient: ApiClient(
          baseUrl: 'https://api.finu.test',
          client: MockClient((request) async {
            captured = request;
            return http.Response(
              '{"data":{"id":"cat-api","type":"expense","name":"Kopi","iconKey":"food","monthlyBudget":100000,"savingTarget":null}}',
              201,
            );
          }),
        ),
      );
      controller.tokens = const AuthTokens(
        accessToken: 'access',
        refreshToken: 'refresh',
      );
      controller.profile = const UserProfile(
        id: 'user-1',
        name: 'Alya',
        email: 'alya@example.com',
      );
      controller.savings.add(
        SavingEntry(
          id: 'sav-income',
          type: SavingType.generalIncome,
          name: 'Pemasukan',
          amount: 1000000,
          date: DateTime(2026, 4),
        ),
      );
      await controller.updateConfig(
        const AppConfig(apiBaseUrl: 'https://api.finu.test'),
      );

      final category = await controller.saveCategory(
        type: CategoryType.expense,
        name: 'Kopi',
        iconKey: 'food',
        monthlyBudget: 100000,
      );

      expect(captured.method, 'POST');
      expect(captured.url.path, '/categories');
      expect(category.id, 'cat-api');
      expect(
        controller.expenseCategories.any((cat) => cat.id == 'cat-api'),
        isTrue,
      );
    },
  );
}
