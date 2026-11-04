import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_shadows.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/enums/transaction_type.dart';
import '../../../core/formatters/currency_formatter.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../../core/formatters/report_date_formatter.dart';
import '../../../data/repositories/app_models.dart';
import '../../../shared/helpers/category_icon_mapper.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/pressable_surface.dart';
import '../../monthly/widgets/monthly_transaction_actions.dart';
import '../../transactions/widgets/transaction_filter_chips.dart';

/// Riwayat transaksi di Beranda: filter jenis, kartu per hari dengan total
/// harian, dan baris transaksi berikon.
class DashboardHistorySection extends ConsumerStatefulWidget {
  const DashboardHistorySection({
    super.key,
    required this.hideBalance,
    required this.onSeeAll,
  });

  final bool hideBalance;
  final VoidCallback onSeeAll;

  @override
  ConsumerState<DashboardHistorySection> createState() =>
      _DashboardHistorySectionState();
}

class _DashboardHistorySectionState
    extends ConsumerState<DashboardHistorySection> {
  static const _filterLabels = ['Semua', 'Pemasukan', 'Pengeluaran', 'Transfer'];
  static const _maxItems = 15;

  int _filterIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.colorScheme.brightness == Brightness.dark;
    final transactions = ref.watch(transactionDetailsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.receipt_long_rounded,
              color: isDark ? AppColors.softMint : AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Riwayat Transaksi',
                style: theme.textTheme.headlineSmall,
              ),
            ),
            PressableSurface(
              onTap: widget.onSeeAll,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: Text(
                  'Lihat semua',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: isDark ? AppColors.softMint : AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        TransactionFilterChips(
          labels: _filterLabels,
          selectedIndex: _filterIndex,
          onChanged: (index) => setState(() => _filterIndex = index),
        ),
        const SizedBox(height: AppSpacing.lg),
        transactions.when(
          data: (items) => _buildList(context, items),
          loading: () => const SizedBox(height: AppSpacing.xxl),
          error: (_, _) => Text(
            'Riwayat belum bisa dimuat.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildList(BuildContext context, List<TransactionDetail> all) {
    final type = switch (_filterIndex) {
      1 => TransactionType.income,
      2 => TransactionType.expense,
      3 => TransactionType.transfer,
      _ => null,
    };
    final filtered = type == null
        ? all
        : all.where((item) => item.type == type).toList();
    final visible = filtered.take(_maxItems).toList();

    if (visible.isEmpty) {
      return _EmptyCard(
        title: all.isEmpty ? 'Belum ada transaksi' : 'Tidak ada transaksi',
        message: all.isEmpty
            ? 'Tambahkan transaksi pertama untuk mulai melihat riwayat keuanganmu.'
            : 'Belum ada transaksi untuk filter yang dipilih.',
      );
    }

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

    return Column(
      children: [
        for (final day in days) ...[
          _DayCard(
            date: day,
            items: groups[day]!,
            hideBalance: widget.hideBalance,
            onItemTap: (item) => showTransactionDetailSheet(
              context,
              ref,
              item,
              widget.hideBalance,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (filtered.length > _maxItems)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Center(
              child: PressableSurface(
                onTap: widget.onSeeAll,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    'Lihat semua transaksi',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.colorScheme.brightness;
    final isDark = brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(
          color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle,
        ),
        boxShadow: AppShadows.soft(brightness),
      ),
      child: EmptyState(
        compact: true,
        icon: Icons.receipt_long_rounded,
        title: title,
        message: message,
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.date,
    required this.items,
    required this.hideBalance,
    required this.onItemTap,
  });

  final DateTime date;
  final List<TransactionDetail> items;
  final bool hideBalance;
  final ValueChanged<TransactionDetail> onItemTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.colorScheme.brightness;
    final isDark = brightness == Brightness.dark;

    var income = 0;
    var expense = 0;
    var hasTransfer = false;
    for (final item in items) {
      final amount = item.transaction.amount;
      switch (item.type) {
        case TransactionType.income:
          income += amount;
        case TransactionType.expense:
          expense += amount;
        case TransactionType.transfer:
          hasTransfer = true;
      }
    }
    final net = income - expense;

    String pillText;
    Color pillColor;
    if (income == 0 && expense == 0 && hasTransfer) {
      pillText = 'Transfer';
      pillColor = AppColors.infoBlue;
    } else {
      final sign = net < 0 ? '-' : (net > 0 ? '+' : '');
      pillText =
          '$sign${CurrencyFormatter.rupiah(net.abs(), hidden: hideBalance)}';
      pillColor = net < 0
          ? AppColors.expenseRed
          : (net > 0 ? AppColors.incomeGreen : AppColors.infoBlue);
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(
          color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle,
        ),
        boxShadow: AppShadows.soft(brightness),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceSoft
                        : AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    Icons.calendar_month_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    ReportDateFormatter.fullDayLong(date),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: pillColor.withValues(alpha: isDark ? 0.18 : 0.10),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    pillText,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: pillColor,
                      fontWeight: FontWeight.w900,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (var index = 0; index < items.length; index++) ...[
            if (index > 0)
              Padding(
                padding: const EdgeInsets.only(left: 84),
                child: Divider(
                  height: 1,
                  color: isDark
                      ? AppColors.darkBorderSubtle
                      : AppColors.borderSubtle,
                ),
              ),
            _HistoryRow(
              detail: items[index],
              hideBalance: hideBalance,
              onTap: () => onItemTap(items[index]),
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.detail,
    required this.hideBalance,
    required this.onTap,
  });

  final TransactionDetail detail;
  final bool hideBalance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.colorScheme.brightness == Brightness.dark;
    final type = detail.type;
    final isTransfer = type == TransactionType.transfer;

    final accent = switch (type) {
      TransactionType.income => AppColors.incomeGreen,
      TransactionType.expense => AppColors.expenseRed,
      TransactionType.transfer => AppColors.infoBlue,
    };
    final sign = switch (type) {
      TransactionType.income => '+',
      TransactionType.expense => '-',
      TransactionType.transfer => '',
    };

    final note = detail.transaction.note?.trim();
    final hasNote = note != null && note.isNotEmpty;
    final label = isTransfer ? 'Transfer' : detail.category?.name ?? 'Transaksi';
    final title = hasNote ? note : label;
    final walletLabel = isTransfer
        ? '${detail.wallet.name} → ${detail.transferWallet?.name ?? 'Dompet'}'
        : detail.wallet.name;
    final subtitle = [
      label,
      walletLabel,
      ReportDateFormatter.time(detail.transaction.date),
    ].join(' • ');

    final IconData icon;
    if (isTransfer) {
      icon = Icons.swap_horiz_rounded;
    } else if (detail.category != null) {
      icon = categoryIconForEntry(detail.category);
    } else {
      icon = Icons.category_rounded;
    }

    return PressableSurface(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: isDark ? 0.18 : 0.10),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Icon(icon, color: accent, size: 26),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              '$sign${CurrencyFormatter.rupiah(detail.transaction.amount, hidden: hideBalance)}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: accent,
                fontWeight: FontWeight.w900,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
