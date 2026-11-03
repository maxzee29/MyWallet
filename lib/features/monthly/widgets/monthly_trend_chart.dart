import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_shadows.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/enums/transaction_type.dart';
import '../../../core/formatters/currency_formatter.dart';
import '../../../data/repositories/monthly_report_models.dart';
import '../../../shared/widgets/pressable_surface.dart';

/// Grafik tren mingguan (M1..M5) untuk pengeluaran atau pemasukan.
class MonthlyTrendChart extends StatefulWidget {
  const MonthlyTrendChart({
    super.key,
    required this.report,
    required this.hideBalance,
    this.fixedType,
  });

  final MonthlyReport report;
  final bool hideBalance;

  /// Jika diisi, tombol pilihan jenis disembunyikan.
  final TransactionType? fixedType;

  @override
  State<MonthlyTrendChart> createState() => _MonthlyTrendChartState();
}

class _MonthlyTrendChartState extends State<MonthlyTrendChart> {
  TransactionType _type = TransactionType.expense;

  TransactionType get _active => widget.fixedType ?? _type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.colorScheme.brightness;
    final isDark = brightness == Brightness.dark;
    final isIncome = _active == TransactionType.income;
    final values = isIncome
        ? widget.report.weeklyIncome
        : widget.report.weeklyExpense;
    final color = isIncome ? AppColors.incomeGreen : AppColors.expenseRed;

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
          Row(
            children: [
              Expanded(
                child: Text('Grafik Tren', style: theme.textTheme.titleLarge),
              ),
              if (widget.fixedType == null) ...[
                _TypeChip(
                  label: 'Keluar',
                  color: AppColors.expenseRed,
                  selected: _type == TransactionType.expense,
                  onTap: () => setState(() => _type = TransactionType.expense),
                ),
                const SizedBox(width: AppSpacing.sm),
                _TypeChip(
                  label: 'Masuk',
                  color: AppColors.incomeGreen,
                  selected: _type == TransactionType.income,
                  onTap: () => setState(() => _type = TransactionType.income),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isIncome ? 'Pemasukan per minggu' : 'Pengeluaran per minggu',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            height: 200,
            child: _buildChart(context, values, color, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(
    BuildContext context,
    List<int> values,
    Color color,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final maxValue = values.fold<int>(0, (top, value) {
      return value > top ? value : top;
    });

    if (maxValue == 0) {
      return Center(
        child: Text(
          'Belum ada data pada bulan ini.',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    final maxY = maxValue * 1.25;
    final interval = maxY / 3;
    final hide = widget.hideBalance;
    final spots = [
      for (var index = 0; index < values.length; index++)
        FlSpot(index.toDouble(), values[index].toDouble()),
    ];

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (_) => FlLine(
            color: theme.colorScheme.outline.withValues(alpha: 0.6),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: !hide,
              reservedSize: 48,
              interval: interval,
              getTitlesWidget: (value, meta) {
                return Text(
                  _compact(value.round()),
                  style: theme.textTheme.labelSmall,
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= values.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    'M${index + 1}',
                    style: theme.textTheme.labelSmall,
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBorderRadius: BorderRadius.circular(AppRadius.md),
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            getTooltipColor: (_) =>
                isDark ? AppColors.darkSurfaceElevated : AppColors.textPrimary,
            getTooltipItems: (touched) {
              return [
                for (final spot in touched)
                  LineTooltipItem(
                    CurrencyFormatter.rupiah(spot.y.round(), hidden: hide),
                    theme.textTheme.labelLarge!.copyWith(
                      color: AppColors.onDark,
                    ),
                  ),
              ];
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            preventCurveOverShooting: true,
            color: color,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }

  String _compact(int value) {
    if (value >= 1000000) {
      final millions = value / 1000000;
      final text = millions
          .toStringAsFixed(millions >= 10 ? 0 : 1)
          .replaceAll('.', ',');
      return '$text jt';
    }
    if (value >= 1000) {
      return '${(value / 1000).round()}K';
    }
    return '$value';
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: PressableSurface(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.14) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
              color: selected ? color : theme.colorScheme.outline,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: selected ? color : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
