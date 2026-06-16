import 'package:flutter_test/flutter_test.dart';
import 'package:tubes_apb_mobile/src/domain/models.dart';

void main() {
  test('category serializes API type and nullable money fields', () {
    const category = Category(
      id: 'cat-1',
      type: CategoryType.expense,
      name: 'Makan',
      iconKey: 'food',
      monthlyBudget: 1000000,
    );

    final json = category.toJson();
    final parsed = Category.fromJson(json);

    expect(json['type'], 'expense');
    expect(json['monthlyBudget'], 1000000);
    expect(parsed.name, 'Makan');
    expect(parsed.type, CategoryType.expense);
  });

  test('saving serializes general income API type', () {
    final saving = SavingEntry(
      id: 'saving-1',
      type: SavingType.generalIncome,
      name: 'Pemasukan Umum',
      amount: 100000,
      date: DateTime(2026, 4, 30),
    );

    expect(saving.toJson()['type'], 'general_income');
    expect(
      SavingEntry.fromJson(saving.toJson()).type,
      SavingType.generalIncome,
    );
  });

  test('transaction serializes nullable location', () {
    final transaction = TransactionEntry(
      id: 'tx-1',
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

    final json = transaction.toJson();
    expect(json['location'], {
      'latitude': -6.2,
      'longitude': 106.816666,
      'source': 'gps',
    });

    final parsed = TransactionEntry.fromJson(json);
    expect(parsed.location?.latitude, -6.2);
    expect(parsed.location?.longitude, 106.816666);
    expect(parsed.location?.source, TransactionLocationSource.gps);

    final cleared = parsed.copyWith(clearLocation: true);
    expect(cleared.location, isNull);
    expect(cleared.toJson()['location'], isNull);
  });
}
