import 'package:flutter_test/flutter_test.dart';
import 'package:tubes_apb_mobile/src/data/api_client.dart';
import 'package:tubes_apb_mobile/src/data/app_controller.dart';
import 'package:tubes_apb_mobile/src/data/local_services.dart';
import 'package:tubes_apb_mobile/src/domain/models.dart';

void main() {
  test('failed login resets loading state', () async {
    final controller = AppController(
      persistence: MemoryPersistenceService(),
      notifications: RecordingNotificationGateway(),
      imagePicker: FixedImagePickerGateway(null),
      apiClient: RecordingApiClient(
        baseUrl: AppConfig.defaultApiBaseUrl,
        responses: const {},
        throwingPostPaths: const {'/auth/login'},
      ),
    );

    await expectLater(
      controller.login('demo@finu.app', 'password123'),
      throwsA(isA<StateError>()),
    );

    expect(controller.loading, isFalse);
  });

  test(
    'login persists API tokens and profile, then initialize hydrates them',
    () async {
      final persistence = MemoryPersistenceService();
      final api = RecordingApiClient(
        baseUrl: AppConfig.defaultApiBaseUrl,
        responses: {
          '/auth/login': {
            'data': {
              'tokens': {
                'accessToken': 'api-access',
                'refreshToken': 'api-refresh',
              },
              'user': {
                'id': 'user-1',
                'name': 'Alya Finu',
                'email': 'demo@finu.app',
              },
            },
          },
        },
        getResponses: _snapshotResponses(),
      );
      final controller = AppController(
        persistence: persistence,
        notifications: RecordingNotificationGateway(),
        imagePicker: FixedImagePickerGateway(null),
        apiClient: api,
      );

      await controller.login('demo@finu.app', 'password123');

      expect(persistence.storedTokens?.accessToken, 'api-access');
      expect(persistence.storedProfile?.email, 'demo@finu.app');

      final restored = AppController(
        persistence: persistence,
        notifications: RecordingNotificationGateway(),
        imagePicker: FixedImagePickerGateway(null),
        apiClient: RecordingApiClient(
          baseUrl: AppConfig.defaultApiBaseUrl,
          responses: const {},
          getResponses: _snapshotResponses(),
        ),
      );
      await restored.initialize();

      expect(restored.isAuthenticated, isTrue);
      expect(restored.profile?.name, 'Alya Finu');
    },
  );

  test('runtime config always resolves to production backend', () async {
    final persistence = MemoryPersistenceService();
    final controller = AppController(
      persistence: persistence,
      notifications: RecordingNotificationGateway(),
      imagePicker: FixedImagePickerGateway(null),
    );

    await controller.updateConfig(
      const AppConfig(apiBaseUrl: 'https://api.example.test'),
    );

    expect(controller.config.apiBaseUrl, AppConfig.defaultApiBaseUrl);
    expect(persistence.storedConfig?.apiBaseUrl, AppConfig.defaultApiBaseUrl);
  });

  test('default config points to deployed backend in real mode', () {
    final controller = AppController(
      persistence: MemoryPersistenceService(),
      notifications: RecordingNotificationGateway(),
      imagePicker: FixedImagePickerGateway(null),
    );

    expect(controller.config.apiBaseUrl, 'https://apb-api.denis.my.id');
  });

  test(
    'enabling notification requests permission and persists profile',
    () async {
      final persistence = MemoryPersistenceService();
      final notifications = RecordingNotificationGateway();
      final controller = AppController(
        persistence: persistence,
        notifications: notifications,
        imagePicker: FixedImagePickerGateway(null),
        apiClient: RecordingApiClient(
          baseUrl: AppConfig.defaultApiBaseUrl,
          responses: {
            '/settings/notifications': {
              'data': {
                'id': 'user-1',
                'name': 'Alya Finu',
                'email': 'demo@finu.app',
                'budgetNotificationEnabled': true,
              },
            },
          },
        ),
      );
      controller.tokens = const AuthTokens(
        accessToken: 'access',
        refreshToken: 'refresh',
      );
      controller.profile = const UserProfile(
        id: 'user-1',
        name: 'Alya Finu',
        email: 'demo@finu.app',
      );

      await controller.updateNotification(true);

      expect(notifications.requestedPermission, isTrue);
      expect(persistence.storedProfile?.budgetNotificationEnabled, isTrue);
    },
  );

  test('budget warning also emits local notification when enabled', () async {
    final notifications = RecordingNotificationGateway();
    final controller = AppController(
      persistence: MemoryPersistenceService(),
      notifications: notifications,
      imagePicker: FixedImagePickerGateway(null),
      apiClient: RecordingApiClient(
        baseUrl: AppConfig.defaultApiBaseUrl,
        responses: {
          '/transactions': {
            'data': {
              'id': 'tx-budget',
              'name': 'Belanja besar',
              'amount': 2000000,
              'categoryId': 'cat-food',
              'date': '2026-04-10',
              'note': null,
              'location': null,
            },
            'warnings': [
              {'message': 'Transaksi ini akan melebihi budget category'},
            ],
          },
        },
      ),
    );
    controller.tokens = const AuthTokens(
      accessToken: 'access',
      refreshToken: 'refresh',
    );
    controller.profile = const UserProfile(
      id: 'user-1',
      name: 'Alya Finu',
      email: 'demo@finu.app',
      budgetNotificationEnabled: true,
    );
    controller.categories.add(
      const Category(
        id: 'cat-food',
        type: CategoryType.expense,
        name: 'Makan',
        iconKey: 'food',
        monthlyBudget: 1200000,
      ),
    );

    await controller.saveTransaction(
      name: 'Belanja besar',
      amount: 2000000,
      categoryId: 'cat-food',
      date: DateTime.now(),
    );

    expect(
      controller.lastWarning,
      'Transaksi ini akan melebihi budget category',
    );
    expect(notifications.messages.single, contains('Peringatan Budget'));
  });

  test('profile photo picker stores chosen profile photo path', () async {
    final persistence = MemoryPersistenceService();
    final controller = AppController(
      persistence: persistence,
      notifications: RecordingNotificationGateway(),
      imagePicker: FixedImagePickerGateway('/tmp/profile.png'),
      apiClient: RecordingApiClient(
        baseUrl: AppConfig.defaultApiBaseUrl,
        responses: const {},
      ),
    );
    controller.tokens = const AuthTokens(
      accessToken: 'access',
      refreshToken: 'refresh',
    );
    controller.profile = const UserProfile(
      id: 'user-1',
      name: 'Alya Finu',
      email: 'demo@finu.app',
    );

    await controller.pickAndUploadProfilePhoto();

    expect(controller.profile?.profilePhotoUrl, '/tmp/profile.png');
    expect(persistence.storedProfile?.profilePhotoUrl, '/tmp/profile.png');
  });

  test('resetPassword sends backend newPassword payload key', () async {
    final api = RecordingApiClient(
      baseUrl: AppConfig.defaultApiBaseUrl,
      responses: const {
        '/auth/reset-password': {'data': true},
      },
    );
    final controller = AppController(
      persistence: MemoryPersistenceService(),
      notifications: RecordingNotificationGateway(),
      imagePicker: FixedImagePickerGateway(null),
      apiClient: api,
    );

    await controller.resetPassword(
      'reset@example.com',
      'A1B2C3',
      'newpassword123',
    );

    expect(api.lastJsonBody, {
      'email': 'reset@example.com',
      'code': 'A1B2C3',
      'newPassword': 'newpassword123',
    });
    expect(api.lastJsonBody, isNot(containsPair('password', anything)));
  });

  test('saveTransaction sends location to production API', () async {
    final api = RecordingApiClient(
      baseUrl: 'https://api.finu.test',
      responses: {
        '/transactions': {
          'data': {
            'id': 'tx-location',
            'name': 'Lunch',
            'amount': 35000,
            'categoryId': 'cat-food',
            'date': '2026-04-10',
            'note': null,
            'location': {
              'latitude': -6.2,
              'longitude': 106.816666,
              'source': 'gps',
            },
          },
        },
      },
    );
    final controller = AppController(
      persistence: MemoryPersistenceService(),
      notifications: RecordingNotificationGateway(),
      imagePicker: FixedImagePickerGateway(null),
      apiClient: api,
    );
    await controller.updateConfig(
      const AppConfig(apiBaseUrl: 'https://api.finu.test'),
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
    controller.categories.add(
      const Category(
        id: 'cat-food',
        type: CategoryType.expense,
        name: 'Food',
        iconKey: 'food',
      ),
    );

    await controller.saveTransaction(
      name: 'Lunch',
      amount: 35000,
      categoryId: 'cat-food',
      date: DateTime(2026, 4, 10),
      location: const TransactionLocation(
        latitude: -6.2,
        longitude: 106.816666,
        source: TransactionLocationSource.gps,
      ),
    );

    expect(api.lastJsonBody?['location'], {
      'latitude': -6.2,
      'longitude': 106.816666,
      'source': 'gps',
    });
  });

  test('currentTransactionLocation delegates to injected gateway', () async {
    final controller = AppController(
      persistence: MemoryPersistenceService(),
      notifications: RecordingNotificationGateway(),
      imagePicker: FixedImagePickerGateway(null),
      locationGateway: FixedLocationGateway(
        const TransactionLocation(
          latitude: -6.2,
          longitude: 106.816666,
          source: TransactionLocationSource.gps,
        ),
      ),
    );

    final location = await controller.currentTransactionLocation();

    expect(location.latitude, -6.2);
    expect(location.longitude, 106.816666);
    expect(location.source, TransactionLocationSource.gps);
  });

  test('remote finance entries hydrate controller initialization', () async {
    final persistence = MemoryPersistenceService();
    persistence.storedTokens = const AuthTokens(
      accessToken: 'access',
      refreshToken: 'refresh',
    );
    persistence.storedProfile = const UserProfile(
      id: 'user-1',
      name: 'Alya Finu',
      email: 'demo@finu.app',
    );
    final controller = AppController(
      persistence: persistence,
      notifications: RecordingNotificationGateway(),
      imagePicker: FixedImagePickerGateway(null),
      apiClient: RecordingApiClient(
        baseUrl: AppConfig.defaultApiBaseUrl,
        responses: const {},
        getResponses: _snapshotResponses(),
      ),
    );
    await controller.initialize();

    expect(controller.transactions.any((tx) => tx.name == 'Kopi'), isTrue);
    expect(controller.savings.any((item) => item.name == 'Freelance'), isTrue);
    expect(
      controller.savings.any((item) => item.name == 'Dana darurat ekstra'),
      isTrue,
    );
  });

  test(
    'remote finance snapshot persists for later no-token hydration',
    () async {
      final persistence = MemoryPersistenceService();
      final controller = AppController(
        persistence: persistence,
        notifications: RecordingNotificationGateway(),
        imagePicker: FixedImagePickerGateway(null),
        apiClient: RecordingApiClient(
          baseUrl: AppConfig.defaultApiBaseUrl,
          responses: const {},
          getResponses: _snapshotResponses(),
        ),
      );
      controller.tokens = const AuthTokens(
        accessToken: 'access',
        refreshToken: 'refresh',
      );

      await controller.loadRemoteSnapshot();

      expect(
        persistence.storedCategories?.map((item) => item.id),
        containsAll(<String>['cat-food', 'cat-emergency']),
      );
      expect(persistence.storedTransactions?.single.name, 'Kopi');
      expect(
        persistence.storedSavings?.map((item) => item.name),
        containsAll(<String>['Freelance', 'Dana darurat ekstra']),
      );

      final restored = AppController(
        persistence: persistence,
        notifications: RecordingNotificationGateway(),
        imagePicker: FixedImagePickerGateway(null),
        apiClient: RecordingApiClient(
          baseUrl: AppConfig.defaultApiBaseUrl,
          responses: const {},
        ),
      );
      await restored.initialize();

      expect(
        restored.categories.map((item) => item.id),
        containsAll(<String>['cat-food', 'cat-emergency']),
      );
      expect(restored.transactions.single.name, 'Kopi');
      expect(
        restored.savings.map((item) => item.name),
        containsAll(<String>['Freelance', 'Dana darurat ekstra']),
      );
    },
  );
}

class RecordingApiClient extends ApiClient {
  RecordingApiClient({
    required super.baseUrl,
    required this.responses,
    this.getResponses = const {},
    this.throwingPostPaths = const {},
  });

  final Map<String, Map<String, dynamic>> responses;
  final Map<String, Map<String, dynamic>> getResponses;
  final Set<String> throwingPostPaths;
  Map<String, dynamic>? lastJsonBody;

  @override
  Future<Map<String, dynamic>> getJson(String path) async {
    return getResponses[path] ?? <String, dynamic>{'data': <dynamic>[]};
  }

  @override
  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    if (throwingPostPaths.contains(path)) {
      throw StateError('forced failure for $path');
    }
    lastJsonBody = body;
    return responses[path] ?? <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> patchJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    lastJsonBody = body;
    return responses[path] ?? <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> uploadProfilePhoto(String filePath) async {
    return responses['/profile/photo'] ?? <String, dynamic>{};
  }
}

Map<String, Map<String, dynamic>> _snapshotResponses() => {
  '/profile': {
    'data': {'id': 'user-1', 'name': 'Alya Finu', 'email': 'demo@finu.app'},
  },
  '/categories?type=expense': {
    'data': [
      {
        'id': 'cat-food',
        'type': 'expense',
        'name': 'Makan',
        'iconKey': 'food',
        'monthlyBudget': 1200000,
        'savingTarget': null,
      },
    ],
  },
  '/categories?type=saving': {
    'data': [
      {
        'id': 'cat-emergency',
        'type': 'saving',
        'name': 'Dana Darurat',
        'iconKey': 'emergency',
        'monthlyBudget': null,
        'savingTarget': 5000000,
      },
    ],
  },
  '/transactions?limit=100': {
    'data': [
      {
        'id': 'tx-kopi',
        'name': 'Kopi',
        'amount': 18000,
        'categoryId': 'cat-food',
        'date': '2026-04-10',
        'note': null,
        'location': null,
      },
    ],
  },
  '/savings?limit=100': {
    'data': [
      {
        'id': 'sav-income',
        'type': 'general_income',
        'name': 'Freelance',
        'amount': 250000,
        'date': '2026-04-11',
        'categoryId': null,
        'note': null,
      },
      {
        'id': 'sav-emergency',
        'type': 'saving',
        'name': 'Dana darurat ekstra',
        'amount': 50000,
        'date': '2026-04-12',
        'categoryId': 'cat-emergency',
        'note': null,
      },
    ],
  },
};
