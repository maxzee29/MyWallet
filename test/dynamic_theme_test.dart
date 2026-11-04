import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:faddompet/app/theme/app_accent.dart';
import 'package:faddompet/app/theme/app_colors.dart';
import 'package:faddompet/app/theme/app_theme.dart';
import 'package:faddompet/app/theme/system_palette.dart';

Map<String, List<int>> _rawPalette() {
  return {
    for (var set = 0; set < SystemPalette.sets.length; set++)
      SystemPalette.sets[set]: [
        for (var step = 0; step < SystemPalette.toneSteps.length; step++)
          0xFF000000 | (set << 16) | (step << 8) | 0x7F,
      ],
  };
}

void main() {
  test('palette is read from the platform data', () {
    final palette = SystemPalette.fromPlatform(_rawPalette());

    expect(palette, isNotNull);
    expect(palette!.tone('accent1', 0), const Color(0xFF00007F));
    expect(palette.tone('accent2', 10), const Color(0xFF01017F));
  });

  test('negative platform integers are masked to ARGB colors', () {
    final raw = _rawPalette();
    raw['accent1']![0] = -1;

    final palette = SystemPalette.fromPlatform(raw);

    expect(palette!.tone('accent1', 0), const Color(0xFFFFFFFF));
  });

  test('incomplete platform data is rejected', () {
    final raw = _rawPalette();
    raw['accent3'] = [1, 2, 3];

    expect(SystemPalette.fromPlatform(raw), isNull);
    expect(SystemPalette.fromPlatform(null), isNull);
    expect(SystemPalette.fromPlatform('invalid'), isNull);
  });

  test('dynamic themes take their accent from the system palette', () {
    final palette = SystemPalette.fromPlatform(_rawPalette())!;

    final light = AppTheme.dynamicLight(palette);
    expect(light.colorScheme.primary, palette.tone('accent1', 600));
    expect(light.extension<AppAccent>()!.color, palette.tone('accent1', 600));
    expect(light.extension<AppAccent>()!.onColor, palette.tone('accent1', 0));

    final dark = AppTheme.dynamicDark(palette);
    expect(dark.colorScheme.primary, palette.tone('accent1', 200));
    expect(dark.extension<AppAccent>()!.onColor, palette.tone('accent1', 800));
  });

  test('default themes keep the brand accent', () {
    expect(AppTheme.light.extension<AppAccent>()!.color, AppColors.primary);
    expect(AppTheme.dark.extension<AppAccent>()!.color, AppColors.softMint);
  });
}
