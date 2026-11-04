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
import '../../shared/components/section_header.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/pressable_surface.dart';
import '../transactions/widgets/period_selector.dart';
import '../transactions/widgets/transaction_filter_chips.dart';
import '../transactions/widgets/transaction_search_bar.dart';
import 'monthly_report_providers.dart';
import 'widgets/monthly_activity_calendar.dart';
import 'widgets/monthly_category_breakdown.dart';
import 'widgets/monthly_insight_card.dart';
import 'widgets/monthly_summary_carousel.dart';
import 'widgets/monthly_transaction_actions.dart';
import 'widgets/monthly_transaction_widgets.dart';
import 'widgets/monthly_trend_chart.dart';
import 'widgets/monthly_type_overview.dart';

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
  static const _tabLabels = ['Ringkasan', 'Keluar', 'Masuk', 'Catatan'];
  static const _filterLabels = [
    'Semua',
    'Pemasukan',
    'Pengeluaran',
    'Transfer',
  ];

  final TextEditingController _searchController = TextEditingController();

  int _tabIndex = 0;
  int _filterIndex = 0;
  String _query = '';
  bool _groupByGroup = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final report = ref.watch(monthlyReportProvider);
    final walletId = ref.watch(reportWalletProvider);
    final wallets = ref
        .watch(walletBalancesProvider)
        .maybeWhen(
          data: (value) =>
              value.where((item) => !item.wallet.isArchived).toList(),
          orElse: () => const <WalletBalance>[],
        );
    final hideBalance = ref
        .watch(appSettingsProvider)
        .maybeWhen(
          data: (value) => value?.hideBalance ?? false,
          orElse: () => false,
        );

    String walletLabel = 'Semua Dompet';
    for (final item in wallets) {
      if (item.wallet.id == walletId) walletLabel = item.wallet.name;
    }

    return SafeArea(
      bottom: false,
      child: report.when(
        data: (data) {
          final currentMonth = DateFormatter.startOfMonth(DateTime.now());
          final canGoNext = data.month.isBefore(currentMonth);
          final monthController = ref.read(reportMonthProvider.notifier);

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
              _WalletFilterButton(
                label: walletLabel,
                onTap: () => _pickWallet(wallets, walletId),
              ),
              const SizedBox(height: AppSpacing.md),
              _MonthNavigator(
                label: DateFormatter.monthLabel(data.month),
                canGoPrevious: data.hasEarlierData,
                canGoNext: canGoNext,
                onPrevious: monthController.previous,
                onNext: monthController.next,
                onLabelTap: () => _pickMonth(data),
              ),
              const SizedBox(height: AppSpacing.md),
              const _InfoChip(label: 'Transfer tidak dihitung'),
              const SizedBox(height: AppSpacing.lg),
              PeriodSelector(
                labels: _tabLabels,
                selectedIndex: _tabIndex,
                onChanged: (index) => setState(() => _tabIndex = index),
              ),
              const SizedBox(height: AppSpacing.xxl),
              ...switch (_tabIndex) {
                0 => _overviewTab(data, hideBalance),
                1 => _typeTab(data, TransactionType.expense, hideBalance),
                2 => _typeTab(data, TransactionType.income, hideBalance),
                _ => _recordsTab(data, hideBalance),
              },
            ],
          );
        },
        loading: () => const Center(child: Text('Memuat laporan')),
        error: (_, _) => const Center(child: Text('Laporan belum bisa dimuat')),
      ),
    );
  }

  void _pickWallet(List<WalletBalance> wallets, int? selected) {
    showReportOptionsSheet<int?>(
      context: context,
      title: 'Pilih dompet',
      selected: selected,
      options: [
        const ReportOption<int?>(label: 'Semua Dompet', value: null),
        for (final item in wallets)
          ReportOption<int?>(label: item.wallet.name, value: item.wallet.id),
      ],
      onSelected: ref.read(reportWalletProvider.notifier).select,
    );
  }

  void _pickMonth(MonthlyReport data) {
    showReportOptionsSheet<DateTime>(
      context: context,
      title: 'Pilih bulan',
      selected: data.month,
      options: [
        for (final month in data.availableMonths)
          ReportOption<DateTime>(
            label: DateFormatter.monthLabel(month),
            value: month,
          ),
      ],
      onSelected: ref.read(reportMonthProvider.notifier).select,
    );
  }

  List<Widget> _overviewTab(MonthlyReport data, bool hideBalance) {
    final monthLabel = DateFormatter.monthLabel(data.month);

    if (!data.hasActivity) {
      return [
        EmptyState(
          icon: Icons.insights_rounded,
          title: 'Belum ada data',
          message:
              'Catat pemasukan atau pengeluaran di $monthLabel untuk melihat ringkasan dan insight.',
        ),
      ];
    }

    return [
      MonthlySummaryCarousel(report: data, hideBalance: hideBalance),
      const SizedBox(height: AppSpacing.xxl),
      MonthlyTrendChart(report: data, hideBalance: hideBalance),
      const SizedBox(height: AppSpacing.xxl),
      const SectionHeader(
        title: 'Rincian kategori',
        subtitle: 'Ketuk kategori untuk melihat transaksinya.',
      ),
      const SizedBox(height: AppSpacing.lg),
      MonthlyCategoryBreakdown(
        title: 'Pengeluaran teratas',
        icon: Icons.trending_down_rounded,
        accent: AppColors.expenseRed,
        items: data.expenseCategories,
        total: data.expense,
        hideBalance: hideBalance,
        limit: 3,
        onTap: (item) =>
            _showCategory(data, item, TransactionType.expense, hideBalance),
      ),
      const SizedBox(height: AppSpacing.lg),
      MonthlyCategoryBreakdown(
        title: 'Pemasukan teratas',
        icon: Icons.trending_up_rounded,
        accent: AppColors.incomeGreen,
        items: data.incomeCategories,
        total: data.income,
        hideBalance: hideBalance,
        limit: 3,
        onTap: (item) =>
            _showCategory(data, item, TransactionType.income, hideBalance),
      ),
      const SizedBox(height: AppSpacing.xxl),
      SectionHeader(
        title: 'Insight',
        subtitle: 'Ringkasan otomatis dari catatanmu di $monthLabel.',
      ),
      const SizedBox(height: AppSpacing.lg),
      for (final insight in data.insights) ...[
        MonthlyInsightCard(insight: insight),
        const SizedBox(height: AppSpacing.md),
      ],
      const SizedBox(height: AppSpacing.lg),
      MonthlyActivityCalendar(
        report: data,
        onDayTap: (day) => _showDay(data, day, hideBalance),
      ),
    ];
  }

  List<Widget> _typeTab(
    MonthlyReport data,
    TransactionType type,
    bool hideBalance,
  ) {
    final isIncome = type == TransactionType.income;
    final monthLabel = DateFormatter.monthLabel(data.month);
    final total = isIncome ? data.income : data.expense;
    final categories = isIncome
        ? data.incomeCategories
        : data.expenseCategories;

    if (total == 0 && categories.isEmpty) {
      return [
        EmptyState(
          icon: isIncome
              ? Icons.trending_up_rounded
              : Icons.trending_down_rounded,
          title: isIncome ? 'Belum ada pemasukan' : 'Belum ada pengeluaran',
          message: 'Tidak ada data di $monthLabel.',
        ),
      ];
    }

    final items = _groupByGroup
        ? (isIncome ? data.incomeGroups : data.expenseGroups)
        : categories;

    return [
      MonthlyTotalCard(
        label: isIncome ? 'Total Pemasukan' : 'Total Pengeluaran',
        icon: isIncome ? Icons.trending_up_rounded : Icons.trending_down_rounded,
        colors: isIncome
            ? const [AppColors.incomeGreen, Color(0xFF166534)]
            : const [AppColors.expenseRed, Color(0xFF991B1B)],
        current: total,
        previous: isIncome
            ? data.previousIncomeComparable
            : data.previousExpenseComparable,
        inProgress: data.inProgress,
        hideBalance: hideBalance,
      ),
      const SizedBox(height: AppSpacing.lg),
      MonthlyGroupToggle(
        value: _groupByGroup,
        onChanged: (value) => setState(() => _groupByGroup = value),
      ),
      const SizedBox(height: AppSpacing.xl),
      Center(
        child: Text(
          'Ketuk untuk melihat detail',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      MonthlyDonutCard(
        items: items,
        total: total,
        hideBalance: hideBalance,
        onTap: (item) => _showCategory(data, item, type, hideBalance),
      ),
      const SizedBox(height: AppSpacing.xxl),
      MonthlyTrendChart(
        report: data,
        hideBalance: hideBalance,
        fixedType: type,
      ),
      const SizedBox(height: AppSpacing.xxl),
      MonthlyCategoryBreakdown(
        title: _groupByGroup ? 'Detail per Grup' : 'Detail per Kategori',
        icon: isIncome ? Icons.trending_up_rounded : Icons.trending_down_rounded,
        accent: isIncome ? AppColors.incomeGreen : AppColors.expenseRed,
        items: items,
        total: total,
        hideBalance: hideBalance,
        onTap: (item) => _showCategory(data, item, type, hideBalance),
      ),
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

    final type = switch (_filterIndex) {
      1 => TransactionType.income,
      2 => TransactionType.expense,
      3 => TransactionType.transfer,
      _ => null,
    };
    final query = _query.trim().toLowerCase();
    final visible = data.transactions.where((item) {
      if (type != null && item.type != type) return false;
      if (query.isEmpty) return true;

      final haystack = [
        item.category?.name,
        item.wallet.name,
        item.transferWallet?.name,
        item.transaction.note,
      ].whereType<String>().join(' ').toLowerCase();

      return haystack.contains(query);
    }).toList();

    final groups = <DateTime, List<TransactionDetail>>{};
    for (final item in visible) {
      groups
          .putIfAbsent(
            DateFormatter.startOfDay(item.transaction.date),
            () => [],
          )
          .add(item);
    }
    final days = groups.keys.toList();

    return [
      _TypeSummaryCard(
        label: 'Selisih bulan ini',
        total: CurrencyFormatter.rupiah(data.net, hidden: hideBalance),
        color: data.net >= 0 ? AppColors.incomeGreen : AppColors.expenseRed,
        detail:
            'Masuk ${CurrencyFormatter.rupiah(data.income, hidden: hideBalance)} · Keluar ${CurrencyFormatter.rupiah(data.expense, hidden: hideBalance)}',
      ),
      const SizedBox(height: AppSpacing.xxl),
      const SectionHeader(
        title: 'Catatan keuangan',
        subtitle: 'Ketuk untuk detail, tahan untuk menghapus.',
      ),
      const SizedBox(height: AppSpacing.lg),
      _SearchFilterCard(
        controller: _searchController,
        onSearchChanged: (value) => setState(() => _query = value),
        labels: _filterLabels,
        selectedIndex: _filterIndex,
        onFilterChanged: (index) => setState(() => _filterIndex = index),
      ),
      const SizedBox(height: AppSpacing.xl),
      if (visible.isEmpty)
        const EmptyState(
          icon: Icons.search_off_rounded,
          title: 'Tidak ada hasil',
          message: 'Coba ubah kata kunci atau filter jenis transaksi.',
        ),
      for (final day in days) ...[
        _DayHeader(date: day, items: groups[day]!, hideBalance: hideBalance),
        const SizedBox(height: AppSpacing.md),
        for (final item in groups[day]!) ...[
          MonthlyTransactionTile(
            detail: item,
            hideBalance: hideBalance,
            onTap: () => openTransactionDetail(context, item, hideBalance),
            onLongPress: () => confirmDeleteTransaction(context, ref, item),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        const SizedBox(height: AppSpacing.md),
      ],
    ];
  }

  void _showCategory(
    MonthlyReport data,
    MonthlyCategoryTotal total,
    TransactionType type,
    bool hideBalance,
  ) {
    final items = data.transactions.where((item) {
      if (item.type != type) return false;
      if (total.isGroup) {
        return (item.category?.groupName ?? 'Tanpa kategori') == total.label;
      }
      return (item.category?.id ?? -1) == (total.category?.id ?? -1);
    }).toList();

    showMonthlyTransactionsSheet(
      context,
      title: total.label,
      subtitle:
          '${items.length} transaksi · ${CurrencyFormatter.rupiah(total.amount, hidden: hideBalance)} · ${DateFormatter.monthLabel(data.month)}',
      items: items,
      hideBalance: hideBalance,
    );
  }

  void _showDay(MonthlyReport data, int day, bool hideBalance) {
    final items = data.transactions
        .where((item) => item.transaction.date.day == day)
        .toList();
    final date = DateTime(data.month.year, data.month.month, day);

    showMonthlyTransactionsSheet(
      context,
      title: ReportDateFormatter.fullDay(date),
      subtitle: '${items.length} transaksi',
      items: items,
      hideBalance: hideBalance,
    );
  }
}

class _SearchFilterCard extends StatelessWidget {
  const _SearchFilterCard({
    required this.controller,
    required this.onSearchChanged,
    required this.labels,
    required this.selectedIndex,
    required this.onFilterChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSearchChanged;
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.colorScheme.brightness;
    final isDark = brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
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
          TransactionSearchBar(
            controller: controller,
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: AppSpacing.lg),
          TransactionFilterChips(
            labels: labels,
            selectedIndex: selectedIndex,
            onChanged: onFilterChanged,
          ),
        ],
      ),
    );
  }
}

class _WalletFilterButton extends StatelessWidget {
  const _WalletFilterButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.colorScheme.brightness == Brightness.dark;

    return PressableSurface(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceElevated : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.account_balance_wallet_rounded,
              color: isDark ? AppColors.softMint : AppColors.primary,
              size: 22,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
            ),
            Icon(
              Icons.expand_more_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.swap_horiz_rounded,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(label, style: theme.textTheme.labelMedium),
          ],
        ),
      ),
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
    required this.onLabelTap,
  });

  final String label;
  final bool canGoPrevious;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onLabelTap;

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
            child: Semantics(
              button: true,
              label: 'Pilih bulan',
              child: PressableSurface(
                onTap: onLabelTap,
                child: SizedBox(
                  height: AppSpacing.iconTile,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Icon(
                        Icons.expand_more_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
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

class _TypeSummaryCard extends StatelessWidget {
  const _TypeSummaryCard({
    required this.label,
    required this.total,
    required this.color,
    required this.detail,
  });

  final String label;
  final String total;
  final Color color;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.colorScheme.brightness;
    final isDark = brightness == Brightness.dark;

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
          Text(label, style: theme.textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              total,
              maxLines: 1,
              style: theme.textTheme.displayMedium?.copyWith(
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(detail, style: theme.textTheme.labelSmall),
        ],
      ),
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
