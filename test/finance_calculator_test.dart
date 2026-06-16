import 'package:flutter_test/flutter_test.dart';
import 'package:tubes_apb_mobile/src/domain/finance_calculator.dart';
import 'package:tubes_apb_mobile/src/domain/models.dart';

void main() {
  test(
    'budget remaining ignores uncategorized and unbudgeted transactions',
    () {
      const calculator = FinanceCalculator();
      final month = DateTime(2026, 4, 1);
      const categories = [
        Category(
          id: 'food',
          type: CategoryType.expense,
          name: 'Makan',
          iconKey: 'food',
          monthlyBudget: 100000,
        ),
        Category(
          id: 'misc',
          type: CategoryType.expense,
          name: 'Lainnya',
          iconKey: 'category',
        ),
      ];
      final transactions = [
        TransactionEntry(
          id: '1',
          name: 'Nasi',
          amount: 25000,
          categoryId: 'food',
          date: month,
        ),
        TransactionEntry(
          id: '2',
          name: 'Tanpa budget',
          amount: 50000,
          categoryId: 'misc',
          date: month,
        ),
        TransactionEntry(
          id: '3',
          name: 'Uncategorized',
          amount: 50000,
          categoryId: null,
          date: month,
        ),
      ];

      final summary = calculator.budgetRemaining(
        categories,
        transactions,
        month,
      );

      expect(summary.totalBudget, 100000);
      expect(summary.spent, 25000);
      expect(summary.remaining, 75000);
    },
  );

  test('total balance combines all savings and subtracts expenses', () {
    const calculator = FinanceCalculator();
    final savings = [
      SavingEntry(
        id: 'income',
        type: SavingType.generalIncome,
        name: 'Gaji',
        amount: 500000,
        date: DateTime(2026, 4, 1),
      ),
      SavingEntry(
        id: 'saving',
        type: SavingType.saving,
        name: 'Dana darurat',
        amount: 100000,
        date: DateTime(2026, 4, 2),
      ),
    ];
    final transactions = [
      TransactionEntry(
        id: 'tx',
        name: 'Makan',
        amount: 25000,
        categoryId: 'food',
        date: DateTime(2026, 4, 3),
      ),
    ];

    expect(calculator.totalBalance(savings, transactions), 575000);
  });
}
