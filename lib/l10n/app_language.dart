/// Bahasa tampilan aplikasi.
enum AppLanguage { indonesian, english }

/// Menyimpan bahasa yang sedang aktif agar bisa dibaca dari mana saja,
/// termasuk di luar widget.
class AppLocale {
  const AppLocale._();

  static AppLanguage current = AppLanguage.indonesian;
}
