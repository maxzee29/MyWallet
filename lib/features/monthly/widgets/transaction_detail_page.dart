import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_text.dart';
import '../../../app/theme/app_accent.dart';
import '../../../app/providers/app_providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_shadows.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/enums/transaction_type.dart';
import '../../../core/formatters/currency_formatter.dart';
import '../../../core/formatters/report_date_formatter.dart';
import '../../../data/repositories/app_models.dart';
import '../../../shared/helpers/category_icon_mapper.dart';
import 'monthly_transaction_actions.dart';

/// Halaman rincian transaksi: kartu berwarna berisi judul dan nominal,
/// lalu daftar rincian kategori, dompet, dan tanggal.
class TransactionDetailPage extends ConsumerWidget {
  const TransactionDetailPage({
    super.key,
    required this.detail,
    required this.hideBalance,
  });

  final TransactionDetail detail;
  final bool hideBalance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brightness = theme.colorScheme.brightness;
    final isDark = brightness == Brightness.dark;

    // Ikuti perubahan terbaru, misalnya setelah transaksi diedit.
    final latest = ref
        .watch(transactionDetailsProvider)
        .maybeWhen<TransactionDetail?>(
          data: (items) {
            for (final item in items) {
              if (item.transaction.id == detail.transaction.id) return item;
            }
            return null;
          },
          orElse: () => null,
        );
    final current = latest ?? detail;

    final type = current.type;
    final isTransfer = type == TransactionType.transfer;
    final colors = switch (type) {
      TransactionType.income => const [
        AppColors.incomeGreen,
        Color(0xFF166534),
      ],
      TransactionType.expense => const [
        AppColors.expenseRed,
        Color(0xFF991B1B),
      ],
      TransactionType.transfer => const [
        AppColors.infoBlue,
        Color(0xFF1E3A8A),
      ],
    };
    final sign = switch (type) {
      TransactionType.income => '+',
      TransactionType.expense => '-',
      TransactionType.transfer => '',
    };

    final note = current.transaction.note?.trim();
    final label = isTransfer
        ? 'Transfer'
        : current.category?.name ?? 'Transaksi';
    final title = note == null || note.isEmpty ? label : note;
    final date = current.transaction.date;
    final dateText =
        '${ReportDateFormatter.fullDayLong(date)} • ${ReportDateFormatter.time(date)}';
    final iconColor = context.accent.color;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.lg,
            AppSpacing.screen,
            AppSpacing.xxl,
          ),
          children: [
            Row(
              children: [
                _HeaderButton(
                  icon: Icons.arrow_back_rounded,
                  label: 'Kembali',
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Text(
                    'Rincian Transaksi',
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                _HeaderButton(
                  icon: Icons.delete_outline_rounded,
                  label: 'Hapus transaksi',
                  onTap: () async {
                    final deleted = await confirmDeleteTransaction(
                      context,
                      ref,
                      current,
                    );
                    if (deleted && context.mounted) Navigator.pop(context);
                  },
                ),
                const SizedBox(width: AppSpacing.sm),
                _HeaderButton(
                  icon: Icons.edit_rounded,
                  label: 'Ubah transaksi',
                  onTap: () => showEditTransactionSheet(context, current),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
                borderRadius: BorderRadius.circular(AppRadius.xxl),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.onDark,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '$sign${CurrencyFormatter.rupiah(current.transaction.amount, hidden: hideBalance)}',
                      maxLines: 1,
                      style: theme.textTheme.displayMedium?.copyWith(
                        color: AppColors.onDark,
                        fontWeight: FontWeight.w900,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceElevated
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.xxl),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkBorderSubtle
                      : AppColors.borderSubtle,
                ),
                boxShadow: AppShadows.soft(brightness),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    child: Text('Rincian', style: theme.textTheme.titleMedium),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (isTransfer) ...[
                    _InfoRow(
                      icon: Icons.logout_rounded,
                      color: iconColor,
                      label: 'Dari dompet',
                      value: current.wallet.name,
                    ),
                    _InfoRow(
                      icon: Icons.login_rounded,
                      color: iconColor,
                      label: 'Ke dompet',
                      value: current.transferWallet?.name ?? 'Dompet',
                    ),
                  ] else ...[
                    _InfoRow(
                      icon: current.category == null
                          ? Icons.category_rounded
                          : categoryIconForEntry(current.category),
                      color: iconColor,
                      label: 'Kategori',
                      value: current.category?.name ?? 'Tanpa kategori',
                    ),
                    _InfoRow(
                      icon: Icons.account_balance_wallet_rounded,
                      color: iconColor,
                      label: 'Dompet',
                      value: current.wallet.name,
                    ),
                  ],
                  _InfoRow(
                    icon: Icons.event_rounded,
                    color: iconColor,
                    label: 'Tanggal',
                    value: dateText,
                    showDivider: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.colorScheme.brightness == Brightness.dark;

    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: AppSpacing.iconTile,
          height: AppSpacing.iconTile,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceSoft : AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Icon(icon, color: theme.colorScheme.onSurface),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.colorScheme.brightness == Brightness.dark;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: theme.textTheme.labelMedium),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      value,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle,
          ),
      ],
    );
  }
}
