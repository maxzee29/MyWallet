import '../../core/enums/budget_status.dart';
import '../../core/enums/transaction_type.dart';
import '../../core/formatters/currency_formatter.dart';
import '../../core/formatters/date_formatter.dart';
import '../../core/formatters/report_date_formatter.dart';
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
    DateTime? now,
    bool hideAmounts = false,
  }) {
    final today = now ?? DateTime.now();
    final start = DateFormatter.startOfMonth(month);
    final end = DateTime(start.year, start.month + 1);
    final previousStart = DateTime(start.year, start.month - 1);

    final current = <TransactionDetail>[];
    final previous = <TransactionDetail>[];
    var hasEarlierData = false;

    for (final item in transactions) {
      final date = item.transaction.date;
      if (date.isBefore(start)) {
        hasEarlierData = true;
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

    final expenseByCategory = _expenseByCategory(expenses);

    final insights = income == 0 && expense == 0
        ? const <MonthlyInsight>[]
        : _insights(
            start: start,
            income: income,
            expense: expense,
            previousExpense: previousExpense,
            averageDailyExpense: averageDailyExpense,
            inProgress: isCurrentMonth && today.day < daysInMonth,
            expenseByCategory: expenseByCategory,
            expenses: expenses,
            budgets: budgets,
            hideAmounts: hideAmounts,
          );

    return MonthlyReport(
      month: start,
      income: income,
      expense: expense,
      previousIncome: previousIncome,
      previousExpense: previousExpense,
      averageDailyExpense: averageDailyExpense,
      expenseByCategory: expenseByCategory,
      transactions: current,
      insights: insights,
      hasEarlierData: hasEarlierData,
    );
  }

  static int _sum(Iterable<TransactionDetail> items, TransactionType type) {
    return items
        .where((item) => item.type == type)
        .fold<int>(0, (total, item) => total + item.transaction.amount);
  }

  static List<CategoryAmount> _expenseByCategory(
    List<TransactionDetail> expenses,
  ) {
    final byCategory = <int, CategoryAmount>{};
    for (final item in expenses) {
      final category = item.category;
      final key = category?.id ?? -1;
      final existing = byCategory[key];
      byCategory[key] = CategoryAmount(
        label: category?.name ?? 'Tanpa kategori',
        amount: (existing?.amount ?? 0) + item.transaction.amount,
        colorValue: category?.colorValue ?? 0xFF64748B,
      );
    }

    final items = byCategory.values.toList();
    items.sort((a, b) => b.amount.compareTo(a.amount));
    return items;
  }

  static List<MonthlyInsight> _insights({
    required DateTime start,
    required int income,
    required int expense,
    required int previousExpense,
    required int averageDailyExpense,
    required bool inProgress,
    required List<CategoryAmount> expenseByCategory,
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
    if (expense > 0 && expenseByCategory.isNotEmpty) {
      final top = expenseByCategory.first;
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
