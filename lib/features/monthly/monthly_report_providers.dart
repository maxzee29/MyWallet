import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/app_providers.dart';
import '../../core/formatters/date_formatter.dart';
import '../../data/repositories/app_models.dart';
import '../../data/repositories/monthly_report_builder.dart';
import '../../data/repositories/monthly_report_models.dart';

final reportMonthProvider =
    NotifierProvider.autoDispose<ReportMonthController, DateTime>(
      ReportMonthController.new,
    );

class ReportMonthController extends Notifier<DateTime> {
  @override
  DateTime build() {
    return DateFormatter.startOfMonth(DateTime.now());
  }

  void previous() {
    state = DateTime(state.year, state.month - 1);
  }

  void next() {
    final current = DateFormatter.startOfMonth(DateTime.now());
    final candidate = DateTime(state.year, state.month + 1);
    if (candidate.isAfter(current)) return;
    state = candidate;
  }
}

final monthlyReportProvider = Provider.autoDispose<AsyncValue<MonthlyReport>>((
  ref,
) {
  final month = ref.watch(reportMonthProvider);
  final transactions = ref.watch(transactionDetailsProvider);
  final budgets = ref
      .watch(budgetProgressProvider)
      .maybeWhen(
        data: (value) => value,
        orElse: () => const <BudgetProgress>[],
      );
  final hideAmounts = ref
      .watch(appSettingsProvider)
      .maybeWhen(
        data: (value) => value?.hideBalance ?? false,
        orElse: () => false,
      );

  return transactions.whenData(
    (items) => MonthlyReportBuilder.build(
      month: month,
      transactions: items,
      budgets: budgets,
      hideAmounts: hideAmounts,
    ),
  );
});
