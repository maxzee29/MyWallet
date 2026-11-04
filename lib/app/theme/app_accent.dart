import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Warna aksen aplikasi. Nilai bawaan memakai palet teal MyWallet. Pada mode
/// warna dinamis (Material You) nilainya diambil dari palet sistem Android.
@immutable
class AppAccent extends ThemeExtension<AppAccent> {
  const AppAccent({
    required this.color,
    required this.container,
    required this.onColor,
    required this.gradientStart,
    required this.gradientMid,
    required this.gradientEnd,
  });

  /// Aksen untuk ikon dan teks di atas permukaan biasa.
  final Color color;

  /// Latar lembut berwarna aksen, misalnya untuk ikon bertuliskan.
  final Color container;

  /// Warna isi di atas permukaan yang diisi penuh dengan [color].
  final Color onColor;

  /// Tiga titik gradien untuk kartu berwarna, selalu cukup gelap untuk teks putih.
  final Color gradientStart;
  final Color gradientMid;
  final Color gradientEnd;

  static const AppAccent light = AppAccent(
    color: AppColors.primary,
    container: AppColors.surfaceMint,
    onColor: AppColors.onDark,
    gradientStart: AppColors.primary,
    gradientMid: AppColors.primaryDark,
    gradientEnd: AppColors.deepNavy,
  );

  static final AppAccent dark = AppAccent(
    color: AppColors.softMint,
    container: AppColors.softMint.withValues(alpha: 0.14),
    onColor: AppColors.darkBackground,
    gradientStart: AppColors.primary,
    gradientMid: AppColors.primaryDark,
    gradientEnd: AppColors.deepNavy,
  );

  @override
  AppAccent copyWith({
    Color? color,
    Color? container,
    Color? onColor,
    Color? gradientStart,
    Color? gradientMid,
    Color? gradientEnd,
  }) {
    return AppAccent(
      color: color ?? this.color,
      container: container ?? this.container,
      onColor: onColor ?? this.onColor,
      gradientStart: gradientStart ?? this.gradientStart,
      gradientMid: gradientMid ?? this.gradientMid,
      gradientEnd: gradientEnd ?? this.gradientEnd,
    );
  }

  @override
  AppAccent lerp(ThemeExtension<AppAccent>? other, double t) {
    if (other is! AppAccent) return this;
    return AppAccent(
      color: Color.lerp(color, other.color, t)!,
      container: Color.lerp(container, other.container, t)!,
      onColor: Color.lerp(onColor, other.onColor, t)!,
      gradientStart: Color.lerp(gradientStart, other.gradientStart, t)!,
      gradientMid: Color.lerp(gradientMid, other.gradientMid, t)!,
      gradientEnd: Color.lerp(gradientEnd, other.gradientEnd, t)!,
    );
  }
}

extension AppAccentContext on BuildContext {
  /// Aksen aktif. Jika tema tidak memuatnya, dipakai nilai bawaan.
  AppAccent get accent {
    final theme = Theme.of(this);
    return theme.extension<AppAccent>() ??
        (theme.brightness == Brightness.dark ? AppAccent.dark : AppAccent.light);
  }
}
