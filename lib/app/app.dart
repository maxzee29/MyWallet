import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/onboarding/onboarding_page.dart';
import '../features/security/app_lock_gate.dart';
import '../shared/layouts/main_shell.dart';
import '../l10n/app_language.dart';
import '../l10n/language_root.dart';
import '../shared/widgets/loading_state.dart';
import 'providers/app_providers.dart';
import 'providers/theme_providers.dart';
import 'theme/app_theme.dart';

class FadDompetApp extends ConsumerWidget {
  const FadDompetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preference = ref.watch(themePreferenceProvider);
    final systemPalette = ref
        .watch(systemPaletteProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    // Warna dinamis hanya dipakai jika diaktifkan dan perangkat mendukung.
    final palette = preference.dynamicColor ? systemPalette : null;

    // Bahasa dibaca dari mana saja lewat AppLocale, jadi perbarui sebelum
    // widget di bawahnya dibangun.
    AppLocale.current = preference.language;

    return MaterialApp(
      title: 'MyWallet',
      debugShowCheckedModeBanner: false,
      theme: palette == null ? AppTheme.light : AppTheme.dynamicLight(palette),
      darkTheme: palette == null ? AppTheme.dark : AppTheme.dynamicDark(palette),
      themeMode: preference.mode,
      builder: (context, child) {
        final brightness = Theme.of(context).colorScheme.brightness;
        final isDark = brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarDividerColor: Colors.transparent,
            statusBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
            systemNavigationBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
          ),
          child: AppLanguageRoot(
            language: preference.language,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      home: const AppLockGate(child: _AppGate()),
    );
  }

}

class _AppGate extends ConsumerWidget {
  const _AppGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(appBootstrapProvider);

    return bootstrap.when(
      data: (_) {
        final settings = ref.watch(appSettingsProvider);
        return settings.when(
          data: (value) {
            if (value?.onboardingCompleted ?? false) {
              return const MainShell();
            }
            return const OnboardingPage();
          },
          loading: () => const LoadingState(message: 'Menyiapkan data lokal'),
          error: (_, _) => const OnboardingPage(),
        );
      },
      loading: () => const LoadingState(message: 'Menyiapkan MyWallet'),
      error: (_, _) => const LoadingState(message: 'Data belum bisa dimuat'),
    );
  }
}
