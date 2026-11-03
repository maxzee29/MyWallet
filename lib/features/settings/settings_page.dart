import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers/app_providers.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/enums/category_type.dart';
import '../../data/local/database/app_database.dart';
import '../../shared/helpers/category_icon_mapper.dart';
import '../../shared/widgets/app_brand_mark.dart';
import '../../shared/widgets/app_confirm_dialog.dart';
import '../../shared/widgets/app_form_actions.dart';
import '../../shared/widgets/app_icon_action_button.dart';
import '../../shared/widgets/pressable_surface.dart';
import '../../shared/widgets/top_toast.dart';
import '../analytics/analytics_page.dart';
import '../monthly/monthly_report_page.dart';
import 'widgets/app_update_sheet.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref
        .watch(appSettingsProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    final security = ref
        .watch(securitySettingsProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    final packageInfo = ref.watch(packageInfoProvider);
    final versionLabel = packageInfo.when(
      data: (info) => 'Versi ${info.version}',
      loading: () => 'Memuat versi...',
      error: (_, _) => 'Versi aplikasi belum bisa dimuat',
    );
    final aboutSubtitle = packageInfo.when(
      data: (info) => 'Versi ${info.version}, offline tanpa akun',
      loading: () => 'Memuat versi...',
      error: (_, _) => 'Versi aplikasi belum bisa dimuat',
    );
    final theme = Theme.of(context);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.xl,
          AppSpacing.screen,
          AppSpacing.contentBottomInset,
        ),
        children: [
          Text('Pengaturan', style: theme.textTheme.displayMedium),
          const SizedBox(height: AppSpacing.xxl),
          _SettingsTile(
            icon: Icons.dark_mode_rounded,
            title: 'Tampilan',
            subtitle: _themeLabel(settings?.themeMode ?? 'system'),
            onTap: () =>
                _showThemeSheet(context, ref, settings?.themeMode ?? 'system'),
          ),
          _SettingsTile(
            icon: Icons.visibility_off_rounded,
            title: 'Sembunyikan saldo',
            subtitle: settings?.hideBalance ?? false
                ? 'Nominal disamarkan'
                : 'Nominal terlihat',
            trailing: Switch(
              value: settings?.hideBalance ?? false,
              onChanged: (value) =>
                  ref.read(settingsRepositoryProvider).setHideBalance(value),
            ),
          ),
          _SettingsTile(
            icon: Icons.calendar_month_rounded,
            title: 'Laporan Bulanan',
            subtitle: 'Insight dan catatan keuangan per bulan',
            onTap: () => MonthlyReportPage.open(context),
          ),
          _SettingsTile(
            icon: Icons.insights_rounded,
            title: 'Analitik & Budget',
            subtitle: 'Lihat grafik dan atur budget bulanan',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const Scaffold(body: AnalyticsPage()),
              ),
            ),
          ),
          _SettingsTile(
            icon: Icons.lock_rounded,
            title: 'Keamanan',
            subtitle: kIsWeb
                ? 'Kunci aplikasi tersedia di Android'
                : security?.pinEnabled ?? false
                ? 'PIN aktif, ${_autoLockLabel(security!.autoLockMinutes)}'
                : 'Buat PIN untuk mengunci aplikasi',
            onTap: kIsWeb
                ? () => TopToast.show(
                    context,
                    'Kunci aplikasi tersedia di Android.',
                    type: TopToastType.warning,
                  )
                : () => _showSecuritySheet(context),
          ),
          _SettingsTile(
            icon: Icons.backup_rounded,
            title: 'Data & Cadangan',
            subtitle: 'Pindahkan data ke HP baru atau simpan laporan',
            onTap: () => _showBackupSheet(context, ref),
          ),
          _SettingsTile(
            icon: Icons.category_rounded,
            title: 'Kategori',
            subtitle: 'Tambah, edit, atau nonaktifkan kategori',
            onTap: () => _showCategoriesSheet(context),
          ),
          const _SettingsTile(
            icon: Icons.payments_rounded,
            title: 'Mata uang',
            subtitle:
                'IDR - Rupiah. Pilihan mata uang lain akan tersedia nanti.',
          ),
          _SettingsTile(
            icon: Icons.warning_rounded,
            title: 'Zona Bahaya',
            subtitle: 'Reset semua data dengan konfirmasi',
            danger: true,
            onTap: () => _confirmReset(context, ref),
          ),
          _SettingsTile(
            icon: Icons.volunteer_activism_rounded,
            title: 'Dukung Pengembangan',
            subtitle: 'Dukungan opsional untuk pengembangan FadDompet.',
            onTap: () => _confirmExternalLink(
              context,
              url: 'https://tako.id/fadhol_pemula',
              actionLabel: 'Lanjutkan',
              note: 'Dukungan bersifat opsional.',
            ),
          ),
          _SettingsTile(
            icon: Icons.integration_instructions_rounded,
            title: 'Repositori GitHub',
            subtitle: 'Lihat kode sumber dan perkembangan proyek.',
            onTap: () => _confirmExternalLink(
              context,
              url: 'https://github.com/fadd3079-prog/faddompet',
              actionLabel: 'Buka GitHub',
            ),
          ),
          _SettingsTile(
            icon: Icons.system_update_alt_rounded,
            title: 'Pembaruan Aplikasi',
            subtitle: 'Periksa dan unduh versi terbaru FadDompet.',
            onTap: () => _showUpdateSheet(context),
          ),
          _SettingsTile(
            icon: Icons.info_rounded,
            title: 'Tentang FadDompet',
            subtitle: aboutSubtitle,
            onTap: () => _showAboutSheet(context, versionLabel),
          ),
        ],
      ),
    );
  }

  void _showThemeSheet(BuildContext context, WidgetRef ref, String selected) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SheetOption(
                title: 'Ikuti perangkat',
                selected: selected == 'system',
                onTap: () => _setTheme(context, ref, 'system'),
              ),
              _SheetOption(
                title: 'Terang',
                selected: selected == 'light',
                onTap: () => _setTheme(context, ref, 'light'),
              ),
              _SheetOption(
                title: 'Gelap',
                selected: selected == 'dark',
                onTap: () => _setTheme(context, ref, 'dark'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _setTheme(
    BuildContext context,
    WidgetRef ref,
    String value,
  ) async {
    await ref.read(settingsRepositoryProvider).setThemeMode(value);
    if (context.mounted) Navigator.pop(context);
  }

  void _showSecuritySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final security = ref.watch(securitySettingsProvider);
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.screen),
              child: security.when(
                data: (settings) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _SheetHeader(
                      title: 'Keamanan',
                      subtitle:
                          'Kunci FadDompet dengan PIN. Biometrik tetap punya PIN cadangan.',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (settings.pinEnabled) ...[
                      _SheetOption(
                        title: 'Ubah PIN',
                        onTap: () => _createOrChangePin(
                          context,
                          ref,
                          requireCurrent: true,
                        ),
                      ),
                      _SheetOption(
                        title: 'Nonaktifkan PIN',
                        destructive: true,
                        onTap: () => _disablePin(context, ref),
                      ),
                    ] else
                      _SheetOption(
                        title: 'Buat PIN',
                        onTap: () => _createOrChangePin(context, ref),
                      ),
                    SwitchListTile.adaptive(
                      value: settings.biometricEnabled,
                      onChanged: settings.pinEnabled
                          ? (value) => _toggleBiometric(context, ref, value)
                          : null,
                      title: const Text('Buka dengan biometrik'),
                      subtitle: const Text('Opsional, PIN tetap bisa dipakai.'),
                    ),
                    ListTile(
                      onTap: settings.pinEnabled
                          ? () => _showAutoLockSheet(context, ref, settings)
                          : null,
                      title: const Text('Kunci otomatis'),
                      subtitle: Text(_autoLockLabel(settings.autoLockMinutes)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
                loading: () => const Center(child: Text('Memuat keamanan')),
                error: (_, _) =>
                    const Center(child: Text('Keamanan belum bisa dimuat')),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _createOrChangePin(
    BuildContext context,
    WidgetRef ref, {
    bool requireCurrent = false,
  }) async {
    final result = await showDialog<_PinSetupResult>(
      context: context,
      builder: (context) => _PinSetupDialog(requireCurrent: requireCurrent),
    );
    if (result == null) return;

    final repository = ref.read(securityRepositoryProvider);
    if (requireCurrent) {
      final ok = await repository.verifyPin(result.currentPin ?? '');
      if (!context.mounted) return;
      if (!ok) {
        TopToast.show(context, 'PIN tidak sesuai.', type: TopToastType.warning);
        return;
      }
    }

    try {
      await repository.savePin(result.newPin);
      if (!context.mounted) return;
      ref.invalidate(securitySettingsProvider);
      Navigator.pop(context);
      TopToast.show(
        context,
        requireCurrent ? 'PIN berhasil diperbarui.' : 'PIN berhasil dibuat.',
        type: TopToastType.success,
      );
    } on ArgumentError catch (error) {
      if (!context.mounted) return;
      TopToast.show(
        context,
        error.message.toString(),
        type: TopToastType.warning,
      );
    }
  }

  Future<void> _disablePin(BuildContext context, WidgetRef ref) async {
    final pin = await showDialog<String>(
      context: context,
      builder: (context) => const _PinVerifyDialog(),
    );
    if (pin == null) return;
    final repository = ref.read(securityRepositoryProvider);
    final ok = await repository.verifyPin(pin);
    if (!context.mounted) return;
    if (!ok) {
      TopToast.show(context, 'PIN tidak sesuai.', type: TopToastType.warning);
      return;
    }
    await repository.disablePin();
    if (!context.mounted) return;
    ref.invalidate(securitySettingsProvider);
    Navigator.pop(context);
    TopToast.show(context, 'PIN dinonaktifkan.', type: TopToastType.success);
  }

  Future<void> _toggleBiometric(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    final repository = ref.read(securityRepositoryProvider);
    try {
      await repository.setBiometricEnabled(value);
      if (!context.mounted) return;
      ref.invalidate(securitySettingsProvider);
      TopToast.show(
        context,
        value ? 'Biometrik diaktifkan.' : 'Biometrik dinonaktifkan.',
        type: TopToastType.success,
      );
    } on ArgumentError catch (error) {
      if (!context.mounted) return;
      TopToast.show(
        context,
        error.message.toString(),
        type: TopToastType.warning,
      );
    }
  }

  void _showAutoLockSheet(BuildContext context, WidgetRef ref, settings) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final value in const [0, 1, 5, 15])
                _SheetOption(
                  title: _autoLockLabel(value),
                  selected: settings.autoLockMinutes == value,
                  onTap: () async {
                    final repository = ref.read(securityRepositoryProvider);
                    await repository.setAutoLockMinutes(value);
                    if (!context.mounted) return;
                    ref.invalidate(securitySettingsProvider);
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBackupSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _SheetHeader(
                title: 'Data & Cadangan',
                subtitle:
                    'Simpan salinan data agar mudah dipulihkan saat ganti HP.',
              ),
              const SizedBox(height: AppSpacing.lg),
              const _BackupSecurityNotice(),
              const SizedBox(height: AppSpacing.lg),
              _SheetOption(
                icon: Icons.ios_share_rounded,
                title: 'Cadangkan Data',
                subtitle:
                    'Simpan salinan data agar bisa dipulihkan saat ganti HP.',
                onTap: () => _runBackupAction(
                  context,
                  () => ref.read(backupRepositoryProvider).exportJson(),
                  'Data berhasil dicadangkan.',
                ),
              ),
              _SheetOption(
                icon: Icons.restore_rounded,
                title: 'Pulihkan dari Cadangan',
                subtitle: 'Impor file cadangan FadDompet dari perangkat lama.',
                onTap: () => _startImport(context, ref),
              ),
              _SheetOption(
                icon: Icons.table_chart_rounded,
                title: 'Ekspor Laporan CSV',
                subtitle:
                    'Simpan daftar transaksi untuk dibuka di spreadsheet.',
                onTap: () => _runBackupAction(
                  context,
                  () => ref.read(backupRepositoryProvider).exportCsv(),
                  'Laporan berhasil diekspor.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _runBackupAction(
    BuildContext context,
    Future<void> Function() action,
    String successMessage,
  ) async {
    try {
      await action();
      if (!context.mounted) return;
      Navigator.pop(context);
      TopToast.show(context, successMessage, type: TopToastType.success);
    } catch (_) {
      if (!context.mounted) return;
      TopToast.show(
        context,
        'File cadangan tidak valid.',
        type: TopToastType.warning,
      );
    }
  }

  Future<void> _startImport(BuildContext context, WidgetRef ref) async {
    try {
      final repository = ref.read(backupRepositoryProvider);
      final preview = await repository.pickImportPreview();
      if (preview == null) return;
      if (!context.mounted) return;
      final confirmed = await showAppConfirmDialog(
        context: context,
        title: 'Pulihkan cadangan?',
        message:
            'Memulihkan cadangan akan mengganti data yang ada di perangkat ini. Pastikan kamu sudah mencadangkan data terbaru.\n\nIsi cadangan: ${preview.transactions} transaksi, ${preview.wallets} dompet, ${preview.categories} kategori, dan ${preview.budgets} budget.',
        confirmLabel: 'Pulihkan',
        danger: true,
      );
      if (!confirmed) return;
      await repository.restoreImport(preview);
      if (!context.mounted) return;
      Navigator.pop(context);
      TopToast.show(
        context,
        'Data berhasil dipulihkan.',
        type: TopToastType.success,
      );
    } catch (_) {
      if (!context.mounted) return;
      TopToast.show(
        context,
        'File cadangan tidak valid.',
        type: TopToastType.warning,
      );
    }
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const _ResetDialog(),
    );
    if (confirmed != true) return;
    final backupRepository = ref.read(backupRepositoryProvider);
    final securityRepository = ref.read(securityRepositoryProvider);
    await backupRepository.resetData();
    await securityRepository.disablePin();
    if (!context.mounted) return;
    ref.invalidate(securitySettingsProvider);
    TopToast.show(
      context,
      'Data berhasil direset.',
      type: TopToastType.success,
    );
  }

  void _showCategoriesSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _CategoryManagerSheet(),
    );
  }

  void _showUpdateSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => const AppUpdateSheet(),
    );
  }

  void _confirmExternalLink(
    BuildContext context, {
    required String url,
    required String actionLabel,
    String? note,
  }) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SheetHeader(
                title: 'Lanjutkan ke browser?',
                subtitle: 'Tautan ini akan dibuka di browser.',
              ),
              if (note != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(note, style: Theme.of(context).textTheme.bodyMedium),
              ],
              const SizedBox(height: AppSpacing.xl),
              AppFormActions(
                secondaryLabel: 'Batal',
                primaryLabel: actionLabel,
                onSecondaryPressed: () => Navigator.pop(sheetContext),
                onPrim
