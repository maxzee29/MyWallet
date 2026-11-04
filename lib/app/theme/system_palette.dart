import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Palet warna sistem Android 12+ (Material You), berupa tangga nada
/// untuk aksen 1-3 dan netral 1-2.
class SystemPalette {
  const SystemPalette(this._tones);

  /// Urutan nada yang dikirim oleh sisi Android.
  static const List<int> toneSteps = [
    0,
    10,
    50,
    100,
    200,
    300,
    400,
    500,
    600,
    700,
    800,
    900,
    1000,
  ];

  static const List<String> sets = [
    'accent1',
    'accent2',
    'accent3',
    'neutral1',
    'neutral2',
  ];

  final Map<String, List<int>> _tones;

  /// Warna untuk [set] pada nada [step], misalnya `tone('accent1', 600)`.
  Color tone(String set, int step) {
    final values = _tones[set]!;
    return Color(values[toneSteps.indexOf(step)]);
  }

  /// Membaca data dari platform. Mengembalikan null jika tidak lengkap.
  static SystemPalette? fromPlatform(Object? raw) {
    if (raw is! Map) return null;

    final tones = <String, List<int>>{};
    for (final set in sets) {
      final value = raw[set];
      if (value is! List || value.length != toneSteps.length) return null;

      final colors = <int>[];
      for (final item in value) {
        if (item is! int) return null;
        colors.add(item & 0xFFFFFFFF);
      }
      tones[set] = colors;
    }
    return SystemPalette(tones);
  }
}

class SystemPaletteLoader {
  const SystemPaletteLoader._();

  static const MethodChannel _channel = MethodChannel(
    'com.faddgraphics.faddompet/theme',
  );

  /// Mengambil palet sistem. Hasilnya null di web, Android di bawah 12,
  /// atau jika platform tidak mendukungnya.
  static Future<SystemPalette?> load() async {
    if (kIsWeb) return null;

    try {
      final raw = await _channel.invokeMethod<Object?>('getSystemPalette');
      return SystemPalette.fromPlatform(raw);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
