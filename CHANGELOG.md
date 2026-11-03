# Changelog

All notable changes to FadDompet are documented in this file.

## [Unreleased]

- Added Monthly Report page: per-month insights, summary cards, weekly trend chart, category breakdown with details, activity calendar, wallet filter, and a month-by-month record list.
- Renamed the app to MyWallet and changed the Android application id so it installs next to the original app.
- CI now builds split and universal APKs and can sign with a fixed keystore from the MYWALLET_KEYSTORE_B64 secret.

## [1.3.0] - 2026-07-03

- Improved Analytics period filtering.
- Improved chart explanations, legends, and budget visibility.
- Improved category icons across transactions, dashboard, and settings.
- Improved budget form layout consistency.
- Fixed app version display consistency.
- Prepared release naming and documentation for v1.3.0.

## [1.2.1] - 2026-07-02

- Added in-app update checker.
- Added direct Android APK download flow.
- Added SHA256 validation when a release checksum is available.
- Improved update error handling and Android installer handoff.

## [1.2.0] - 2026-07-02

- Improved security and release hygiene.
- Hardened local app lock behavior.
- Added PIN failed-attempt cooldown.
- Improved backup validation and restore safety.
- Added release signing configuration for local keystore use.
- Updated public documentation for APK verification and offline trust model.

## [1.1.0] - 2026-07-02

- Added offline transactions, wallets, categories, budgets, analytics, backup, and settings.
- Added PIN lock, optional biometric unlock, and hide balance.
- Added MIT License.
