enum CategoryType { expense, saving }

enum SavingType { generalIncome, saving }

enum ActivityKind { transaction, saving }

enum EntryTab { all, generalIncome, saving }

enum TransactionLocationSource { gps, manual }

class TransactionLocation {
  const TransactionLocation({
    required this.latitude,
    required this.longitude,
    required this.source,
  });

  final double latitude;
  final double longitude;
  final TransactionLocationSource source;

  factory TransactionLocation.fromJson(Map<String, dynamic> json) {
    final source = (json['source'] as String?) == 'manual'
        ? TransactionLocationSource.manual
        : TransactionLocationSource.gps;
    return TransactionLocation(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      source: source,
    );
  }

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'source': source == TransactionLocationSource.manual ? 'manual' : 'gps',
  };
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.profilePhotoUrl,
    this.budgetNotificationEnabled = true,
  });

  final String id;
  final String name;
  final String email;
  final String? profilePhotoUrl;
  final bool budgetNotificationEnabled;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  UserProfile copyWith({
    String? name,
    String? profilePhotoUrl,
    bool? budgetNotificationEnabled,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      budgetNotificationEnabled:
          budgetNotificationEnabled ?? this.budgetNotificationEnabled,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    profilePhotoUrl: json['profilePhotoUrl'] as String?,
    budgetNotificationEnabled:
        json['budgetNotificationEnabled'] as bool? ?? true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'profilePhotoUrl': profilePhotoUrl,
    'budgetNotificationEnabled': budgetNotificationEnabled,
  };
}

class AuthTokens {
  const AuthTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String,
  );

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
  };
}

class Category {
  const Category({
    required this.id,
    required this.type,
    required this.name,
    required this.iconKey,
    this.monthlyBudget,
    this.savingTarget,
    this.deleted = false,
  });

  final String id;
  final CategoryType type;
  final String name;
  final String iconKey;
  final int? monthlyBudget;
  final int? savingTarget;
  final bool deleted;

  Category copyWith({
    String? name,
    String? iconKey,
    int? monthlyBudget,
    int? savingTarget,
    bool clearBudget = false,
    bool clearTarget = false,
    bool? deleted,
  }) {
    return Category(
      id: id,
      type: type,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      monthlyBudget: clearBudget ? null : monthlyBudget ?? this.monthlyBudget,
      savingTarget: clearTarget ? null : savingTarget ?? this.savingTarget,
      deleted: deleted ?? this.deleted,
    );
  }

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'] as String,
    type: (json['type'] as String) == 'saving'
        ? CategoryType.saving
        : CategoryType.expense,
    name: json['name'] as String,
    iconKey: json['iconKey'] as String? ?? 'category',
    monthlyBudget: json['monthlyBudget'] as int?,
    savingTarget: json['savingTarget'] as int?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type == CategoryType.saving ? 'saving' : 'expense',
    'name': name,
    'iconKey': iconKey,
    'monthlyBudget': monthlyBudget,
    'savingTarget': savingTarget,
  };
}

class TransactionEntry {
  const TransactionEntry({
    required this.id,
    required this.name,
    required this.amount,
    required this.categoryId,
    required this.date,
    this.note,
    this.location,
    this.deleted = false,
    this.previousCategoryId,
  });

  final String id;
  final String name;
  final int amount;
  final String? categoryId;
  final DateTime date;
  final String? note;
  final TransactionLocation? location;
  final bool deleted;
  final String? previousCategoryId;

  TransactionEntry copyWith({
    String? name,
    int? amount,
    String? categoryId,
    DateTime? date,
    String? note,
    TransactionLocation? location,
    bool? deleted,
    String? previousCategoryId,
    bool clearCategory = false,
    bool clearLocation = false,
  }) {
    return TransactionEntry(
      id: id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      categoryId: clearCategory ? null : categoryId ?? this.categoryId,
      date: date ?? this.date,
      note: note ?? this.note,
      location: clearLocation ? null : location ?? this.location,
      deleted: deleted ?? this.deleted,
      previousCategoryId: previousCategoryId ?? this.previousCategoryId,
    );
  }

  factory TransactionEntry.fromJson(Map<String, dynamic> json) =>
      TransactionEntry(
        id: json['id'] as String,
        name: json['name'] as String,
        amount: json['amount'] as int,
        categoryId: json['categoryId'] as String?,
        date: DateTime.parse(json['date'] as String),
        note: json['note'] as String?,
        location: json['location'] == null
            ? null
            : TransactionLocation.fromJson(
                json['location'] as Map<String, dynamic>,
              ),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'amount': amount,
    'categoryId': categoryId,
    'date': date.toIso8601String().substring(0, 10),
    'note': note,
    'location': location?.toJson(),
  };
}

class SavingEntry {
  const SavingEntry({
    required this.id,
    required this.type,
    required this.name,
    required this.amount,
    required this.date,
    this.categoryId,
    this.note,
    this.deleted = false,
    this.previousCategoryId,
  });

  final String id;
  final SavingType type;
  final String name;
  final int amount;
  final DateTime date;
  final String? categoryId;
  final String? note;
  final bool deleted;
  final String? previousCategoryId;

  SavingEntry copyWith({
    SavingType? type,
    String? name,
    int? amount,
    DateTime? date,
    String? categoryId,
    String? note,
    bool? deleted,
    String? previousCategoryId,
    bool clearCategory = false,
  }) {
    return SavingEntry(
      id: id,
      type: type ?? this.type,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      categoryId: clearCategory ? null : categoryId ?? this.categoryId,
      note: note ?? this.note,
      deleted: deleted ?? this.deleted,
      previousCategoryId: previousCategoryId ?? this.previousCategoryId,
    );
  }

  factory SavingEntry.fromJson(Map<String, dynamic> json) => SavingEntry(
    id: json['id'] as String,
    type: (json['type'] as String) == 'saving'
        ? SavingType.saving
        : SavingType.generalIncome,
    name: json['name'] as String,
    amount: json['amount'] as int,
    date: DateTime.parse(json['date'] as String),
    categoryId: json['categoryId'] as String?,
    note: json['note'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type == SavingType.saving ? 'saving' : 'general_income',
    'name': name,
    'amount': amount,
    'date': date.toIso8601String().substring(0, 10),
    'categoryId': categoryId,
    'note': note,
  };
}

class AppConfig {
  const AppConfig({String? apiBaseUrl});

  static const defaultApiBaseUrl = 'https://apb-api.denis.my.id';
  static const defaultConfig = AppConfig();

  String get apiBaseUrl => defaultApiBaseUrl;

  AppConfig copyWith({String? apiBaseUrl}) => AppConfig.defaultConfig;
}
