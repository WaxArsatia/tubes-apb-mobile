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
}
