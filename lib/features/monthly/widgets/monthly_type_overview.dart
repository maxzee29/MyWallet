import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_shadows.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/formatters/currency_formatter.dart';
import '../../../data/repositories/monthly_report_models.dart';

/// Kartu total berwarna untuk tab Keluar atau Masuk, lengkap dengan
/// perbandingan terhadap periode sebelumnya.
class MonthlyTotalCard extends StatelessWidget {
  const MonthlyTotalCard({
    super.key,
    required this.label,
    required this.icon,
    required this.colors,
    required this.current,
    required this.previous,
    required this.inProgress,
    required this.hideBalance,
  });

  final String label;
  final IconData icon;
  final List<Color> colors;
  final int current;
  final int previous;
  final bool inProgress;
  final bool hideBalance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    var comparison = 'Belum ada pembanding dari bulan lalu';
    IconData? comparisonIcon;
    if (previous > 0) {
      final change = (current - previous) / previous * 100;
      final text = change.abs().toStringAsFixed(1).replaceAll('.', ',');
      final reference = inProgress
          ? 'periode yang sama bulan lalu'
          : 'bulan lalu';
      if (change.abs() < 0.05) {
        comparison = 'Sama dengan $reference';
      } else if (change > 0) {
        comparison = '$text% naik dari $reference';
        comparisonIcon = Icons.arrow_upward_rounded;
      } else {
        comparison = '$text% turun dari $reference';
        comparisonIcon = Icons.arrow_downward_rounded;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.onDark, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.onDarkMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormatter.rupiah(current, hidden: hideBalance),
              maxLines: 1,
              style: theme.textTheme.displayMedium?.copyWith(
                color: AppColors.onDark,
                fontWeight: FontWeight.w900,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              if (comparisonIcon != null) ...[
                Icon(comparisonIcon, color: AppColors.onDarkMuted, size: 18),
                const SizedBox(width: AppSpacing.xs),
              ],
              Expanded(
                child: Text(
                  comparison,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.onDarkMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Saklar untuk menggabungkan kategori berdasarkan grupnya.
class MonthlyGroupToggle extends StatelessWidget {
  const MonthlyGroupToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.colorScheme.brightness == Brightness.dark;

    return Container(
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
            Icons.account_tree_rounded,
            color: isDark ? AppColors.softMint : AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tampilkan per grup', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Gabungkan kategori dalam satu grup menjadi satu item laporan.',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

/// Grafik donat dengan legenda lima item teratas. Ketuk irisan atau
/// legenda untuk melihat detail.
class MonthlyDonutCard extends StatelessWidget {
  const MonthlyDonutCard({
    super.key,
    required this.items,
    required this.total,
    required this.hideBalance,
    required this.onTap,
  });

  final List<MonthlyCategoryTotal> items;
  final int total;
  final bool hideBalance;
  final ValueChanged<MonthlyCategoryTotal> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.colorScheme.brightness;
    final isDark = brightness == Brightness.dark;
    final legend = items.take(5).toList();

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 150,
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 50,
                    startDegreeOffset: -90,
                    borderData: FlBorderData(show: false),
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        if (event is! FlTapUpEvent) return;
                        final index =
                            response?.touchedSection?.touchedSectionIndex;
                        if (index == null ||
                            index < 0 ||
                            index >= items.length) {
                          return;
                        }
                        onTap(items[index]);
                      },
                    ),
                    sections: [
                      for (final item in items)
                        PieChartSectionData(
                          value: item.amount.toDouble(),
                          color: Color(item.colorValue),
                          radius: 26,
                          showTitle: false,
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Total', style: theme.textTheme.labelMedium),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          CurrencyFormatter.rupiah(total, hidden: hideBalance),
                          maxLines: 1,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              children: [
                for (var index = 0; index < legend.length; index++) ...[
                  _LegendRow(
                    item: legend[index],
                    total: total,
                    onTap: () => onTap(legend[index]),
                  ),
                  if (index != legend.length - 1)
                    const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.item,
    required this.total,
    required this.onTap,
  });

  final MonthlyCategoryTotal item;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.colorScheme.brightness == Brightness.dark;
    final color = Color(item.colorValue);
    final ratio = total <= 0 ? 0.0 : (item.amount / total).clamp(0.0, 1.0);
    final percent = ratio * 100;
    final percentText = percent >= 10
        ? '${percent.round()}%'
        : '${percent.toStringAsFixed(1).replaceAll('.', ',')}%';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                percentText,
                style: theme.textTheme.labelLarge?.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 3,
              color: color,
              backgroundColor: isDark
                  ? AppColors.darkSurfaceSoft
                  : AppColors.surfaceSoft,
            ),
          ),
        ],
      ),
    );
  }
}
