import '../../core/enums/budget_status.dart';
import '../../core/enums/transaction_type.dart';
import '../../core/formatters/currency_formatter.dart';
import '../../core/formatters/date_formatter.dart';
import '../../core/formatters/report_date_formatter.dart';
import '../local/database/app_database.dart';
import 'app_models.dart';
import 'monthly_report_models.dart';

/// Builds a [MonthlyReport] from already-loaded local data.
///
/// This is pure logic: it never touches the database or the network.
/// Transfers are ignored for income and expense totals.
class MonthlyReportBuilder {
  MonthlyReportBuilder._();

  static MonthlyReport build({
    required DateTime month,
    required List<TransactionDetail> transactions,
    required List<BudgetProgress> budgets,
    int? walletId,
    DateTime? now,
    bool hideAmounts = false,
  }) {
    final today = now ?? DateTime.now();
    final start = DateFormatter.startOfMonth(month);
    final end = DateTime(start.year, start.month + 1);
    final previousStart = DateTime(start.year, start.month - 1);
    final currentMonthStart = DateFormatter.startOfMonth(today);

    // Navigasi bulan memakai semua data, tidak terpengaruh filter dompet.
    final monthSet = <DateTime>{currentMonthStart, start};
    var hasEarlierData = false;
    for (final item in transactions) {
      final date = item.transaction.date;
      final itemMonth = DateTime(date.year, date.month);
      if (!itemMonth.isAfter(currentMonthStart)) monthSet.add(itemMonth);
      if (date.isBefore(start)) hasEarlierData = true;
    }
    final availableMonths = monthSet.toList();
    availableMonths.sort((a, b) => b.compareTo(a));

    final scoped = walletId == null
        ? transactions
        : transactions
              .where(
                (item) =>
                    item.transaction.walletId == walletId ||
                    item.transaction.transferWalletId == walletId,
              )
              .toList();

    final current = <TransactionDetail>[];
    final previous = <TransactionDetail>[];
    for (final item in scoped) {
      final date = item.transaction.date;
      if (date.isBefore(start)) {
        if (!date.isBefore(previousStart)) previous.add(item);
      } else if (date.isBefore(end)) {
        current.add(item);
      }
    }

    current.sort((a, b) {
      final byDate = b.transaction.date.compareTo(a.transaction.date);
      if (byDate != 0) return byDate;
      return b.transaction.id.compareTo(a.transaction.id);
    });

    final expenses = current
        .where((item) => item.type == TransactionType.expense)
        .toList();
    final incomes = current
        .where((item) => item.type == TransactionType.income)
        .toList();
    final income = _sum(current, TransactionType.income);
    final expense = _sum(current, TransactionType.expense);
    final previousIncome = _sum(previous, TransactionType.income);
    final previousExpense = _sum(previous, TransactionType.expense);

    final isCurrentMonth =
        today.year == start.year && today.month == start.month;
    final daysInMonth = DateTime(start.year, start.month + 1, 0).day;
    final daysCounted = isCurrentMonth ? today.day : daysInMonth;
    final averageDailyExpense = daysCounted > 0
        ? (expense / daysCounted).round()
        : 0;
    final averageDailyIncome = daysCounted > 0
        ? (income / daysCounted).round()
        : 0;

    final expenseCategories = _categoryTotals(expenses);
    final incomeCategories = _categoryTotals(incomes);
    final expenseGroups = _groupTotals(expenses);
    final incomeGroups = _groupTotals(incomes);

    final inProgress = isCurrentMonth && today.day < daysInMonth;
    final comparable = inProgress
        ? previous.where((item) => item.transaction.date.day <= today.day)
        : previous;
    final previousIncomeComparable = _sum(comparable, TransactionType.income);
    final previousExpenseComparable = _sum(comparable, TransactionType.expense);

    final weekCount = (daysInMonth / 7).ceil();
    final weeklyExpense = List<int>.filled(weekCount, 0);
    final weeklyIncome = List<int>.filled(weekCount, 0);
    final dayActivity = <int, MonthlyDayActivity>{};
    for (final item in current) {
      final day = item.transaction.date.day;
      final amount = item.transaction.amount;
      final type = item.type;
      final bucket = (day - 1) ~/ 7;
      if (type == TransactionType.expense) weeklyExpense[bucket] += amount;
      if (type == TransactionType.income) weeklyIncome[bucket] += amount;

      final existing = dayActivity[day];
      dayActivity[day] = MonthlyDayActivity(
        income:
            (existing?.income ?? 0) +
            (type == TransactionType.income ? amount : 0),
        expense:
            (existing?.expense ?? 0) +
            (type == TransactionType.expense ? amount : 0),
        transfer:
            (existing?.transfer ?? 0) +
            (type == TransactionType.transfer ? amount : 0),
        count: (existing?.count ?? 0) + 1,
      );
    }

    final insights = income == 0 && expense == 0
        ? const <MonthlyInsight>[]
        : _insights(
            start: start,
            income: income,
            expense: expense,
            previousExpense: previousExpense,
            averageDailyExpense: averageDailyExpense,
            inProgress: inProgress,
            expenseCategories: expenseCategories,
            expenses: expenses,
            // Budget berlaku untuk semua dompet, jadi dilewati saat difilter.
            budgets: walletId == null ? budgets : const <BudgetProgress>[],
            hideAmounts: hideAmounts,
          );

    return MonthlyReport(
      month: start,
      income: income,
      expense: expense,
      previousIncome: previousIncome,
      previousExpense: previousExpense,
      previousIncomeComparable: previousIncomeComparable,
      previousExpenseComparable: previousExpenseComparable,
      inProgress: inProgress,
      averageDailyExpense: averageDailyExpense,
      averageDailyIncome: averageDailyIncome,
      daysCounted: daysCounted,
      expenseCategories: expenseCategories,
      incomeCategories: incomeCategories,
      expenseGroups: expenseGroups,
      incomeGroups: incomeGroups,
      weeklyExpense: weeklyExpense,
      weeklyIncome: weeklyIncome,
      dayActivity: dayActivity,
      transactions: current,
      insights: insights,
      hasEarlierData: hasEarlierData,
      availableMonths: availableMonths,
    );
  }

  static int _sum(Iterable<TransactionDetail> items, TransactionType type) {
    return items
        .where((item) => item.type == type)
        .fold<int>(0, (total, item) => total + item.transaction.amount);
  }

  static List<MonthlyCategoryTotal> _categoryTotals(
    List<TransactionDetail> items,
  ) {
    final amounts = <int, int>{};
    final counts = <int, int>{};
    final categories = <int, CategoryEntry?>{};
    for (final item in items) {
      final category = item.category;
      final key = category?.id ?? -1;
      amounts[key] = (amounts[key] ?? 0) + item.transaction.amount;
      counts[key] = (counts[key] ?? 0) + 1;
      categories[key] = category;
    }

    final totals = <MonthlyCategoryTotal>[];
    for (final entry in amounts.entries) {
      final category = categories[entry.key];
      totals.add(
        MonthlyCategoryTotal(
          category: category,
          label: category?.name ?? 'Tanpa kategori',
          amount: entry.value,
          colorValue: category?.colorValue ?? 0xFF64748B,
          count: counts[entry.key] ?? 0,
        ),
      );
    }
    totals.sort((a, b) => b.amount.compareTo(a.amount));
    return totals;
  }

  static List<MonthlyCategoryTotal> _groupTotals(
    List<TransactionDetail> items,
  ) {
    final amounts = <String, int>{};
    final counts = <String, int>{};
    final colors = <String, int>{};
    for (final item in items) {
      final category = item.category;
      final key = category?.groupName ?? 'Tanpa kategori';
      amounts[key] = (amounts[key] ?? 0) + item.transaction.amount;
      counts[key] = (counts[key] ?? 0) + 1;
      colors[key] ??= category?.colorValue ?? 0xFF64748B;
    }

    final totals = <MonthlyCategoryTotal>[];
    for (final entry in amounts.entries) {
      totals.add(
        MonthlyCategoryTotal(
          label: entry.key,
          amount: entry.value,
          colorValue: colors[entry.key] ?? 0xFF64748B,
          count: counts[entry.key] ?? 0,
          isGroup: true,
        ),
      );
    }
    totals.sort((a, b) => b.amount.compareTo(a.amount));
    return totals;
  }

  static List<MonthlyInsight> _insights({
    required DateTime start,
    required int income,
    required int expense,
    required int previousExpense,
    required int averageDailyExpense,
    required bool inProgress,
    required List<MonthlyCategoryTotal> expenseCategories,
    required List<TransactionDetail> expenses,
    required List<BudgetProgress> budgets,
    required bool hideAmounts,
  }) {
    String money(int value) =>
        CurrencyFormatter.rupiah(value, hidden: hideAmounts);

    final insights = <MonthlyInsight>[];
    final net = income - expense;

    // 1. Hasil bulan ini.
    if (net > 0) {
      final rate = (net / income * 100).round();
      insights.add(
        MonthlyInsight(
          title: 'Bulan ini surplus',
          message:
              'Pemasukan lebih besar ${money(net)} dari pengeluaran. '
              'Kamu menyisihkan $rate% dari pemasukan.',
          tone: MonthlyInsightTone.positive,
        ),
      );
    } else if (net == 0) {
      insights.add(
        const MonthlyInsight(
          title: 'Pemasukan dan pengeluaran seimbang',
          message: 'Tidak ada selisih pada bulan ini.',
          tone: MonthlyInsightTone.neutral,
        ),
      );
    } else {
      insights.add(
        MonthlyInsight(
          title: 'Pengeluaran melebihi pemasukan',
          message:
              'Defisit ${money(-net)} bulan ini. '
              'Tinjau kategori terbesar untuk mencari yang bisa dikurangi.',
          tone: MonthlyInsightTone.warning,
        ),
      );
    }

    // 2. Budget pada bulan yang dipilih.
    final monthKey = DateFormatter.monthKey(start);
    final monthBudgets = budgets
        .where((item) => item.budget.month == monthKey)
        .toList();
    if (monthBudgets.isNotEmpty) {
      final exceeded = monthBudgets
          .where((item) => item.status == BudgetStatus.exceeded)
          .toList();
      final nearLimit = monthBudgets
          .where((item) => item.status == BudgetStatus.nearLimit)
          .toList();

      if (exceeded.isNotEmpty) {
        insights.add(
          MonthlyInsight(
            title: 'Budget terlampaui',
            message: '${_joinLabels(exceeded)} melewati batas yang kamu atur.',
            tone: MonthlyInsightTone.warning,
          ),
        );
      }
      if (nearLimit.isNotEmpty) {
        insights.add(
          MonthlyInsight(
            title: 'Budget hampir habis',
            message: '${_joinLabels(nearLimit)} sudah terpakai lebih dari 80%.',
            tone: MonthlyInsightTone.warning,
          ),
        );
      }
      if (exceeded.isEmpty && nearLimit.isEmpty) {
        insights.add(
          const MonthlyInsight(
            title: 'Budget aman',
            message: 'Semua budget bulan ini masih dalam batas.',
            tone: MonthlyInsightTone.positive,
          ),
        );
      }
    }

    // 3. Perbandingan dengan bulan sebelumnya.
    if (previousExpense > 0) {
      if (inProgress) {
        final percent = (expense / previousExpense * 100).round();
        insights.add(
          MonthlyInsight(
            title: 'Dibanding bulan sebelumnya',
            message:
                'Pengeluaran sejauh ini ${money(expense)}, atau $percent% '
                'dari total bulan sebelumnya (${money(previousExpense)}).',
            tone: percent >= 100
                ? MonthlyInsightTone.warning
                : MonthlyInsightTone.neutral,
          ),
        );
      } else {
        final change = ((expense - previousExpense) / previousExpense * 100)
            .round();
        if (change.abs() < 5) {
          insights.add(
            MonthlyInsight(
              title: 'Pengeluaran stabil',
              message:
                  'Hampir sama dengan bulan sebelumnya '
                  '(${money(previousExpense)}).',
              tone: MonthlyInsightTone.neutral,
            ),
          );
        } else if (change > 0) {
          insights.add(
            MonthlyInsight(
              title: 'Pengeluaran naik $change%',
              message:
                  'Bulan sebelumnya ${money(previousExpense)}, '
                  'bulan ini ${money(expense)}.',
              tone: MonthlyInsightTone.warning,
            ),
          );
        } else {
          insights.add(
            MonthlyInsight(
              title: 'Pengeluaran turun ${-change}%',
              message:
                  'Bulan sebelumnya ${money(previousExpense)}, '
                  'bulan ini ${money(expense)}.',
              tone: MonthlyInsightTone.positive,
            ),
          );
        }
      }
    }

    // 4. Kategori terbesar.
    if (expense > 0 && expenseCategories.isNotEmpty) {
      final top = expenseCategories.first;
      final share = (top.amount / expense * 100).round();
      insights.add(
        MonthlyInsight(
          title: 'Terbesar: ${top.label}',
          message:
              '${money(top.amount)}, atau $share% dari total pengeluaran.',
          tone: MonthlyInsightTone.neutral,
        ),
      );
    }

    // 5. Pola harian.
    if (expense > 0) {
      final byDay = <DateTime, int>{};
      for (final item in expenses) {
        final day = DateFormatter.startOfDay(item.transaction.date);
        byDay[day] = (byDay[day] ?? 0) + item.transaction.amount;
      }
      final busiest = byDay.entries.reduce(
        (a, b) => b.value > a.value ? b : a,
      );
      insights.add(
        MonthlyInsight(
          title: 'Pengeluaran harian',
          message:
              'Rata-rata ${money(averageDailyExpense)} per hari. '
              'Hari terboros ${ReportDateFormatter.dayMonth(busiest.key)} '
              '(${money(busiest.value)}).',
          tone: MonthlyInsightTone.neutral,
        ),
      );
    }

    // 6. Transaksi tunggal terbesar.
    if (expenses.length >= 2) {
      final largest = expenses.reduce(
        (a, b) => b.transaction.amount > a.transaction.amount ? b : a,
      );
      insights.add(
        MonthlyInsight(
          title: 'Transaksi terbesar',
          message:
              '${money(largest.transaction.amount)} untuk '
              '${largest.category?.name ?? 'transaksi'} pada '
              '${ReportDateFormatter.dayMonth(largest.transaction.date)}.',
          tone: MonthlyInsightTone.neutral,
        ),
      );
    }

    return insights;
  }

  static String _joinLabels(List<BudgetProgress> items) {
    final labels = items.map((item) => item.label).toList();
    if (labels.length <= 3) return labels.join(', ');
    return '${labels.take(3).join(', ')}, dan ${labels.length - 3} lainnya';
  }
}
