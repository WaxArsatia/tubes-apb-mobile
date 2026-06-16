import 'models.dart';

class BudgetSummary {
  const BudgetSummary({
    required this.totalBudget,
    required this.spent,
    required this.budgetedCategoryCount,
  });

  final int totalBudget;
  final int spent;
  final int budgetedCategoryCount;

  int get remaining => totalBudget - spent;
  double get progress =>
      totalBudget == 0 ? 0 : (spent / totalBudget).clamp(0, 1);
}

class FinanceCalculator {
  const FinanceCalculator();

  int totalBalance(List<SavingEntry> savings, List<TransactionEntry> txs) =>
      savings
          .where((item) => !item.deleted)
          .fold(0, (sum, item) => sum + item.amount) -
      txs
          .where((item) => !item.deleted)
          .fold(0, (sum, item) => sum + item.amount);

  int monthlyIncome(List<SavingEntry> savings, DateTime month) => savings
      .where((item) => !item.deleted && _sameMonth(item.date, month))
      .fold(0, (sum, item) => sum + item.amount);

  int monthlyExpense(List<TransactionEntry> txs, DateTime month) => txs
      .where((item) => !item.deleted && _sameMonth(item.date, month))
      .fold(0, (sum, item) => sum + item.amount);

  BudgetSummary budgetRemaining(
    List<Category> categories,
    List<TransactionEntry> txs,
    DateTime month,
  ) {
    final budgeted = categories
        .where(
          (cat) =>
              !cat.deleted &&
              cat.type == CategoryType.expense &&
              cat.monthlyBudget != null,
        )
        .toList();
    final ids = budgeted.map((cat) => cat.id).toSet();
    final totalBudget = budgeted.fold(
      0,
      (sum, cat) => sum + (cat.monthlyBudget ?? 0),
    );
    final spent = txs
        .where(
          (tx) =>
              !tx.deleted &&
              _sameMonth(tx.date, month) &&
              ids.contains(tx.categoryId),
        )
        .fold(0, (sum, tx) => sum + tx.amount);
    return BudgetSummary(
      totalBudget: totalBudget,
      spent: spent,
      budgetedCategoryCount: budgeted.length,
    );
  }

  int categorySpending(
    String categoryId,
    List<TransactionEntry> txs,
    DateTime month,
  ) => txs
      .where(
        (tx) =>
            !tx.deleted &&
            tx.categoryId == categoryId &&
            _sameMonth(tx.date, month),
      )
      .fold(0, (sum, tx) => sum + tx.amount);

  int savingProgress(String categoryId, List<SavingEntry> savings) => savings
      .where(
        (item) =>
            !item.deleted &&
            item.type == SavingType.saving &&
            item.categoryId == categoryId,
      )
      .fold(0, (sum, item) => sum + item.amount);

  bool _sameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;
}
