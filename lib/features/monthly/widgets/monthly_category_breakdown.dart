import 'package:flutter/material.dart' hide Text;

import '../../../l10n/app_text.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_shadows.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/formatters/currency_formatter.dart';
import '../../../data/repositories/monthly_report_models.dart';
import '../../../shared/helpers/category_icon_mapper.dart';
import '../../../shared/widgets/pressable_surface.dart';

/// Daftar kategori dengan bar persentase. Ketuk baris untuk melihat detail.
class MonthlyCategoryBreakdown extends StatelessWidget {
  const MonthlyCategoryBreakdown({
    super.key,
    required this.title,
    required this.icon,
    required this.accent,
    required this.items,
    required this.total,
    required this.hideBalance,
    required this.onTap,
    this.limit,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final List<MonthlyCategoryTotal> items;
  final int total;
  final bool hideBalance;
  final ValueChanged<MonthlyCategoryTotal> onTap;
  final int? limit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.colorScheme.brightness;
    final isDark = brightness == Brightness.dark;
    final visible = limit == null ? items : items.take(limit!).toList();

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
              Container(
                width: AppSpacing.iconTileSmall,
                height: AppSpacing.iconTileSmall,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.18 : 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(color: accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('Ketuk untuk melihat detail', style: theme.textTheme.labelSmall),
          const SizedBox(height: AppSpacing.xl),
          if (visible.isEmpty)
            Text('Belum ada data.', style: theme.textTheme.bodyMedium),
          for (var index = 0; index < visible.length; index++) ...[
            _CategoryRow(
              item: visible[index],
              total: total,
              hideBalance: hideBalance,
              onTap: () => onTap(visible[index]),
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
    required this.onTap,
  });

  final MonthlyCategoryTotal item;
  final int total;
  final bool hideBalance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.colorScheme.brightness == Brightness.dark;
    final color = Color(item.colorValue);
    final ratio = total <= 0 ? 0.0 : (item.amount / total).clamp(0.0, 1.0);
    final percent = (ratio * 100).toStringAsFixed(1).replaceAll('.', ',');
    final icon = item.category == null
        ? Icons.category_rounded
        : categoryIconForEntry(item.category);

    return PressableSurface(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: AppSpacing.md),
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
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              color: color,
              backgroundColor: isDark
                  ? AppColors.darkSurfaceSoft
                  : AppColors.surfaceSoft,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$percent% dari total • ${item.count} transaksi',
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
