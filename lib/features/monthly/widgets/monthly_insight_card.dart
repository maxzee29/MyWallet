import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_shadows.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../data/repositories/monthly_report_models.dart';

class MonthlyInsightCard extends StatelessWidget {
  const MonthlyInsightCard({super.key, required this.insight});

  final MonthlyInsight insight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.colorScheme.brightness;
    final isDark = brightness == Brightness.dark;
    final accent = switch (insight.tone) {
      MonthlyInsightTone.positive => AppColors.incomeGreen,
      MonthlyInsightTone.neutral => isDark
          ? AppColors.softMint
          : AppColors.primary,
      MonthlyInsightTone.warning => AppColors.warningOrange,
    };
    final icon = switch (insight.tone) {
      MonthlyInsightTone.positive => Icons.check_circle_outline_rounded,
      MonthlyInsightTone.neutral => Icons.lightbulb_outline_rounded,
      MonthlyInsightTone.warning => Icons.warning_amber_rounded,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle,
        ),
        boxShadow: AppShadows.subtle(brightness),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppSpacing.iconTileSmall,
            height: AppSpacing.iconTileSmall,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.18 : 0.10),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insight.title, style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(insight.message, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
