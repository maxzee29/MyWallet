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

final _bank = WalletEntry(
  id: 2,
  name: 'Bank',
  type: 'bank',
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
  WalletEntry? wallet,
}) {
  final owner = wallet ?? _wallet;
  return TransactionDetail(
    transaction: TransactionEntry(
      id: id,
      type: type.value,
      amount: amount,
      categoryId: category?.id,
      walletId: owner.id,
      date: date,
      createdAt: _stamp,
      updatedAt: _stamp,
    ),
    wallet: owner,
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
    _transaction(
      id: 5,
      type: TransactionType.expense,
      amount: 50000,
      date: DateTime(2026, 11, 29),
      category: _food,
      wallet: _bank,
    ),
  ];

  MonthlyReport build({
    DateTime? month,
    int? walletId,
    DateTime? now,
    bool hideAmounts = false,
    List<BudgetProgress> budgets = const [],
  }) {
    return MonthlyReportBuilder.build(
      month: month ?? DateTime(2026, 11),
      transactions: transactions,
      budgets: budgets,
      walletId: walletId,
      now: now ?? DateTime(2026, 12, 5),
      hideAmounts: hideAmounts,
    );
  }

  test('totals only count the selected month and ignore transfers', () {
    final report = build();

    expect(report.income, 1000000);
    expect(report.expense, 300000);
    expect(report.net, 700000);
    expect(report.previousExpense, 100000);
    expect(report.transactions.length, 4);
    expect(report.hasEarlierData, isTrue);
    expect(report.expenseCategories.single.label, 'Makan');
    expect(report.expenseCategories.single.amount, 300000);
    expect(report.expenseCategories.single.count, 2);
    expect(report.incomeCategories.single.label, 'Tanpa kategori');
    expect(report.incomeCategories.single.amount, 1000000);
  });

  test('finished month compares expense with the previous month', () {
    final titles = build().insights.map((item) => item.title).toList();

    expect(titles, contains('Bulan ini surplus'));
    expect(titles, contains('Pengeluaran naik 200%'));
    expect(titles, contains('Terbesar: Makan'));
  });

  test('running month averages over the days passed so far', () {
    final report = build(now: DateTime(2026, 11, 20));

    expect(report.daysCounted, 20);
    expect(report.averageDailyExpense, 15000);
    expect(report.averageDailyIncome, 50000);
  });

  test('finished month averages over every day of the month', () {
    final report = build();

    expect(report.daysCounted, 30);
    expect(report.averageDailyExpense, 10000);
  });

  test('weekly totals follow the 7-day buckets of the month', () {
    final report = build();

    expect(report.weeklyExpense, [250000, 0, 0, 0, 50000]);
    expect(report.weeklyIncome, [1000000, 0, 0, 0, 0]);
  });

  test('day activity marks income, expense and transfer days', () {
    final report = build();

    expect(report.dayActivity[2]?.income, 1000000);
    expect(report.dayActivity[5]?.expense, 250000);
    expect(report.dayActivity[6]?.transfer, 500000);
    expect(report.dayActivity[7], isNull);
  });

  test('wallet filter limits totals and records to that wallet', () {
    final bank = build(walletId: 2);
    final cash = build(walletId: 1);

    expect(bank.expense, 50000);
    expect(bank.income, 0);
    expect(bank.transactions.length, 1);
    expect(cash.expense, 250000);
    expect(cash.income, 1000000);
  });

  test('available months include months with data up to the current month', () {
    final report = build();

    expect(report.availableMonths, [
      DateTime(2026, 12),
      DateTime(2026, 11),
      DateTime(2026, 10),
    ]);
  });

  test('month without activity has no insights', () {
    final report = build(month: DateTime(2026, 12));

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
    final insight = build(budgets: [budget]).insights.firstWhere(
      (item) => item.title == 'Budget terlampaui',
    );

    expect(insight.tone, MonthlyInsightTone.warning);
  });

  test('budget insight is skipped when a single wallet is selected', () {
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
    final titles = build(
      walletId: 1,
      budgets: [budget],
    ).insights.map((item) => item.title).toList();

    expect(titles, isNot(contains('Budget terlampaui')));
  });

  test('hidden amounts never leak into insight messages', () {
    final report = build(hideAmounts: true);

    for (final insight in report.insights) {
      expect(insight.message, isNot(contains('250.000')));
      expect(insight.message, isNot(contains('1.000.000')));
    }
  });
}
