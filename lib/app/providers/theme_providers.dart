import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/system_palette.dart';
import '../theme/theme_preference.dart';
import 'app_providers.dart';

/// Palet warna sistem Android (Material You). Null jika tidak tersedia.
final systemPaletteProvider = FutureProvider<SystemPalette?>((ref) {
  return SystemPaletteLoader.load();
});

/// Preferensi tampilan yang tersimpan di pengaturan.
final themePreferenceProvider = Provider<ThemePreference>((ref) {
  final value = ref
      .watch(appSettingsProvider)
      .maybeWhen(data: (settings) => settings?.themeMode, orElse: () => null);
  return ThemePreference.parse(value);
});
