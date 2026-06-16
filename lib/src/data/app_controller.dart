import 'dart:math';

import 'package:flutter/material.dart';

import 'api_client.dart';
import 'local_services.dart';
import '../domain/finance_calculator.dart';
import '../domain/models.dart';

class AppController extends ChangeNotifier {
  AppController({
    PersistenceService? persistence,
    NotificationGateway? notifications,
    ImagePickerGateway? imagePicker,
    LocationGateway? locationGateway,
    ApiClient? apiClient,
  }) : _persistence = persistence ?? LocalPersistenceService(),
       _notifications = notifications ?? LocalNotificationGateway(),
       _imagePicker = imagePicker ?? GalleryImagePickerGateway(),
       _locationGateway = locationGateway ?? DeviceLocationGateway(),
       _apiClientOverride = apiClient {
    _seed();
  }

  final calculator = const FinanceCalculator();
  final PersistenceService _persistence;
  final NotificationGateway _notifications;
  final ImagePickerGateway _imagePicker;
  final LocationGateway _locationGateway;
  final ApiClient? _apiClientOverride;

  UserProfile? profile;
  AuthTokens? tokens;
  AppConfig config = AppConfig.defaultConfig;
  final categories = <Category>[];
  final transactions = <TransactionEntry>[];
  final savings = <SavingEntry>[];
  bool loading = false;
  bool initialized = false;
  String? lastWarning;

  bool get isAuthenticated => tokens != null && profile != null;
  List<Category> get expenseCategories =>
      categories
          .where((cat) => !cat.deleted && cat.type == CategoryType.expense)
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
  List<Category> get savingCategories =>
      categories
          .where((cat) => !cat.deleted && cat.type == CategoryType.saving)
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
  List<TransactionEntry> get activeTransactions =>
      transactions.where((item) => !item.deleted).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
  List<SavingEntry> get activeSavings =>
      savings.where((item) => !item.deleted).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
  bool get hasGeneralIncome =>
      activeSavings.any((item) => item.type == SavingType.generalIncome);

  void refresh() {
    notifyListeners();
  }

  Future<void> initialize() async {
    if (initialized) return;
    await _notifications.initialize();
    config = await _persistence.readConfig() ?? config;
    tokens = await _persistence.readTokens();
    profile = await _persistence.readProfile();
    if (!config.mockMode && tokens != null) {
      await loadRemoteSnapshot();
    }
    initialized = true;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _validateEmail(email);
    if (password.length < 8) throw ArgumentError('Password minimal 8 karakter');
    await _busy(() async {
      if (config.mockMode) {
        if (email == 'salah@example.com') {
          throw ArgumentError('Email atau password salah');
        }
        profile = UserProfile(
          id: 'user-1',
          name: email.split('@').first == 'demo'
              ? 'Alya Finu'
              : email.split('@').first,
          email: email,
        );
        tokens = const AuthTokens(
          accessToken: 'mock-access',
          refreshToken: 'mock-refresh',
        );
      } else {
        final envelope = await _api().postJson('/auth/login', {
          'email': email,
          'password': password,
        });
        _applyAuthEnvelope(envelope);
        await loadRemoteSnapshot();
      }
      await _persistSession();
    });
  }

  Future<void> register(
    String name,
    String email,
    String password,
    String confirm,
  ) async {
    if (name.trim().isEmpty) throw ArgumentError('Nama wajib diisi');
    _validateEmail(email);
    if (password.length < 8) throw ArgumentError('Password minimal 8 karakter');
    if (password != confirm) {
      throw ArgumentError('Konfirmasi password tidak sama');
    }
    await _busy(() async {
      if (config.mockMode) {
        profile = UserProfile(id: 'user-1', name: name.trim(), email: email);
        tokens = const AuthTokens(
          accessToken: 'mock-access',
          refreshToken: 'mock-refresh',
        );
      } else {
        final envelope = await _api().postJson('/auth/register', {
          'name': name.trim(),
          'email': email,
          'password': password,
        });
        _applyAuthEnvelope(envelope);
        await loadRemoteSnapshot();
      }
      await _persistSession();
    });
  }

  Future<void> forgotPassword(String email) async {
    _validateEmail(email);
    await _busy(() async {
      if (!config.mockMode) {
        await _api().postJson('/auth/forgot-password', {'email': email});
      }
    });
  }

  Future<void> resetPassword(String email, String code, String password) async {
    _validateEmail(email);
    if (!RegExp(r'^[a-zA-Z0-9]{6}$').hasMatch(code)) {
      throw ArgumentError('Kode reset harus 6 karakter alfanumerik');
    }
    if (password.length < 8) throw ArgumentError('Password minimal 8 karakter');
    await _busy(() async {
      if (!config.mockMode) {
        await _api().postJson('/auth/reset-password', {
          'email': email,
          'code': code,
          'password': password,
        });
      }
    });
  }

  Future<void> logout() async {
    if (!config.mockMode && tokens != null) {
      try {
        await _api().postJson('/auth/logout', {
          'refreshToken': tokens!.refreshToken,
        });
      } on Object {
        // Local session cleanup must still happen if the backend is unreachable.
      }
    }
    profile = null;
    tokens = null;
    await _persistence.clearTokens();
    await _persistence.clearProfile();
    notifyListeners();
  }

  Future<void> updateProfile(String name, {String? photoPath}) async {
    if (name.trim().isEmpty) throw ArgumentError('Nama wajib diisi');
    if (!config.mockMode) {
      final envelope = await _api().patchJson('/profile', {
        'name': name.trim(),
      });
      final data = _data(envelope);
      if (data.isNotEmpty) {
        profile = UserProfile.fromJson(data);
        await _persistence.writeProfile(profile!);
        notifyListeners();
        return;
      }
    }
    profile = profile?.copyWith(name: name.trim(), profilePhotoUrl: photoPath);
    if (profile != null) await _persistence.writeProfile(profile!);
    notifyListeners();
  }

  Future<void> pickAndUploadProfilePhoto() async {
    final path = await _imagePicker.pickProfilePhotoPath();
    if (path == null) return;
    if (config.mockMode) {
      profile = profile?.copyWith(profilePhotoUrl: path);
    } else {
      final envelope = await _api().uploadProfilePhoto(path);
      final data = _data(envelope);
      profile = data.isEmpty
          ? profile?.copyWith(profilePhotoUrl: path)
          : UserProfile.fromJson(data);
    }
    if (profile != null) await _persistence.writeProfile(profile!);
    notifyListeners();
  }

  Future<TransactionLocation> currentTransactionLocation() async {
    return _locationGateway.currentTransactionLocation();
  }

  Future<void> updateNotification(bool enabled) async {
    if (!config.mockMode) {
      final envelope = await _api().patchJson('/settings/notifications', {
        'budgetNotificationEnabled': enabled,
      });
      final data = _data(envelope);
      if (data.isNotEmpty) {
        profile = UserProfile.fromJson(data);
      }
    } else {
      profile = profile?.copyWith(budgetNotificationEnabled: enabled);
    }
    if (enabled) await _notifications.requestPermission();
    if (profile != null) await _persistence.writeProfile(profile!);
    notifyListeners();
  }

  Future<void> updateConfig(AppConfig next) async {
    config = next;
    await _persistence.writeConfig(next);
    notifyListeners();
  }

  Future<void> loadRemoteSnapshot() async {
    if (config.mockMode || tokens == null) return;
    final api = _api();
    final profileEnvelope = await api.getJson('/profile');
    final expenseEnvelope = await api.getJson('/categories?type=expense');
    final savingCategoryEnvelope = await api.getJson('/categories?type=saving');
    final transactionEnvelope = await api.getJson('/transactions?limit=100');
    final savingEnvelope = await api.getJson('/savings?limit=100');

    profile = UserProfile.fromJson(_data(profileEnvelope));
    categories
      ..clear()
      ..addAll([
        ..._listData(expenseEnvelope).map(Category.fromJson),
        ..._listData(savingCategoryEnvelope).map(Category.fromJson),
      ]);
    transactions
      ..clear()
      ..addAll(_listData(transactionEnvelope).map(TransactionEntry.fromJson));
    savings
      ..clear()
      ..addAll(_listData(savingEnvelope).map(SavingEntry.fromJson));
    if (profile != null) await _persistence.writeProfile(profile!);
    notifyListeners();
  }

  void _markBudgetWarning(String message) {
    lastWarning = message;
    if (profile?.budgetNotificationEnabled ?? false) {
      _notifications.showBudgetWarning(
        title: 'Peringatan Budget',
        body: message,
      );
    }
  }

  void _applyAuthEnvelope(Map<String, dynamic> envelope) {
    final data = _data(envelope);
    tokens = AuthTokens.fromJson(
      (data['tokens'] as Map<String, dynamic>?) ?? data,
    );
    final profileJson =
        (data['user'] as Map<String, dynamic>?) ??
        (data['profile'] as Map<String, dynamic>?);
    if (profileJson != null) profile = UserProfile.fromJson(profileJson);
  }

  Future<void> _persistSession() async {
    if (tokens != null) await _persistence.writeTokens(tokens!);
    if (profile != null) await _persistence.writeProfile(profile!);
  }

  ApiClient _api() {
    final client =
        _apiClientOverride ??
        ApiClient(
          baseUrl: config.apiBaseUrl,
          onTokensRefreshed: _persistence.writeTokens,
        );
    client.tokens = tokens;
    return client;
  }

  Map<String, dynamic> _data(Map<String, dynamic> envelope) =>
      (envelope['data'] as Map<String, dynamic>?) ?? envelope;

  List<Map<String, dynamic>> _listData(Map<String, dynamic> envelope) {
    final raw = envelope['data'];
    if (raw is List) return raw.cast<Map<String, dynamic>>();
    if (raw is Map<String, dynamic> && raw['items'] is List) {
      return (raw['items'] as List).cast<Map<String, dynamic>>();
    }
    return const [];
  }

  void updateNotificationLocal(bool enabled) {
    profile = profile?.copyWith(budgetNotificationEnabled: enabled);
    notifyListeners();
  }

  Future<Category> saveCategory({
    String? id,
    required CategoryType type,
    required String name,
    required String iconKey,
    int? monthlyBudget,
    int? savingTarget,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError('Nama category wajib diisi');
    final duplicate = categories.any(
      (cat) =>
          !cat.deleted &&
          cat.type == type &&
          cat.id != id &&
          cat.name.toLowerCase() == trimmed.toLowerCase(),
    );
    if (duplicate) throw ArgumentError('Nama category sudah digunakan');
    if (type == CategoryType.expense &&
        monthlyBudget != null &&
        !hasGeneralIncome) {
      throw ArgumentError(
        'Catat pemasukan umum terlebih dahulu untuk mengaktifkan budget',
      );
    }
    if ((monthlyBudget ?? 1) <= 0 || (savingTarget ?? 1) <= 0) {
      throw ArgumentError('Nominal harus positif');
    }
    final body = {
      'type': type == CategoryType.saving ? 'saving' : 'expense',
      'name': trimmed,
      'iconKey': iconKey,
      'monthlyBudget': type == CategoryType.expense ? monthlyBudget : null,
      'savingTarget': type == CategoryType.saving ? savingTarget : null,
    };
    Category category;
    if (!config.mockMode) {
      final envelope = id == null
          ? await _api().postJson('/categories', body)
          : await _api().patchJson('/categories/$id', body);
      category = Category.fromJson(_data(envelope));
    } else {
      final existing = id == null ? null : _categoryById(id);
      category = existing == null
          ? Category(
              id: _id('cat'),
              type: type,
              name: trimmed,
              iconKey: iconKey,
              monthlyBudget: type == CategoryType.expense
                  ? monthlyBudget
                  : null,
              savingTarget: type == CategoryType.saving ? savingTarget : null,
            )
          : existing.copyWith(
              name: trimmed,
              iconKey: iconKey,
              monthlyBudget: type == CategoryType.expense
                  ? monthlyBudget
                  : null,
              savingTarget: type == CategoryType.saving ? savingTarget : null,
              clearBudget:
                  type == CategoryType.expense && monthlyBudget == null,
              clearTarget: type == CategoryType.saving && savingTarget == null,
            );
    }
    _upsertCategory(category);
    notifyListeners();
    return category;
  }

  Future<int> softDeleteCategory(String id) async {
    if (!config.mockMode) {
      await _api().deleteJson('/categories/$id');
      await loadRemoteSnapshot();
      return 0;
    }
    final affected = _softDeleteCategoryLocal(id);
    notifyListeners();
    return affected;
  }

  Future<void> restoreCategory(String id) async {
    if (!config.mockMode) {
      await _api().postJson('/categories/$id/restore', {});
      await loadRemoteSnapshot();
      return;
    }
    final index = categories.indexWhere((cat) => cat.id == id);
    if (index == -1) return;
    categories[index] = categories[index].copyWith(deleted: false);
    for (var i = 0; i < transactions.length; i++) {
      if (transactions[i].previousCategoryId == id) {
        transactions[i] = transactions[i].copyWith(categoryId: id);
      }
    }
    for (var i = 0; i < savings.length; i++) {
      if (savings[i].previousCategoryId == id) {
        savings[i] = savings[i].copyWith(categoryId: id);
      }
    }
    notifyListeners();
  }

  void _upsertCategory(Category category) {
    final index = categories.indexWhere((cat) => cat.id == category.id);
    if (index == -1) {
      categories.add(category);
    } else {
      categories[index] = category;
    }
  }

  int _softDeleteCategoryLocal(String id) {
    final index = categories.indexWhere((cat) => cat.id == id);
    if (index == -1) return 0;
    final category = categories[index];
    categories[index] = category.copyWith(deleted: true);
    var affected = 0;
    for (var i = 0; i < transactions.length; i++) {
      if (transactions[i].categoryId == id) {
        transactions[i] = transactions[i].copyWith(
          clearCategory: true,
          previousCategoryId: id,
        );
        affected++;
      }
    }
    for (var i = 0; i < savings.length; i++) {
      if (savings[i].categoryId == id) {
        savings[i] = savings[i].copyWith(
          clearCategory: true,
          previousCategoryId: id,
        );
        affected++;
      }
    }
    return affected;
  }

  Future<TransactionEntry> saveTransaction({
    String? id,
    String? name,
    required int amount,
    required String categoryId,
    required DateTime date,
    String? note,
    TransactionLocation? location,
  }) async {
    if (amount <= 0) throw ArgumentError('Amount harus positif');
    if (date.isAfter(DateTime.now())) {
      throw ArgumentError('Tanggal tidak boleh di masa depan');
    }
    final category = expenseCategories.firstWhere(
      (cat) => cat.id == categoryId,
    );
    final body = {
      'name': name?.trim(),
      'amount': amount,
      'categoryId': categoryId,
      'date': _dateOnly(date),
      'note': note,
      'location': location?.toJson(),
    };
    TransactionEntry entry;
    if (!config.mockMode) {
      final envelope = id == null
          ? await _api().postJson('/transactions', body)
          : await _api().patchJson('/transactions/$id', body);
      entry = TransactionEntry.fromJson(_data(envelope));
      _applyWarnings(envelope);
    } else {
      entry = TransactionEntry(
        id: id ?? _id('tx'),
        name: name?.trim().isNotEmpty == true ? name!.trim() : category.name,
        amount: amount,
        categoryId: categoryId,
        date: DateTime(date.year, date.month, date.day),
        note: note,
        location: location,
      );
    }
    _upsertTransaction(entry);
    final budget = category.monthlyBudget;
    if (budget != null &&
        calculator.categorySpending(categoryId, transactions, date) > budget) {
      _markBudgetWarning('Transaksi ini akan melebihi budget category');
    }
    notifyListeners();
    return entry;
  }

  Future<void> softDeleteTransaction(String id) async {
    if (!config.mockMode) {
      await _api().deleteJson('/transactions/$id');
      await loadRemoteSnapshot();
      return;
    }
    final index = transactions.indexWhere((tx) => tx.id == id);
    if (index == -1) return;
    transactions[index] = transactions[index].copyWith(deleted: true);
    notifyListeners();
  }

  Future<void> restoreTransaction(String id) async {
    if (!config.mockMode) {
      await _api().postJson('/transactions/$id/restore', {});
      await loadRemoteSnapshot();
      return;
    }
    final index = transactions.indexWhere((tx) => tx.id == id);
    if (index == -1) return;
    transactions[index] = transactions[index].copyWith(deleted: false);
    notifyListeners();
  }

  void _upsertTransaction(TransactionEntry entry) {
    final index = transactions.indexWhere((tx) => tx.id == entry.id);
    if (index == -1) {
      transactions.add(entry);
    } else {
      transactions[index] = entry;
    }
  }

  Future<SavingEntry> saveSaving({
    String? id,
    required SavingType type,
    String? name,
    required int amount,
    String? categoryId,
    required DateTime date,
    String? note,
  }) async {
    if (amount <= 0) throw ArgumentError('Amount harus positif');
    if (date.isAfter(DateTime.now())) {
      throw ArgumentError('Tanggal tidak boleh di masa depan');
    }
    Category? category;
    if (type == SavingType.saving) {
      if (categoryId == null) {
        throw ArgumentError('Category tabungan wajib dipilih');
      }
      category = savingCategories.firstWhere((cat) => cat.id == categoryId);
    }
    final body = {
      'type': type == SavingType.saving ? 'saving' : 'general_income',
      'name': name?.trim(),
      'amount': amount,
      'date': _dateOnly(date),
      'categoryId': type == SavingType.saving ? categoryId : null,
      'note': note,
    };
    SavingEntry entry;
    if (!config.mockMode) {
      final envelope = id == null
          ? await _api().postJson('/savings', body)
          : await _api().patchJson('/savings/$id', body);
      entry = SavingEntry.fromJson(_data(envelope));
      _applyWarnings(envelope);
    } else {
      entry = SavingEntry(
        id: id ?? _id('sav'),
        type: type,
        name: name?.trim().isNotEmpty == true
            ? name!.trim()
            : type == SavingType.saving
            ? category!.name
            : 'Pemasukan Umum',
        amount: amount,
        date: DateTime(date.year, date.month, date.day),
        categoryId: type == SavingType.saving ? categoryId : null,
        note: note,
      );
    }
    _upsertSaving(entry);
    final target = category?.savingTarget;
    if (target != null &&
        calculator.savingProgress(category!.id, savings) > target) {
      _markBudgetWarning('Kamu telah melampaui target tabungan');
    }
    notifyListeners();
    return entry;
  }

  Future<void> softDeleteSaving(String id) async {
    if (!config.mockMode) {
      await _api().deleteJson('/savings/$id');
      await loadRemoteSnapshot();
      return;
    }
    final index = savings.indexWhere((item) => item.id == id);
    if (index == -1) return;
    savings[index] = savings[index].copyWith(deleted: true);
    notifyListeners();
  }

  Future<void> restoreSaving(String id) async {
    if (!config.mockMode) {
      await _api().postJson('/savings/$id/restore', {});
      await loadRemoteSnapshot();
      return;
    }
    final index = savings.indexWhere((item) => item.id == id);
    if (index == -1) return;
    savings[index] = savings[index].copyWith(deleted: false);
    notifyListeners();
  }

  void _upsertSaving(SavingEntry entry) {
    final index = savings.indexWhere((item) => item.id == entry.id);
    if (index == -1) {
      savings.add(entry);
    } else {
      savings[index] = entry;
    }
  }

  void _applyWarnings(Map<String, dynamic> envelope) {
    final warnings = envelope['warnings'];
    if (warnings is! List || warnings.isEmpty) return;
    final first = warnings.first;
    if (first is Map<String, dynamic>) {
      _markBudgetWarning(
        first['message'] as String? ?? 'Ada peringatan budget',
      );
    }
  }

  String _dateOnly(DateTime date) => date.toIso8601String().substring(0, 10);

  List<Object> recentActivities({int limit = 5}) {
    final merged = <Object>[...activeTransactions, ...activeSavings];
    merged.sort((a, b) {
      final ad = a is TransactionEntry ? a.date : (a as SavingEntry).date;
      final bd = b is TransactionEntry ? b.date : (b as SavingEntry).date;
      return bd.compareTo(ad);
    });
    return merged.take(limit).toList();
  }

  Future<void> _busy(Future<void> Function() action) async {
    loading = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 250));
    await action();
    loading = false;
    notifyListeners();
  }

  void _validateEmail(String email) {
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      throw ArgumentError('Format email tidak valid');
    }
  }

  void _seed() {
    final now = DateTime.now();
    categories.addAll([
      const Category(
        id: 'cat-food',
        type: CategoryType.expense,
        name: 'Makan',
        iconKey: 'food',
        monthlyBudget: 1200000,
      ),
      const Category(
        id: 'cat-transport',
        type: CategoryType.expense,
        name: 'Transport',
        iconKey: 'transport',
        monthlyBudget: 500000,
      ),
      const Category(
        id: 'cat-emergency',
        type: CategoryType.saving,
        name: 'Dana Darurat',
        iconKey: 'emergency',
        savingTarget: 5000000,
      ),
    ]);
    savings.addAll([
      SavingEntry(
        id: 'sav-income',
        type: SavingType.generalIncome,
        name: 'Gaji Bulanan',
        amount: 4500000,
        date: DateTime(now.year, now.month, 1),
      ),
      SavingEntry(
        id: 'sav-emergency',
        type: SavingType.saving,
        name: 'Dana Darurat',
        amount: 350000,
        date: DateTime(now.year, now.month, 3),
        categoryId: 'cat-emergency',
      ),
    ]);
    transactions.addAll([
      TransactionEntry(
        id: 'tx-lunch',
        name: 'Makan siang',
        amount: 35000,
        categoryId: 'cat-food',
        date: DateTime(now.year, now.month, min(now.day, 6)),
        location: const TransactionLocation(
          latitude: -6.2,
          longitude: 106.816666,
          source: TransactionLocationSource.manual,
        ),
      ),
      TransactionEntry(
        id: 'tx-bus',
        name: 'Bus kampus',
        amount: 12000,
        categoryId: 'cat-transport',
        date: DateTime(now.year, now.month, min(now.day, 5)),
      ),
    ]);
  }

  String _id(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}';

  Category? _categoryById(String id) {
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }
}
