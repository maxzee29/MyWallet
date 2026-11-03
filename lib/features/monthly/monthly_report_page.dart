import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/app_providers.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_shadows.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/enums/transaction_type.dart';
import '../../core/formatters/currency_formatter.dart';
import '../../core/formatters/date_formatter.dart';
import '../../core/formatters/report_date_formatter.dart';
import '../../data/repositories/app_models.dart';
import '../../data/repositories/monthly_report_models.dart';
import '../../shared/components/add_transaction_sheet.dart';
import '../../shared/components/section_header.dart';
import '../../shared/helpers/category_icon_mapper.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/pressable_surface.dart';
import '../transactions/widgets/period_selector.dart';
import '../transactions/widgets/transaction_tile.dart';
import 'monthly_report_providers.dart';
import 'widgets/monthly_insight_card.dart';

class MonthlyReportPage extends ConsumerStatefulWidget {
  const MonthlyReportPage({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const Scaffold(body: MonthlyReportPage()),
      ),
    );
  }

  @override
  ConsumerState<MonthlyReportPage> createState() => _MonthlyReportPageState();
}

class _MonthlyReportPageState extends ConsumerState<MonthlyReportPage> {
  static const _tabLabels = ['Insight', 'Catatan'];

  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final report = ref.watch(monthlyReportProvider);
    final hideBalance = ref
        .watch(appSettingsProvider)
        .maybeWhen(
          data: (value) => value?.hideBalance ?? false,
          orElse: () => false,
        );

    return SafeArea(
      bottom: false,
      child: report.when(
        data: (data) {
          final currentMonth = DateFormatter.startOfMonth(DateTime.now());
          final canGoNext = data.month.isBefore(currentMonth);
          final controller = ref.read(reportMonthProvider.notifier);

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.xl,
              AppSpacing.screen,
              AppSpacing.contentBottomInset,
            ),
            children: [
              Text(
                'Laporan Bulanan',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Lihat insight dan catatan keuangan untuk setiap bulan.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),
              _MonthNavigator(
                label: DateFormatter.monthLabel(data.month),
                canGoPrevious: data.hasEarlierData,
                canGoNext: canGoNext,
                onPrevious: controller.previous,
                onNext: controller.next,
              ),
              const SizedBox(height: AppSpacing.lg),
              _SummaryCard(report: data, hideBalance: hideBalance),
              const SizedBox(height: AppSpacing.xl),
              PeriodSelector(
                labels: _tabLabels,
                selectedIndex: _tabIndex,
                onChanged: (index) => setState(() => _tabIndex = index),
              ),
              const SizedBox(height: AppSpacing.xxl),
              ...(_tabIndex == 0
                  ? _insightTab(data, hideBalance)
                  : _recordsTab(data, hideBalance)),
            ],
          );
        },
        loading: () => const Center(child: Text('Memuat laporan')),
        error: (_, _) => const Center(child: Text('Laporan belum bisa dimuat')),
      ),
    );
  }

  List<Widget> _insightTab(MonthlyReport data, bool hideBalance) {
    final monthLabel = DateFormatter.monthLabel(data.month);

    if (!data.hasActivity) {
      return [
        EmptyState(
          icon: Icons.insights_rounded,
          title: 'Belum ada insight',
          message:
              'Catat pemasukan atau pengeluaran di $monthLabel untuk melihat insight.',
        ),
      ];
    }

    return [
      SectionHeader(
        title: 'Insight',
        subtitle: 'Ringkasan otomatis dari catatanmu di $monthLabel.',
      ),
      const SizedBox(height: AppSpacing.lg),
      for (final insight in data.insights) ...[
        MonthlyInsightCard(insight: insight),
        const SizedBox(height: AppSpacing.md),
      ],
      if (data.expenseByCategory.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.lg),
        _CategoryBreakdown(
          items: data.expenseByCategory,
          total: data.expense,
          hideBalance: hideBalance,
        ),
      ],
    ];
  }

  List<Widget> _recordsTab(MonthlyReport data, bool hideBalance) {
    if (data.transactions.isEmpty) {
      return [
        EmptyState(
          icon: Icons.receipt_long_rounded,
          title: 'Belum ada catatan',
          message:
              'Tidak ada transaksi pada ${DateFormatter.monthLabel(data.month)}.',
        ),
      ];
    }

    final groups = <DateTime, List<TransactionDetail>>{};
    for (final item in data.transactions) {
      groups
          .putIfAbsent(DateFormatter.startOfDay(item.transaction.date), () => [])
          .add(item);
    }
    final days = groups.keys.toList();

    return [
      const SectionHeader(
        title: 'Catatan keuangan',
        subtitle: 'Ketuk transaksi untuk mengubahnya.',
      ),
      const SizedBox(height: AppSpacing.lg),
      for (final day in days) ...[
        _DayHeader(date: day, items: groups[day]!, hideBalance: hideBalance),
        const SizedBox(height: AppSpacing.md),
        for (final item in groups[day]!) ...[
          _tile(item, hideBalance),
          const SizedBox(height: AppSpacing.md),
        ],
        const SizedBox(height: AppSpacing.md),
      ],
    ];
  }

  TransactionTile _tile(TransactionDetail detail, bool hideBalance) {
    final isTransfer = detail.type == TransactionType.transfer;
    final title = isTransfer
        ? '${detail.wallet.name} ke ${detail.transferWallet?.name ?? 'Dompet'}'
        : detail.category?.name ?? 'Transaksi';
    final note = detail.transaction.note?.trim();
    final walletLabel = isTransfer ? 'Transfer antar dompet' : detail.wallet.name;
    final subtitle = note == null || note.isEmpty
        ? walletLabel
        : '$walletLabel · $note';

    return TransactionTile(
      title: title,
      subtitle: subtitle,
      timeLabel: ReportDateFormatter.time(detail.transaction.date),
      amount: CurrencyFormatter.rupiah(
        detail.transaction.amount,
        hidden: hideBalance,
      ),
      type: _previewType(detail.type),
      icon: _transactionIcon(detail),
      onTap: () => _edit(detail),
    );
  }

  void _edit(TransactionDetail detail) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.scrim,
      builder: (context) => AddTransactionSheet(transaction: detail),
    );
  }
}

class _MonthNavigator extends StatelessWidget {
  const _MonthNavigator({
    required this.label,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final bool canGoPrevious;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.colorScheme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceSoft : AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle,
        ),
      ),
      child: Row(
        children: [
          _ArrowButton(
            icon: Icons.chevron_left_rounded,
            label: 'Bulan sebelumnya',
            enabled: canGoPrevious,
            onTap: onPrevious,
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium,
            ),
          ),
          _ArrowButton(
            icon: Icons.chevron_right_rounded,
            label: 'Bulan berikutnya',
            enabled: canGoNext,
            onTap: onNext,
          ),
        ],
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.colorScheme.brightness == Brightness.dark;
    final color = enabled
        ? (isDark ? AppColors.softMint : AppColors.primary)
        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.38);

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: PressableSurface(
        enabled: enabled,
        onTap: onTap,
        child: SizedBox(
          width: AppSpacing.iconTile,
          height: AppSpacing.iconTile,
          child: Icon(icon, color: color, size: 28),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.report, required this.hideBalance});

  final MonthlyReport report;
  final bool hideBalance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.colorScheme.brightness;
    final isDark = brightness == Brightness.dark;
    final netColor = report.net >= 0
        ? AppColors.incomeGreen
        : AppColors.expenseRed;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(
          color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle,
        ),
        boxShadow: AppShadows.soft(brightness),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Selisih bulan ini', style: theme.textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormatter.rupiah(report.net, hidden: hideBalance),
              maxLines: 1,
              style: theme.textTheme.displayMedium?.copyWith(
                color: netColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${report.transactions.length} transaksi tercatat',
            style: theme.textTheme.labelSmall,
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: _FlowStat(
                  label: 'Masuk',
                  value: CurrencyFormatter.rupiah(
                    report.income,
                    hidden: hideBalance,
                  ),
                  color: AppColors.incomeGreen,
                ),
              ),
              Container(
                width: AppSpacing.xxs,
                height: AppSpacing.huge,
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkBorderSubtle
                      : AppColors.borderSubtle,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
              Expanded(
                child: _FlowStat(
                  label: 'Keluar',
                  value: CurrencyFormatter.rupiah(
                    report.expense,
                    hidden: hideBalance,
                  ),
                  color: AppColors.expenseRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FlowStat extends StatelessWidget {
  const _FlowStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: AppSpacing.metricDot,
              height: AppSpacing.metricDot,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(label, style: theme.textTheme.labelMedium),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            style: theme.textTheme.titleLarge?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({
    required this.items,
    required this.total,
    required this.hideBalance,
  });

  final List<CategoryAmount> items;
  final int total;
  final bool hideBalance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.colorScheme.brightness;
    final isDark = brightness == Brightness.dark;
    final visible = items.take(5).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(
          color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle,
        ),
        boxShadow: AppShadows.soft(brightness),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pengeluaran per kategori', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Lima kategori dengan pengeluaran terbesar.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          for (var index = 0; index < visible.length; index++) ...[
            _CategoryRow(
              item: visible[index],
              total: total,
              hideBalance: hideBalance,
            ),
            if (index != visible.length - 1)
              const SizedBox(height: AppSpacing.lg),
          ],
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.item,
    required this.total,
    required this.hideBalance,
  });

  final CategoryAmount item;
  final int total;
  final bool hideBalance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.colorScheme.brightness == Brightness.dark;
    final ratio = total <= 0 ? 0.0 : (item.amount / total).clamp(0.0, 1.0);
    final percent = (ratio * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              CurrencyFormatter.rupiah(item.amount, hidden: hideBalance),
              style: theme.textTheme.titleMedium?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            color: Color(item.colorValue),
            backgroundColor: isDark
                ? AppColors.darkSurfaceSoft
                : AppColors.surfaceSoft,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text('$percent% dari pengeluaran', style: theme.textTheme.labelSmall),
      ],
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.date,
    required this.items,
    required this.hideBalance,
  });

  final DateTime date;
  final List<TransactionDetail> items;
  final bool hideBalance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expense = items
        .where((item) => item.type == TransactionType.expense)
        .fold<int>(0, (total, item) => total + item.transaction.amount);

    return Row(
      children: [
        Expanded(
          child: Text(
            ReportDateFormatter.fullDay(date),
            style: theme.textTheme.titleMedium,
          ),
        ),
        if (expense > 0)
          Text(
            'Keluar ${CurrencyFormatter.rupiah(expense, hidden: hideBalance)}',
            style: theme.textTheme.labelMedium,
          ),
      ],
    );
  }
}

TransactionPreviewType _previewType(TransactionType type) {
  switch (type) {
    case TransactionType.income:
      return TransactionPreviewType.income;
    case TransactionType.expense:
      return TransactionPreviewType.expense;
    case TransactionType.transfer:
      return TransactionPreviewType.transfer;
  }
}

IconData _transactionIcon(TransactionDetail detail) {
  if (detail.type == TransactionType.transfer) {
    return Icons.swap_horiz_rounded;
  }
  if (detail.category != null) {
    return categoryIconForEntry(detail.category);
  }
  if (detail.type == TransactionType.income) {
    return Icons.work_rounded;
  }
  return Icons.category_rounded;
}
