import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/enums/transaction_type.dart';
import '../../../core/formatters/currency_formatter.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../../data/repositories/app_models.dart';
import '../../../shared/components/add_transaction_sheet.dart';
import '../../../shared/widgets/app_confirm_dialog.dart';
import '../../../shared/widgets/app_form_actions.dart';
import '../../../shared/widgets/top_toast.dart';

void showEditTransactionSheet(BuildContext context, TransactionDetail detail) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.scrim,
    builder: (context) => AddTransactionSheet(transaction: detail),
  );
}

Future<void> confirmDeleteTransaction(
  BuildContext context,
  WidgetRef ref,
  TransactionDetail detail,
) async {
  final confirmed = await showAppConfirmDialog(
    context: context,
    title: 'Hapus transaksi?',
    message: 'Transaksi yang dihapus tidak bisa dikembalikan.',
    confirmLabel: 'Hapus',
    danger: true,
  );

  if (!confirmed) return;

  await ref.read(transactionRepositoryProvider).delete(detail.transaction.id);
  if (!context.mounted) return;
  TopToast.show(
    context,
    'Transaksi berhasil dihapus.',
    type: TopToastType.success,
  );
}

void showTransactionDetailSheet(
  BuildContext context,
  WidgetRef ref,
  TransactionDetail detail,
  bool hideBalance,
) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      final title = detail.type == TransactionType.transfer
          ? '${detail.wallet.name} ke ${detail.transferWallet?.name ?? 'Dompet'}'
          : detail.category?.name ?? 'Transaksi';
      final walletLabel = detail.type == TransactionType.transfer
          ? 'Dari ${detail.wallet.name} ke ${detail.transferWallet?.name ?? 'Dompet'}'
          : detail.wallet.name;
      final typeLabel = switch (detail.type) {
        TransactionType.income => 'Pemasukan',
        TransactionType.expense => 'Pengeluaran',
        TransactionType.transfer => 'Transfer',
      };
      final note = detail.transaction.note?.trim();

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.sm,
            AppSpacing.screen,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              Text(typeLabel, style: theme.textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                CurrencyFormatter.rupiah(
                  detail.transaction.amount,
                  hidden: hideBalance,
                ),
                style: theme.textTheme.displayMedium?.copyWith(
                  color: _amountColor(detail.type),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              _DetailRow(
                label: 'Tanggal',
                value: DateFormatter.dateTimeLabel(detail.transaction.date),
              ),
              _DetailRow(label: 'Dompet', value: walletLabel),
              if (detail.category != null)
                _DetailRow(label: 'Kategori', value: detail.category!.name),
              _DetailRow(
                label: 'Catatan',
                value: note == null || note.isEmpty
                    ? 'Tidak ada catatan'
                    : note,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppFormActions(
                secondaryLabel: 'Edit',
                primaryLabel: 'Hapus',
                danger: true,
                onSecondaryPressed: () {
                  Navigator.pop(sheetContext);
                  showEditTransactionSheet(context, detail);
                },
                onPrimaryPressed: () {
                  Navigator.pop(sheetContext);
                  confirmDeleteTransaction(context, ref, detail);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: Text(label, style: theme.textTheme.labelLarge),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }
}

Color _amountColor(TransactionType type) {
  switch (type) {
    case TransactionType.income:
      return AppColors.incomeGreen;
    case TransactionType.expense:
      return AppColors.expenseRed;
    case TransactionType.transfer:
      return AppColors.infoBlue;
  }
}
