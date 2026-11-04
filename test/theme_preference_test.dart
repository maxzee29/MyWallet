import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:faddompet/app/theme/theme_preference.dart';

void main() {
  test('plain values from older versions keep working', () {
    final fallback = ThemePreference.parse(null);

    expect(fallback.mode, ThemeMode.system);
    expect(fallback.dynamicColor, isFalse);
    expect(fallback.showNavLabels, isTrue);
    expect(ThemePreference.parse('dark').mode, ThemeMode.dark);
    expect(ThemePreference.parse('light').encode(), 'light');
  });

  test('flags are encoded and parsed back', () {
    const preference = ThemePreference(
      mode: ThemeMode.dark,
      dynamicColor: true,
      showNavLabels: false,
    );

    expect(preference.encode(), 'dark+dynamic+nolabels');

    final parsed = ThemePreference.parse('dark+dynamic+nolabels');
    expect(parsed.mode, ThemeMode.dark);
    expect(parsed.dynamicColor, isTrue);
    expect(parsed.showNavLabels, isFalse);
  });

  test('unknown values fall back to safe defaults', () {
    final parsed = ThemePreference.parse('weird+other');

    expect(parsed.mode, ThemeMode.system);
    expect(parsed.dynamicColor, isFalse);
    expect(parsed.showNavLabels, isTrue);
  });

  test('copyWith changes only the given option', () {
    final updated = ThemePreference.parse(
      'light',
    ).copyWith(showNavLabels: false);

    expect(updated.encode(), 'light+nolabels');
  });

  test('summary describes the active options', () {
    expect(ThemePreference.parse('light+dynamic').summary, 'Terang • Material You');
    expect(
      ThemePreference.parse('system+nolabels').summary,
      'Ikuti perangkat • tanpa label menu',
    );
  });
}
