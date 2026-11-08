import 'package:flutter/material.dart' hide Text;

import '../../../app/theme/app_accent.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_shadows.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/formatters/currency_formatter.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../../core/formatters/report_date_formatter.dart';
import '../../../data/repositories/app_models.dart';
import '../../../l10n/app_text.dart';
import '../../../shared/widgets/pressable_surface.dart';

/// Sapaan sesuai waktu, tanggal hari ini, dan avatar berinisial nama.
class DashboardGreeting extends StatelessWidget {
  const DashboardGreeting({super.key, this.userName});

  final String? userName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = context.accent;
    final now = DateTime.now();
    final greeting = switch (now.hour) {
      < 11 => 'Selamat pagi',
      < 15 => 'Selamat siang',
      < 18 => 'Selamat sore',
      _ => 'Selamat malam',
    };
    final name = userName?.trim() ?? '';
    final title = name.isEmpty ? greeting : '$greeting, $name';
    final initial = name.isEmpty
        ? 'M'
        : String.fromCharCode(name.runes.first).toUpperCase();

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  maxLines: 1,
                  style: theme.textTheme.displayMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                ReportDateFormatter.dayMonthLong(now),
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Container(
          width: AppSpacing.iconTile,
          height: AppSpacing.iconTile,
          decoration: BoxDecoration(
            color: accent.gradientStart,
            shape: BoxShape.circle,
            boxShadow: AppShadows.hero(
              theme.colorScheme.brightness,
              tint: accent.gradientStart,
            ),
          ),
          child: Center(
            child: Text(
              initial,
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.onDark,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Kartu hijau berisi total saldo, jumlah dompet, dan uang masuk, keluar,
/// serta selisihnya pada bulan ini.
class DashboardBalanceCard extends StatelessWidget {
  const DashboardBalanceCard({
    super.key,
    required this.totalBalance,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.netCashflow,
    required this.walletCount,
    required this.hideBalance,
    required this.onToggleVisibility,
    this.onOpenWallets,
  });

  static const Color _inflowColor = Color(0xFF86EFAC);
  static const Color _outflowColor = Color(0xFFFCA5A5);

  final int totalBalance;
  final int monthlyIncome;
  final int monthlyExpense;
  final int netCashflow;
  final int walletCount;
  final bool hideBalance;
  final VoidCallback onToggleVisibility;
  final VoidCallback? onOpenWallets;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = context.accent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.gradientStart, accent.gradientMid],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: AppShadows.hero(
          theme.colorScheme.brightness,
          tint: accent.gradientStart,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'TOTAL SALDO',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.onDarkMuted,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              PressableSurface(
                onTap: onOpenWallets,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$walletCount dompet',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppColors.onDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.onDark,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: hideBalance ? 'Tampilkan saldo' : 'Sembunyikan saldo',
                child: GestureDetector(
                  onTap: onToggleVisibility,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Icon(
                      hideBalance
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: AppColors.onDarkMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormatter.rupiah(totalBalance, hidden: hideBalance),
              maxLines: 1,
              style: theme.textTheme.displayMedium?.copyWith(
                color: AppColors.onDark,
                fontWeight: FontWeight.w900,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: _FlowTile(
                  label: 'Uang masuk',
                  value: CurrencyFormatter.rupiah(
                    monthlyIncome,
                    hidden: hideBalance,
                  ),
                  color: _inflowColor,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _FlowTile(
                  label: 'Uang keluar',
                  value: CurrencyFormatter.rupiah(
                    monthlyExpense,
                    hidden: hideBalance,
                  ),
                  color: _outflowColor,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _FlowTile(
                  label: 'Selisih',
                  value: CurrencyFormatter.rupiah(
                    netCashflow,
                    hidden: hideBalance,
                  ),
                  color: netCashflow < 0 ? _outflowColor : _inflowColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FlowTile extends StatelessWidget {
  const _FlowTile({
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

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.onDarkMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: theme.textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu putih berisi pemakaian anggaran bulan ini dan batas belanja harian.
class DashboardMonthCard extends StatelessWidget {
  const DashboardMonthCard({
    super.key,
    required this.summary,
    required this.hideBalance,
    required this.onSetBudget,
  });

  final DashboardSummary summary;
  final bool hideBalance;
  final VoidCallback onSetBudget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.colorScheme.brightness;
    final isDark = brightness == Brightness.dark;
    final accent = context.accent;
    final now = DateTime.now();

    String money(int value) =>
        CurrencyFormatter.rupiah(value, hidden: hideBalance);

    final limit = summary.budgetLimit;
    final hasBudget = limit > 0;
    final spent = hasBudget ? summary.budgetSpent : summary.monthlyExpense;
    final left = limit - summary.budgetSpent;
    final ratio = summary.budgetRatio.clamp(0.0, 1.0);

    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysLeft = daysInMonth - now.day + 1;
    final safeToday = left > 0 ? left ~/ daysLeft : 0;

    final barColor = ratio >= 1
        ? AppColors.expenseRed
        : (ratio >= 0.8 ? AppColors.warningOrange : accent.color);
    final leftColor = left < 0 ? AppColors.expenseRed : accent.color;
    final border = isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: border),
        boxShadow: AppShadows.soft(brightness),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Bulan ini',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                DateFormatter.monthLabel(now),
                style: theme.textTheme.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    money(spent),
                    maxLines: 1,
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
              if (hasBudget) ...[
                const SizedBox(width: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Text(
                    'dari ${money(limit)}',
                    style: theme.textTheme.labelLarge,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (hasBudget) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 10,
                color: barColor,
                backgroundColor: isDark
                    ? AppColors.darkSurfaceSoft
                    : AppColors.surfaceSoft,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _MonthStat(
                    label: 'Terpakai',
                    value: money(spent),
                    alignEnd: false,
                  ),
                ),
                Expanded(
                  child: _MonthStat(
                    label: 'Sisa',
                    value: money(left),
                    valueColor: leftColor,
                    alignEnd: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Divider(height: 1, color: border),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: accent.color, size: 20),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Aman dibelanjakan hari ini',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Text(
                  money(safeToday),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: accent.color,
                    fontWeight: FontWeight.w900,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ] else
            PressableSurface(
              onTap: onSetBudget,
              child: Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: accent.color, size: 20),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Atur anggaran di Analitik untuk melihat batas belanja harian.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MonthStat extends StatelessWidget {
  const _MonthStat({
    required this.label,
    required this.value,
    required this.alignEnd,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool alignEnd;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelMedium),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w800,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
