import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../core/enums/transaction_type.dart';
import '../../../core/formatters/currency_formatter.dart';
import '../../../core/formatters/report_date_formatter.dart';
import '../../../data/repositories/app_models.dart';
import '../../../shared/helpers/category_icon_mapper.dart';
import '../../transactions/widgets/transaction_tile.dart';

class MonthlyTransactionTile extends StatelessWidget {
  const MonthlyTransactionTile({
    super.key,
    required this.detail,
    required this.hideBalance,
    this.onTap,
    this.onLongPress,
  });

  final TransactionDetail detail;
  final bool hideBalance;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final isTransfer = detail.type == TransactionType.transfer;
    final title = isTransfer
        ? '${detail.wallet.name} ke ${detail.transferWallet?.name ?? 'Dompet'}'
        : detail.category?.name ?? 'Transaksi';
    final note = detail.transaction.note?.trim();
    final walletLabel = isTransfer
        ? 'Transfer antar dompet'
        : detail.wallet.name;
    final subtitle = note == null || note.isEmpty
        ? walletLabel
        : '$walletLabel · $note';

    return TransactionTile(
      title: title,
      subtitle: subtitle,
      timeLabel: ReportDateFormatter.time(detail.transaction.date),
      amount: CurrencyFormatter.rupiah(
        detail.transaction.amount,
        hidden: hideBalance,
      ),
      type: _previewType(detail.type),
      icon: _transactionIcon(detail),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}

TransactionPreviewType _previewType(TransactionType type) {
  switch (type) {
    case TransactionType.income:
      return TransactionPreviewType.income;
    case TransactionType.expense:
      return TransactionPreviewType.expense;
    case TransactionType.transfer:
      return TransactionPreviewType.transfer;
  }
}

IconData _transactionIcon(TransactionDetail detail) {
  if (detail.type == TransactionType.transfer) {
    return Icons.swap_horiz_rounded;
  }
  if (detail.category != null) {
    return categoryIconForEntry(detail.category);
  }
  if (detail.type == TransactionType.income) {
    return Icons.work_rounded;
  }
  return Icons.category_rounded;
}

Future<void> showMonthlyTransactionsSheet(
  BuildContext context, {
  required String title,
  required String subtitle,
  required List<TransactionDetail> items,
  required bool hideBalance,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      final maxHeight = MediaQuery.of(sheetContext).size.height * 0.75;

      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              0,
              AppSpacing.screen,
              AppSpacing.xl,
            ),
            children: [
              Text(title, style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(subtitle, style: theme.textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.lg),
              if (items.isEmpty)
                Text(
                  'Tidak ada transaksi.',
                  style: theme.textTheme.bodyMedium,
                ),
              for (final item in items) ...[
                MonthlyTransactionTile(detail: item, hideBalance: hideBalance),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        ),
      );
    },
  );
}

class ReportOption<T> {
  const ReportOption({required this.label, required this.value});

  final String label;
  final T value;
}

Future<void> showReportOptionsSheet<T>({
  required BuildContext context,
  required String title,
  required List<ReportOption<T>> options,
  required T selected,
  required ValueChanged<T> onSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      final maxHeight = MediaQuery.of(sheetContext).size.height * 0.7;

      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              0,
              AppSpacing.screen,
              AppSpacing.xl,
            ),
            children: [
              Text(title, style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              for (final option in options)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(option.label),
                  trailing: option.value == selected
                      ? Icon(Icons.check_rounded, color: theme.colorScheme.primary)
                      : null,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    onSelected(option.value);
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}
