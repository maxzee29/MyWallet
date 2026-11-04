import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/providers/theme_providers.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/theme_preference.dart';

/// Pilihan tampilan: mode tema, warna dinamis (Material You), dan label menu.
class ThemeSheet extends ConsumerWidget {
  const ThemeSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final preference = ref.watch(themePreferenceProvider);
    final palette = ref.watch(systemPaletteProvider);
    final dynamicSupported = palette.maybeWhen(
      data: (value) => value != null,
      orElse: () => false,
    );
    final dynamicSubtitle = palette.when(
      data: (value) => value == null
          ? 'Tersedia di Android 12 ke atas.'
          : 'Warna aksen mengikuti wallpaper perangkat.',
      loading: () => 'Memeriksa dukungan perangkat...',
      error: (_, _) => 'Tersedia di Android 12 ke atas.',
    );

    Future<void> save(ThemePreference next) {
      return ref.read(settingsRepositoryProvider).setThemeMode(next.encode());
    }

    const modes = [
      (ThemeMode.system, 'Ikuti perangkat'),
      (ThemeMode.light, 'Terang'),
      (ThemeMode.dark, 'Gelap'),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          0,
          AppSpacing.screen,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tampilan', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            for (final (mode, label) in modes)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(label),
                trailing: preference.mode == mode
                    ? Icon(Icons.check_rounded, color: theme.colorScheme.primary)
                    : null,
                onTap: () => save(preference.copyWith(mode: mode)),
              ),
            const Divider(height: AppSpacing.xxl),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Warna dinamis (Material You)'),
              subtitle: Text(dynamicSubtitle),
              value: preference.dynamicColor && dynamicSupported,
              onChanged: dynamicSupported
                  ? (value) => save(preference.copyWith(dynamicColor: value))
                  : null,
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tampilkan label menu'),
              subtitle: const Text('Tulisan di bawah ikon menu bawah.'),
              value: preference.showNavLabels,
              onChanged: (value) =>
                  save(preference.copyWith(showNavLabels: value)),
            ),
          ],
        ),
      ),
    );
  }
}
