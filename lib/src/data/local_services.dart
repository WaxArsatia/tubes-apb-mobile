import 'dart:convert';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models.dart';

abstract class PersistenceService {
  Future<AuthTokens?> readTokens();
  Future<void> writeTokens(AuthTokens tokens);
  Future<void> clearTokens();
  Future<UserProfile?> readProfile();
  Future<void> writeProfile(UserProfile profile);
  Future<void> clearProfile();
  Future<AppConfig?> readConfig();
  Future<void> writeConfig(AppConfig config);
  Future<List<Category>?> readCategories();
  Future<void> writeCategories(List<Category> categories);
  Future<List<TransactionEntry>?> readTransactions();
  Future<void> writeTransactions(List<TransactionEntry> transactions);
  Future<List<SavingEntry>?> readSavings();
  Future<void> writeSavings(List<SavingEntry> savings);
}

class LocalPersistenceService implements PersistenceService {
  LocalPersistenceService({
    FlutterSecureStorage? secureStorage,
    SharedPreferencesAsync? preferences,
  }) : _secureStorage =
           secureStorage ??
           const FlutterSecureStorage(
             aOptions: AndroidOptions(migrateOnAlgorithmChange: true),
           ),
       _preferences = preferences ?? SharedPreferencesAsync();

  static const _accessTokenKey = 'finu_access_token';
  static const _refreshTokenKey = 'finu_refresh_token';
  static const _profileKey = 'finu_profile';
  static const _categoriesKey = 'finu_categories';
  static const _transactionsKey = 'finu_transactions';
  static const _savingsKey = 'finu_savings';
  static const _apiBaseUrlKey = 'finu_api_base_url';
  static const _mockModeKey = 'finu_mock_mode';

  final FlutterSecureStorage _secureStorage;
  final SharedPreferencesAsync _preferences;

  @override
  Future<AuthTokens?> readTokens() async {
    final accessToken = await _secureStorage.read(key: _accessTokenKey);
    final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
    if (accessToken == null || refreshToken == null) return null;
    return AuthTokens(accessToken: accessToken, refreshToken: refreshToken);
  }

  @override
  Future<void> writeTokens(AuthTokens tokens) async {
    await _secureStorage.write(key: _accessTokenKey, value: tokens.accessToken);
    await _secureStorage.write(
      key: _refreshTokenKey,
      value: tokens.refreshToken,
    );
  }

  @override
  Future<void> clearTokens() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
  }

  @override
  Future<UserProfile?> readProfile() async {
    final raw = await _preferences.getString(_profileKey);
    if (raw == null) return null;
    return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> writeProfile(UserProfile profile) async {
    await _preferences.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  @override
  Future<void> clearProfile() async {
    await _preferences.remove(_profileKey);
  }

  @override
  Future<AppConfig?> readConfig() async {
    final apiBaseUrl = await _preferences.getString(_apiBaseUrlKey);
    final mockMode = await _preferences.getBool(_mockModeKey);
    if (apiBaseUrl == null && mockMode == null) return null;
    return AppConfig(
      apiBaseUrl: apiBaseUrl ?? AppConfig.defaultApiBaseUrl,
      mockMode: mockMode ?? false,
    );
  }

  @override
  Future<void> writeConfig(AppConfig config) async {
    await _preferences.setString(_apiBaseUrlKey, config.apiBaseUrl);
    await _preferences.setBool(_mockModeKey, config.mockMode);
  }

  @override
  Future<List<Category>?> readCategories() async {
    final raw = await _preferences.getString(_categoriesKey);
    if (raw == null) return null;
    return (jsonDecode(raw) as List)
        .cast<Map<String, dynamic>>()
        .map(Category.fromJson)
        .toList();
  }

  @override
  Future<void> writeCategories(List<Category> categories) async {
    await _preferences.setString(
      _categoriesKey,
      jsonEncode(categories.map((item) => item.toJson()).toList()),
    );
  }

  @override
  Future<List<TransactionEntry>?> readTransactions() async {
    final raw = await _preferences.getString(_transactionsKey);
    if (raw == null) return null;
    return (jsonDecode(raw) as List)
        .cast<Map<String, dynamic>>()
        .map(TransactionEntry.fromJson)
        .toList();
  }

  @override
  Future<void> writeTransactions(List<TransactionEntry> transactions) async {
    await _preferences.setString(
      _transactionsKey,
      jsonEncode(transactions.map((item) => item.toJson()).toList()),
    );
  }

  @override
  Future<List<SavingEntry>?> readSavings() async {
    final raw = await _preferences.getString(_savingsKey);
    if (raw == null) return null;
    return (jsonDecode(raw) as List)
        .cast<Map<String, dynamic>>()
        .map(SavingEntry.fromJson)
        .toList();
  }

  @override
  Future<void> writeSavings(List<SavingEntry> savings) async {
    await _preferences.setString(
      _savingsKey,
      jsonEncode(savings.map((item) => item.toJson()).toList()),
    );
  }
}

class MemoryPersistenceService implements PersistenceService {
  AuthTokens? storedTokens;
  UserProfile? storedProfile;
  AppConfig? storedConfig;
  List<Category>? storedCategories;
  List<TransactionEntry>? storedTransactions;
  List<SavingEntry>? storedSavings;

  @override
  Future<void> clearProfile() async {
    storedProfile = null;
  }

  @override
  Future<void> clearTokens() async {
    storedTokens = null;
  }

  @override
  Future<AppConfig?> readConfig() async => storedConfig;

  @override
  Future<UserProfile?> readProfile() async => storedProfile;

  @override
  Future<AuthTokens?> readTokens() async => storedTokens;

  @override
  Future<void> writeConfig(AppConfig config) async {
    storedConfig = config;
  }

  @override
  Future<List<Category>?> readCategories() async => storedCategories;

  @override
  Future<void> writeCategories(List<Category> categories) async {
    storedCategories = List.of(categories);
  }

  @override
  Future<List<TransactionEntry>?> readTransactions() async =>
      storedTransactions;

  @override
  Future<void> writeTransactions(List<TransactionEntry> transactions) async {
    storedTransactions = List.of(transactions);
  }

  @override
  Future<List<SavingEntry>?> readSavings() async => storedSavings;

  @override
  Future<void> writeSavings(List<SavingEntry> savings) async {
    storedSavings = List.of(savings);
  }

  @override
  Future<void> writeProfile(UserProfile profile) async {
    storedProfile = profile;
  }

  @override
  Future<void> writeTokens(AuthTokens tokens) async {
    storedTokens = tokens;
  }
}

abstract class NotificationGateway {
  Future<void> initialize();
  Future<void> requestPermission();
  Future<void> showBudgetWarning({required String title, required String body});
}

class LocalNotificationGateway implements NotificationGateway {
  LocalNotificationGateway({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  var _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: darwin);
    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  @override
  Future<void> requestPermission() async {
    await initialize();
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  @override
  Future<void> showBudgetWarning({
    required String title,
    required String body,
  }) async {
    await initialize();
    const androidDetails = AndroidNotificationDetails(
      'finu_budget',
      'Budget FinU',
      channelDescription: 'Peringatan budget dan target tabungan FinU',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(
      id: 20,
      title: title,
      body: body,
      notificationDetails: details,
      payload: 'budget',
    );
  }
}

class RecordingNotificationGateway implements NotificationGateway {
  final messages = <String>[];
  var initialized = false;
  var requestedPermission = false;

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<void> requestPermission() async {
    requestedPermission = true;
  }

  @override
  Future<void> showBudgetWarning({
    required String title,
    required String body,
  }) async {
    messages.add('$title: $body');
  }
}

abstract class ImagePickerGateway {
  Future<String?> pickProfilePhotoPath();
}

class GalleryImagePickerGateway implements ImagePickerGateway {
  GalleryImagePickerGateway({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<String?> pickProfilePhotoPath() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 88,
    );
    if (image == null) return null;
    final length = await File(image.path).length();
    if (length > 5 * 1024 * 1024) {
      throw ArgumentError('Foto maksimal 5 MB');
    }
    final lowerPath = image.path.toLowerCase();
    if (!lowerPath.endsWith('.jpg') &&
        !lowerPath.endsWith('.jpeg') &&
        !lowerPath.endsWith('.png')) {
      throw ArgumentError('Foto harus JPEG atau PNG');
    }
    return image.path;
  }
}

class FixedImagePickerGateway implements ImagePickerGateway {
  FixedImagePickerGateway(this.path);

  final String? path;

  @override
  Future<String?> pickProfilePhotoPath() async => path;
}

abstract class LocationGateway {
  Future<TransactionLocation> currentTransactionLocation();
}

class DeviceLocationGateway implements LocationGateway {
  @override
  Future<TransactionLocation> currentTransactionLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw ArgumentError('Layanan lokasi belum aktif');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw ArgumentError('Izin lokasi ditolak');
    }
    if (permission == LocationPermission.deniedForever) {
      throw ArgumentError('Izin lokasi ditolak permanen');
    }

    final position = await Geolocator.getCurrentPosition();
    return TransactionLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      source: TransactionLocationSource.gps,
    );
  }
}

class FixedLocationGateway implements LocationGateway {
  FixedLocationGateway(this.location);

  final TransactionLocation? location;

  @override
  Future<TransactionLocation> currentTransactionLocation() async {
    final value = location;
    if (value == null) throw ArgumentError('Lokasi tidak tersedia');
    return value;
  }
}
