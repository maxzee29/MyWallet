import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/app_providers.dart';
import '../../app/theme/app_spacing.dart';
import '../../data/repositories/app_models.dart';
import '../../l10n/app_text.dart';
import '../../shared/components/insight_card.dart';
import '../analytics/analytics_page.dart';
import '../monthly/monthly_report_page.dart';
import 'widgets/dashboard_history_section.dart';
import 'widgets/dashboard_overview.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key, this.onOpenReport, this.onOpenWallets});

  final VoidCallback? onOpenReport;
  final VoidCallback? onOpenWallets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);
    final settings = ref
        .watch(appSettingsProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    final hideBalance = settings?.hideBalance ?? false;

    return summary.when(
      data: (data) => SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.xl,
                AppSpacing.screen,
                AppSpacing.contentBottomInset,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DashboardGreeting(userName: settings?.userName),
                    const SizedBox(height: AppSpacing.xl),
                    DashboardBalanceCard(
                      totalBalance: data.totalBalance,
                      monthlyExpense: data.monthlyExpense,
                      walletCount: data.walletCount,
                      hideBalance: hideBalance,
                      onToggleVisibility: () {
                        ref
                            .read(settingsRepositoryProvider)
                            .setHideBalance(!hideBalance);
                      },
                      onOpenWallets: onOpenWallets,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    DashboardMonthCard(
                      summary: data,
                      hideBalance: hideBalance,
                      onSetBudget: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) =>
                              const Scaffold(body: AnalyticsPage()),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    InsightCard(
                      title: _insightTitle(data),
                      message: _insightMessage(data),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    DashboardHistorySection(
                      hideBalance: hideBalance,
                      onSeeAll:
                          onOpenReport ??
                          (() => MonthlyReportPage.open(context)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      loading: () => const Center(child: Text('Memuat ringkasan')),
      error: (_, _) => const Center(child: Text('Ringkasan belum bisa dimuat')),
    );
  }

  String _insightTitle(DashboardSummary summary) {
    if (summary.recentTransactions.isEmpty) {
      return 'Ringkasan belum tersedia';
    }
    if (summary.budgetLimit > 0 && summary.budgetRatio >= 1) {
      return 'Budget terlampaui';
    }
    if (summary.topExpenseCategory != null) {
      return 'Pengeluaran terbesar: ${summary.topExpenseCategory}';
    }
    return 'Keuangan bulan ini tercatat';
  }

  String _insightMessage(DashboardSummary summary) {
    if (summary.recentTransactions.isEmpty) {
      return 'Tambahkan transaksi pertama untuk mulai melihat ringkasan keuanganmu.';
    }
    if (summary.budgetLimit > 0) {
      final percent = (summary.budgetRatio * 100).round();
      return summary.hasMonthlyBudget
          ? 'Budget bulan ini sudah terpakai $percent%.'
          : 'Budget kategori sudah terpakai $percent%.';
    }
    if (summary.netCashflow >= 0) {
      return 'Pemasukan bulan ini lebih besar atau sama dengan pengeluaran.';
    }
    return 'Pengeluaran bulan ini lebih besar dari pemasukan.';
  }
}
