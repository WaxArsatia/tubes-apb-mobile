import 'package:flutter_test/flutter_test.dart';
import 'package:tubes_apb_mobile/src/data/app_controller.dart';
import 'package:tubes_apb_mobile/src/data/local_services.dart';
import 'package:tubes_apb_mobile/src/domain/models.dart';

void main() {
  test(
    'login persists mock tokens and profile, then initialize hydrates them',
    () async {
      final persistence = MemoryPersistenceService();
      final controller = AppController(
        persistence: persistence,
        notifications: RecordingNotificationGateway(),
        imagePicker: FixedImagePickerGateway(null),
      );
      await controller.updateConfig(
        const AppConfig(
          apiBaseUrl: AppConfig.defaultApiBaseUrl,
          mockMode: true,
        ),
      );

      await controller.login('demo@finu.app', 'password123');

      expect(persistence.storedTokens?.accessToken, 'mock-access');
      expect(persistence.storedProfile?.email, 'demo@finu.app');

      final restored = AppController(
        persistence: persistence,
        notifications: RecordingNotificationGateway(),
        imagePicker: FixedImagePickerGateway(null),
      );
      await restored.initialize();

      expect(restored.isAuthenticated, isTrue);
      expect(restored.profile?.name, 'Alya Finu');
    },
  );

  test('runtime config is persisted', () async {
    final persistence = MemoryPersistenceService();
    final controller = AppController(
      persistence: persistence,
      notifications: RecordingNotificationGateway(),
      imagePicker: FixedImagePickerGateway(null),
    );

    await controller.updateConfig(
      const AppConfig(apiBaseUrl: 'https://api.example.test', mockMode: false),
    );

    expect(persistence.storedConfig?.apiBaseUrl, 'https://api.example.test');
    expect(persistence.storedConfig?.mockMode, isFalse);
  });

  test('default config points to deployed backend in real mode', () {
    final controller = AppController(
      persistence: MemoryPersistenceService(),
      notifications: RecordingNotificationGateway(),
      imagePicker: FixedImagePickerGateway(null),
    );

    expect(controller.config.apiBaseUrl, 'https://apb-api.denis.my.id');
    expect(controller.config.mockMode, isFalse);
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
      );
      await controller.updateConfig(
        const AppConfig(
          apiBaseUrl: AppConfig.defaultApiBaseUrl,
          mockMode: true,
        ),
      );
      await controller.login('demo@finu.app', 'password123');

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
    );
    await controller.updateConfig(
      const AppConfig(apiBaseUrl: AppConfig.defaultApiBaseUrl, mockMode: true),
    );
    await controller.login('demo@finu.app', 'password123');

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
    );
    await controller.updateConfig(
      const AppConfig(apiBaseUrl: AppConfig.defaultApiBaseUrl, mockMode: true),
    );
    await controller.login('demo@finu.app', 'password123');

    await controller.pickAndUploadProfilePhoto();

    expect(controller.profile?.profilePhotoUrl, '/tmp/profile.png');
    expect(persistence.storedProfile?.profilePhotoUrl, '/tmp/profile.png');
  });
}
