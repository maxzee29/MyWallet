import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:faddompet/core/enums/budget_status.dart';
import 'package:faddompet/core/enums/transaction_type.dart';
import 'package:faddompet/data/local/database/app_database.dart';
import 'package:faddompet/data/repositories/app_models.dart';
import 'package:faddompet/data/repositories/monthly_report_builder.dart';
import 'package:faddompet/data/repositories/monthly_report_models.dart';

final _stamp = DateTime(2026, 1, 1);

final _wallet = WalletEntry(
  id: 1,
  name: 'Tunai',
  type: 'cash',
  initialBalance: 0,
  isArchived: false,
  createdAt: _stamp,
  updatedAt: _stamp,
);

final _food = CategoryEntry(
  id: 1,
  name: 'Makan',
  type: 'expense',
  groupName: 'Harian',
  iconKey: 'food',
  colorValue: 0xFFDC2626,
  isDefault: true,
  isArchived: false,
  createdAt: _stamp,
  updatedAt: _stamp,
);

TransactionDetail _transaction({
  required int id,
  required TransactionType type,
  required int amount,
  required DateTime date,
  CategoryEntry? category,
}) {
  return TransactionDetail(
    transaction: TransactionEntry(
      id: id,
      type: type.value,
      amount: amount,
      categoryId: category?.id,
      walletId: _wallet.id,
      date: date,
      createdAt: _stamp,
      updatedAt: _stamp,
    ),
    wallet: _wallet,
    category: category,
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  final transactions = [
    _transaction(
      id: 1,
      type: TransactionType.income,
      amount: 1000000,
      date: DateTime(2026, 11, 2),
    ),
    _transaction(
      id: 2,
      type: TransactionType.expense,
      amount: 250000,
      date: DateTime(2026, 11, 5),
      category: _food,
    ),
    _transaction(
      id: 3,
      type: TransactionType.transfer,
      amount: 500000,
      date: DateTime(2026, 11, 6),
    ),
    _transaction(
      id: 4,
      type: TransactionType.expense,
      amount: 100000,
      date: DateTime(2026, 10, 20),
      category: _food,
    ),
  ];

  test('totals only count the selected month and ignore transfers', () {
    final report = MonthlyReportBuilder.build(
      month: DateTime(2026, 11),
      transactions: transactions,
      budgets: const [],
      now: DateTime(2026, 12, 5),
    );

    expect(report.income, 1000000);
    expect(report.expense, 250000);
    expect(report.net, 750000);
    expect(report.previousExpense, 100000);
    expect(report.transactions.length, 3);
    expect(report.hasEarlierData, isTrue);
    expect(report.expenseByCategory.single.label, 'Makan');
  });

  test('finished month compares expense with the previous month', () {
    final report = MonthlyReportBuilder.build(
      month: DateTime(2026, 11),
      transactions: transactions,
      budgets: const [],
      now: DateTime(2026, 12, 5),
    );
    final titles = report.insights.map((item) => item.title).toList();

    expect(titles, contains('Bulan ini surplus'));
    expect(titles, contains('Pengeluaran naik 150%'));
    expect(titles, contains('Terbesar: Makan'));
  });

  test('running month averages expense over the days passed so far', () {
    final report = MonthlyReportBuilder.build(
      month: DateTime(2026, 11),
      transactions: transactions,
      budgets: const [],
      now: DateTime(2026, 11, 20),
    );

    expect(report.averageDailyExpense, 12500);
  });

  test('month without activity has no insights', () {
    final report = MonthlyReportBuilder.build(
      month: DateTime(2026, 12),
      transactions: transactions,
      budgets: const [],
      now: DateTime(2026, 12, 5),
    );

    expect(report.hasActivity, isFalse);
    expect(report.transactions, isEmpty);
    expect(report.insights, isEmpty);
    expect(report.hasEarlierData, isTrue);
  });

  test('exceeded budget of the month becomes a warning insight', () {
    final budget = BudgetProgress(
      budget: BudgetEntry(
        id: 1,
        month: '2026-11',
        limitAmount: 200000,
        createdAt: _stamp,
        updatedAt: _stamp,
      ),
      label: 'Budget bulanan',
      spent: 250000,
      status: BudgetStatus.exceeded,
    );
    final report = MonthlyReportBuilder.build(
      month: DateTime(2026, 11),
      transactions: transactions,
      budgets: [budget],
      now: DateTime(2026, 12, 5),
    );
    final insight = report.insights.firstWhere(
      (item) => item.title == 'Budget terlampaui',
    );

    expect(insight.tone, MonthlyInsightTone.warning);
  });

  test('hidden amounts never leak into insight messages', () {
    final report = MonthlyReportBuilder.build(
      month: DateTime(2026, 11),
      transactions: transactions,
      budgets: const [],
      now: DateTime(2026, 12, 5),
      hideAmounts: true,
    );

    for (final insight in report.insights) {
      expect(insight.message, isNot(contains('250.000')));
      expect(insight.message, isNot(contains('1.000.000')));
    }
  });
}
