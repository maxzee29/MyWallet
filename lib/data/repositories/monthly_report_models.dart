import '../local/database/app_database.dart';
import 'app_models.dart';

enum MonthlyInsightTone { positive, neutral, warning }

class MonthlyInsight {
  const MonthlyInsight({
    required this.title,
    required this.message,
    required this.tone,
  });

  final String title;
  final String message;
  final MonthlyInsightTone tone;
}

class MonthlyCategoryTotal {
  const MonthlyCategoryTotal({
    required this.label,
    required this.amount,
    required this.colorValue,
    required this.count,
    this.category,
    this.isGroup = false,
  });

  final CategoryEntry? category;
  final String label;
  final int amount;
  final int colorValue;
  final int count;

  /// Benar jika item ini gabungan satu grup kategori, bukan satu kategori.
  final bool isGroup;
}

class MonthlyDayActivity {
  const MonthlyDayActivity({
    this.income = 0,
    this.expense = 0,
    this.transfer = 0,
    this.count = 0,
  });

  final int income;
  final int expense;
  final int transfer;
  final int count;
}

class MonthlyReport {
  const MonthlyReport({
    required this.month,
    required this.income,
    required this.expense,
    required this.previousIncome,
    required this.previousExpense,
    required this.previousIncomeComparable,
    required this.previousExpenseComparable,
    required this.inProgress,
    required this.averageDailyExpense,
    required this.averageDailyIncome,
    required this.daysCounted,
    required this.expenseCategories,
    required this.incomeCategories,
    required this.expenseGroups,
    required this.incomeGroups,
    required this.weeklyExpense,
    required this.weeklyIncome,
    required this.dayActivity,
    required this.transactions,
    required this.insights,
    required this.hasEarlierData,
    required this.availableMonths,
  });

  final DateTime month;
  final int income;
  final int expense;
  final int previousIncome;
  final int previousExpense;

  /// Total bulan sebelumnya untuk pembanding yang adil. Saat bulan masih
  /// berjalan, hanya sampai tanggal yang sama dengan hari ini.
  final int previousIncomeComparable;
  final int previousExpenseComparable;
  final bool inProgress;
  final int averageDailyExpense;
  final int averageDailyIncome;
  final int daysCounted;
  final List<MonthlyCategoryTotal> expenseCategories;
  final List<MonthlyCategoryTotal> incomeCategories;
  final List<MonthlyCategoryTotal> expenseGroups;
  final List<MonthlyCategoryTotal> incomeGroups;
  final List<int> weeklyExpense;
  final List<int> weeklyIncome;
  final Map<int, MonthlyDayActivity> dayActivity;
  final List<TransactionDetail> transactions;
  final List<MonthlyInsight> insights;
  final bool hasEarlierData;
  final List<DateTime> availableMonths;

  int get net => income - expense;

  bool get hasActivity => income > 0 || expense > 0;
}
