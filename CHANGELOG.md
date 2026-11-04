# Changelog

All notable changes to FadDompet are documented in this file.

## [1.4.2]

- Replaced the transaction detail sheet with a full detail page: colored title and amount card, a details list for category, wallet and date, and delete and edit buttons in the header.
- Redesigned the add and edit transaction form: back-arrow header, amount card with a keypad toggle, title field, and picker rows for category, wallet and date and time that open selection sheets.
- Bumped the app version to 1.4.2.

## [1.4.1]

- Added an optional admin fee when creating a transfer. The fee is deducted from the source wallet and recorded as a separate expense in the Biaya Admin category.
- Redesigned the Keluar and Masuk report tabs: colored total card with comparison to the previous period, donut chart with legend, group toggle, trend chart, and category details.
- Redesigned the dashboard transaction history: type filter chips, one card per day with a daily total, and icon rows showing note, category, wallet and time.
- Bumped the app version to 1.4.1.

## [Unreleased]

- Added Monthly Report page: per-month insights, summary cards, weekly trend chart, category breakdown with details, activity calendar, wallet filter, and a month-by-month record list.
- Replaced the Transaksi tab with the Laporan tab. Search, type filter, transaction detail, edit and delete now live in the report's Catatan tab.
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
