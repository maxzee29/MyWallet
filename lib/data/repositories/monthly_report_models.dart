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

class MonthlyReport {
  const MonthlyReport({
    required this.month,
    required this.income,
    required this.expense,
    required this.previousIncome,
    required this.previousExpense,
    required this.averageDailyExpense,
    required this.expenseByCategory,
    required this.transactions,
    required this.insights,
    required this.hasEarlierData,
  });

  final DateTime month;
  final int income;
  final int expense;
  final int previousIncome;
  final int previousExpense;
  final int averageDailyExpense;
  final List<CategoryAmount> expenseByCategory;
  final List<TransactionDetail> transactions;
  final List<MonthlyInsight> insights;
  final bool hasEarlierData;

  int get net => income - expense;

  bool get hasActivity => income > 0 || expense > 0;
}
