# Changelog

All notable changes to FadDompet are documented in this file.

## [1.4.5]

- Fixed restoring a backup: backups made after changing Material You, language or menu label options were rejected as invalid. The theme setting is now accepted, and unknown values fall back to the default theme.
- The restore file picker now accepts any file type, ignores a leading byte order mark, and reports a restore failure separately from an invalid file.
- Added Adjust Balance to a wallet. Enter the actual balance and the difference is recorded as an income or expense in the Balance Adjustment category.
- The dashboard balance card now shows Inflow, Outflow and Net for the month instead of the spent-this-month line.
- Redesigned Settings: an app banner at the top, grouped cards (Preferences, Data Management, Additional Features, About) with icon tiles and dividers, and accent section labels.
- Bumped the app version to 1.4.5.

## [1.4.4]

- Redesigned the dashboard: greeting with date and initial avatar, a green total balance card with the month's spending and a wallet shortcut, and a month card with budget progress, spent and left amounts, and a safe-to-spend-today amount.
- Added English as an app language. Choose it in Pengaturan -> Tampilan & Bahasa. Static texts, dates and generated sentences are translated; notes and names you typed stay as written.
- Bumped the app version to 1.4.4.

## [1.4.3]

- Added a Material You option in Tampilan: accent colors follow the Android 12+ wallpaper palette. Surfaces and income/expense colors keep the app palette.
- Added an option to hide the labels under the bottom menu icons.
- Renamed the remaining FadDompet texts in the update check to MyWallet.
- Bumped the app version to 1.4.3.

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
