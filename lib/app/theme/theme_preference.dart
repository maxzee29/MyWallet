import 'package:flutter/material.dart';

import '../../l10n/app_language.dart';

/// Preferensi tampilan yang disimpan dalam satu teks pada kolom `themeMode`.
///
/// Formatnya `<mode>` diikuti penanda opsional yang dipisah tanda `+`,
/// misalnya `dark+dynamic+nolabels`. Cara ini menjaga skema database tetap
/// sama, dan nilai lama (`system`, `light`, `dark`) tetap valid.
class ThemePreference {
  const ThemePreference({
    this.mode = ThemeMode.system,
    this.dynamicColor = false,
    this.showNavLabels = true,
    this.language = AppLanguage.indonesian,
  });

  static const String _dynamicFlag = 'dynamic';
  static const String _noLabelsFlag = 'nolabels';
  static const String _englishFlag = 'en';

  final ThemeMode mode;

  /// Gunakan warna dinamis Material You jika perangkat mendukung.
  final bool dynamicColor;

  /// Tampilkan tulisan di bawah ikon menu bawah.
  final bool showNavLabels;

  /// Bahasa tampilan aplikasi.
  final AppLanguage language;

  factory ThemePreference.parse(String? value) {
    final parts = (value ?? 'system').split('+');
    final mode = switch (parts.first) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    final flags = parts.skip(1).toSet();

    return ThemePreference(
      mode: mode,
      dynamicColor: flags.contains(_dynamicFlag),
      showNavLabels: !flags.contains(_noLabelsFlag),
      language: flags.contains(_englishFlag)
          ? AppLanguage.english
          : AppLanguage.indonesian,
    );
  }

  /// Teks yang disimpan ke database.
  String encode() {
    final base = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };

    return [
      base,
      if (dynamicColor) _dynamicFlag,
      if (!showNavLabels) _noLabelsFlag,
      if (language == AppLanguage.english) _englishFlag,
    ].join('+');
  }

  ThemePreference copyWith({
    ThemeMode? mode,
    bool? dynamicColor,
    bool? showNavLabels,
    AppLanguage? language,
  }) {
    return ThemePreference(
      mode: mode ?? this.mode,
      dynamicColor: dynamicColor ?? this.dynamicColor,
      showNavLabels: showNavLabels ?? this.showNavLabels,
      language: language ?? this.language,
    );
  }

  String get modeLabel {
    switch (mode) {
      case ThemeMode.light:
        return 'Terang';
      case ThemeMode.dark:
        return 'Gelap';
      case ThemeMode.system:
        return 'Ikuti perangkat';
    }
  }

  /// Ringkasan untuk subjudul menu Pengaturan.
  String get summary {
    final parts = [
      modeLabel,
      if (dynamicColor) 'Material You',
      if (!showNavLabels) 'tanpa label menu',
      if (language == AppLanguage.english) 'English',
    ];
    return parts.join(' • ');
  }
}
