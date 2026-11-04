import 'package:flutter/material.dart';

import 'app_accent.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_typography.dart';
import 'system_palette.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    final textTheme = AppTypography.textTheme(Brightness.light);
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.primary,
          onPrimary: AppColors.onDark,
          secondary: AppColors.infoBlue,
          surface: AppColors.surface,
          surfaceContainerHighest: AppColors.surfaceSoft,
          onSurface: AppColors.textPrimary,
          onSurfaceVariant: AppColors.textSecondary,
          outline: AppColors.borderSubtle,
          error: AppColors.expenseRed,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: colorScheme,
      extensions: const [AppAccent.light],
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      dividerColor: AppColors.borderSubtle,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
      ),
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxl),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        elevation: 0,
        modalElevation: 0,
        backgroundColor: AppColors.surface,
        modalBackgroundColor: AppColors.surface,
        showDragHandle: true,
        dragHandleColor: AppColors.textTertiary.withValues(alpha: 0.34),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onDark,
          disabledBackgroundColor: AppColors.surfaceSoft,
          disabledForegroundColor: AppColors.textTertiary,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.textTertiary,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          side: const BorderSide(color: AppColors.borderSubtle),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.textTertiary,
          minimumSize: const Size(AppSpacing.iconTile, AppSpacing.iconTile),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          disabledForegroundColor: AppColors.textTertiary,
          minimumSize: const Size.square(AppSpacing.iconTile),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceSoft,
        selectedColor: AppColors.surfaceMint,
        disabledColor: AppColors.surfaceSoft.withValues(alpha: 0.56),
        checkmarkColor: AppColors.primary,
        labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        side: const BorderSide(color: AppColors.borderSubtle),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        labelStyle: textTheme.labelLarge?.copyWith(
          color: AppColors.textPrimary,
        ),
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(
          color: AppColors.primaryDark,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceSoft,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        labelStyle: textTheme.labelLarge?.copyWith(
          color: AppColors.textSecondary,
        ),
        floatingLabelStyle: textTheme.labelLarge?.copyWith(
          color: AppColors.primary,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
        ),
        helperStyle: textTheme.labelSmall?.copyWith(
          color: AppColors.textSecondary,
        ),
        errorStyle: textTheme.labelSmall?.copyWith(color: AppColors.expenseRed),
        border: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: const BorderSide(color: AppColors.expenseRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: const BorderSide(color: AppColors.expenseRed, width: 1.2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(
            color: AppColors.borderSubtle.withValues(alpha: 0.7),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.textSecondary,
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodyMedium,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.sm,
        ),
      ),
    );
  }

  static ThemeData get dark {
    final textTheme = AppTypography.textTheme(Brightness.dark);
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ).copyWith(
          primary: AppColors.softMint,
          onPrimary: AppColors.darkBackground,
          secondary: AppColors.infoBlue,
          surface: AppColors.darkSurface,
          surfaceContainerHighest: AppColors.darkSurfaceSoft,
          onSurface: AppColors.darkTextPrimary,
          onSurfaceVariant: AppColors.darkTextSecondary,
          outline: AppColors.darkBorderSubtle,
          error: AppColors.expenseRed,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: colorScheme,
      extensions: [AppAccent.dark],
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      dividerColor: AppColors.darkBorderSubtle,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
      ),
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxl),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        elevation: 0,
        modalElevation: 0,
        backgroundColor: AppColors.darkSurface,
        modalBackgroundColor: AppColors.darkSurface,
        showDragHandle: true,
        dragHandleColor: AppColors.darkTextTertiary.withValues(alpha: 0.48),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.softMint,
          foregroundColor: AppColors.darkBackground,
          disabledBackgroundColor: AppColors.darkSurfaceSoft,
          disabledForegroundColor: AppColors.darkTextTertiary,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.softMint,
          disabledForegroundColor: AppColors.darkTextTertiary,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          side: const BorderSide(color: AppColors.darkBorderSubtle),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.softMint,
          disabledForegroundColor: AppColors.darkTextTertiary,
          minimumSize: const Size(AppSpacing.iconTile, AppSpacing.iconTile),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.darkTextPrimary,
          disabledForegroundColor: AppColors.darkTextTertiary,
          minimumSize: const Size.square(AppSpacing.iconTile),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurfaceSoft,
        selectedColor: AppColors.softMint.withValues(alpha: 0.16),
        disabledColor: AppColors.darkSurfaceSoft.withValues(alpha: 0.52),
        checkmarkColor: AppColors.softMint,
        labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        side: const BorderSide(color: AppColors.darkBorderSubtle),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        labelStyle: textTheme.labelLarge?.copyWith(
          color: AppColors.darkTextPrimary,
        ),
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(
          color: AppColors.softMint,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceSoft,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        labelStyle: textTheme.labelLarge?.copyWith(
          color: AppColors.darkTextSecondary,
        ),
        floatingLabelStyle: textTheme.labelLarge?.copyWith(
          color: AppColors.softMint,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.darkTextSecondary,
        ),
        helperStyle: textTheme.labelSmall?.copyWith(
          color: AppColors.darkTextSecondary,
        ),
        errorStyle: textTheme.labelSmall?.copyWith(color: AppColors.expenseRed),
        border: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: const BorderSide(color: AppColors.darkBorderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: const BorderSide(color: AppColors.darkBorderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: const BorderSide(color: AppColors.softMint, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: const BorderSide(color: AppColors.expenseRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: const BorderSide(color: AppColors.expenseRed, width: 1.2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(
            color: AppColors.darkBorderSubtle.withValues(alpha: 0.7),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.darkTextSecondary,
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodyMedium,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.sm,
        ),
      ),
    );
  }

  /// Tema terang dengan aksen dari palet sistem Android (Material You).
  static ThemeData dynamicLight(SystemPalette palette) {
    return _withPalette(light, palette, Brightness.light);
  }

  /// Tema gelap dengan aksen dari palet sistem Android (Material You).
  static ThemeData dynamicDark(SystemPalette palette) {
    return _withPalette(dark, palette, Brightness.dark);
  }

  /// Mengganti warna aksen tema dasar dengan palet sistem. Warna permukaan,
  /// teks, dan warna semantik (pemasukan, pengeluaran) tetap dari tema dasar.
  static ThemeData _withPalette(
    ThemeData base,
    SystemPalette palette,
    Brightness brightness,
  ) {
    final isDark = brightness == Brightness.dark;
    Color tone(String set, int step) => palette.tone(set, step);

    final primary = isDark ? tone('accent1', 200) : tone('accent1', 600);
    final onPrimary = isDark ? tone('accent1', 800) : tone('accent1', 0);
    final primaryContainer = isDark
        ? tone('accent1', 700)
        : tone('accent1', 100);
    final onPrimaryContainer = isDark
        ? tone('accent1', 100)
        : tone('accent1', 900);

    final accent = AppAccent(
      color: primary,
      container: isDark ? primary.withValues(alpha: 0.14) : tone('accent1', 100),
      onColor: onPrimary,
      gradientStart: tone('accent1', 600),
      gradientMid: tone('accent1', 800),
      gradientEnd: tone('accent1', 900),
    );

    final colorScheme = base.colorScheme.copyWith(
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      tertiary: isDark ? tone('accent3', 200) : tone('accent3', 600),
    );

    final disabledBackground = isDark
        ? AppColors.darkSurfaceSoft
        : AppColors.surfaceSoft;
    final disabledForeground = isDark
        ? AppColors.darkTextTertiary
        : AppColors.textTertiary;

    return base.copyWith(
      colorScheme: colorScheme,
      extensions: [accent],
      filledButtonTheme: FilledButtonThemeData(
        style: base.filledButtonTheme.style?.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.disabled)
                ? disabledBackground
                : primary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.disabled)
                ? disabledForeground
                : onPrimary;
          }),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: base.outlinedButtonTheme.style?.copyWith(
          foregroundColor: WidgetStatePropertyAll<Color>(primary),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: base.textButtonTheme.style?.copyWith(
          foregroundColor: WidgetStatePropertyAll<Color>(primary),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        selectedColor: accent.container,
        checkmarkColor: primary,
        secondaryLabelStyle: base.chipTheme.secondaryLabelStyle?.copyWith(
          color: primary,
        ),
      ),
    );
  }
}
