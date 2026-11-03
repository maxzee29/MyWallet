import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_shadows.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../data/repositories/monthly_report_models.dart';
import '../../../shared/widgets/pressable_surface.dart';

/// Kalender bulanan yang menandai hari ketika ada transaksi.
class MonthlyActivityCalendar extends StatefulWidget {
  const MonthlyActivityCalendar({
    super.key,
    required this.report,
    required this.onDayTap,
  });

  final MonthlyReport report;
  final ValueChanged<int> onDayTap;

  @override
  State<MonthlyActivityCalendar> createState() =>
      _MonthlyActivityCalendarState();
}

class _MonthlyActivityCalendarState extends State<MonthlyActivityCalendar> {
  static const _weekdays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.colorScheme.brightness;
    final isDark = brightness == Brightness.dark;
    final month = widget.report.month;

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
          PressableSurface(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                Container(
                  width: AppSpacing.iconTileSmall,
                  height: AppSpacing.iconTileSmall,
                  decoration: BoxDecoration(
                    color: AppColors.infoBlue.withValues(
                      alpha: isDark ? 0.18 : 0.10,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: const Icon(
                    Icons.event_note_rounded,
                    color: AppColors.infoBlue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kalender Aktivitas',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Hari saat kamu mencatat transaksi',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Icon(
                  _expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                for (final name in _weekdays)
                  Expanded(
                    child: Center(
                      child: Text(name, style: theme.textTheme.labelMedium),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ..._weeks(context, month),
            const SizedBox(height: AppSpacing.md),
            const Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.sm,
              children: [
                _LegendItem(color: AppColors.incomeGreen, label: 'Pemasukan'),
                _LegendItem(color: AppColors.expenseRed, label: 'Pengeluaran'),
                _LegendItem(color: AppColors.infoBlue, label: 'Transfer'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _weeks(BuildContext context, DateTime month) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final offset = DateTime(month.year, month.month, 1).weekday - 1;
    final weekCount = ((offset + daysInMonth) / 7).ceil();
    final now = DateTime.now();
    final isCurrentMonth = now.year == month.year && now.month == month.month;

    return [
      for (var week = 0; week < weekCount; week++)
        Row(
          children: [
            for (var column = 0; column < 7; column++)
              Expanded(
                child: _dayCell(
                  context,
                  day: week * 7 + column - offset + 1,
                  daysInMonth: daysInMonth,
                  today: isCurrentMonth ? now.day : -1,
                ),
              ),
          ],
        ),
    ];
  }

  Widget _dayCell(
    BuildContext context, {
    required int day,
    required int daysInMonth,
    required int today,
  }) {
    if (day < 1 || day > daysInMonth) {
      return const SizedBox(height: 48);
    }

    final theme = Theme.of(context);
    final activity = widget.report.dayActivity[day];
    final hasActivity = activity != null;

    return PressableSurface(
      enabled: hasActivity,
      onTap: () => widget.onDayTap(day),
      child: SizedBox(
        height: 48,
        child: Center(
          child: Container(
            width: 40,
            height: 44,
            decoration: day == today
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.primary,
                      width: 1.5,
                    ),
                  )
                : null,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: hasActivity
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 3),
                SizedBox(
                  height: 6,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (activity != null && activity.income > 0)
                        const _Dot(color: AppColors.incomeGreen),
                      if (activity != null && activity.expense > 0)
                        const _Dot(color: AppColors.expenseRed),
                      if (activity != null && activity.transfer > 0)
                        const _Dot(color: AppColors.infoBlue),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
