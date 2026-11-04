import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_accent.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_durations.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_shadows.dart';
import '../../app/theme/app_spacing.dart';
import 'pressable_surface.dart';

class PremiumBottomNavItem {
  const PremiumBottomNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class PremiumBottomNav extends StatelessWidget {
  const PremiumBottomNav({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onChanged,
    required this.onAddPressed,
    this.showLabels = true,
  });

  final int currentIndex;
  final List<PremiumBottomNavItem> items;
  final ValueChanged<int> onChanged;
  final VoidCallback onAddPressed;

  /// Tampilkan tulisan di bawah ikon. Label tetap dibacakan pembaca layar.
  final bool showLabels;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).colorScheme.brightness;
    final isDark = brightness == Brightness.dark;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: AppSpacing.navBottomInset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: kIsWeb ? AppSpacing.webMaxWidth : double.infinity,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Container(
              height: AppSpacing.navHeight,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurface.withValues(alpha: 0.96)
                    : AppColors.surface.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(AppRadius.xxl),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkBorderSubtle
                      : AppColors.borderSubtle,
                ),
                boxShadow: AppShadows.nav(brightness),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    children: [
                      _NavItem(
                        item: items[0],
                        selected: currentIndex == 0,
                        showLabel: showLabels,
                        onTap: () => onChanged(0),
                      ),
                      _NavItem(
                        item: items[1],
                        selected: currentIndex == 1,
                        showLabel: showLabels,
                        onTap: () => onChanged(1),
                      ),
                      const SizedBox(width: AppSpacing.navActionSlot),
                      _NavItem(
                        item: items[2],
                        selected: currentIndex == 2,
                        showLabel: showLabels,
                        onTap: () => onChanged(2),
                      ),
                      _NavItem(
                        item: items[3],
                        selected: currentIndex == 3,
                        showLabel: showLabels,
                        onTap: () => onChanged(3),
                      ),
                    ],
                  ),
                  _QuickAddButton(onPressed: onAddPressed),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.selected,
    required this.showLabel,
    required this.onTap,
  });

  final PremiumBottomNavItem item;
  final bool selected;
  final bool showLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.colorScheme.brightness == Brightness.dark;
    final activeColor = context.accent.color;
    final inactiveColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: item.label,
        child: PressableSurface(
          onTap: onTap,
          child: SizedBox(
            height: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: AppDurations.normal,
                  curve: AppDurations.easeOut,
                  width: AppSpacing.iconTile,
                  height: AppSpacing.iconTile,
                  decoration: BoxDecoration(
                    color: selected
                        ? activeColor.withValues(alpha: isDark ? 0.16 : 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: selected
                        ? Border.all(
                            color: activeColor.withValues(
                              alpha: isDark ? 0.18 : 0.14,
                            ),
                          )
                        : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedScale(
                        scale: selected ? 1.04 : 1,
                        duration: AppDurations.fast,
                        curve: AppDurations.easeOut,
                        child: Icon(
                          selected ? item.selectedIcon : item.icon,
                          color: selected ? activeColor : inactiveColor,
                          size: AppSpacing.navIconSize,
                        ),
                      ),
                      if (selected)
                        Positioned(
                          bottom: AppSpacing.xs,
                          child: Container(
                            width: AppSpacing.sm,
                            height: AppSpacing.xxs,
                            decoration: BoxDecoration(
                              color: activeColor,
                              borderRadius: BorderRadius.circular(
                                AppRadius.full,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (showLabel) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: selected ? activeColor : inactiveColor,
                      height: 1,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAddButton extends StatelessWidget {
  const _QuickAddButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: 'Tambah Transaksi',
      child: PressableSurface(
        onTap: onPressed,
        child: Tooltip(
          message: 'Tambah Transaksi',
          child: Container(
            width: AppSpacing.navActionSize,
            height: AppSpacing.navActionSize,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            decoration: BoxDecoration(
              color: context.accent.color,
              borderRadius: BorderRadius.circular(AppRadius.hero),
              boxShadow: [...AppShadows.nav(theme.colorScheme.brightness)],
            ),
            child: Icon(
              Icons.add_rounded,
              color: context.accent.onColor,
              size: AppSpacing.xxl,
            ),
          ),
        ),
      ),
    );
  }
}
