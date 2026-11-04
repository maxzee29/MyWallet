import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/repositories/app_models.dart';
import '../../../shared/components/add_transaction_sheet.dart';
import '../../../shared/widgets/app_confirm_dialog.dart';
import '../../../shared/widgets/top_toast.dart';
import 'transaction_detail_page.dart';

/// Membuka halaman rincian transaksi.
Future<void> openTransactionDetail(
  BuildContext context,
  TransactionDetail detail,
  bool hideBalance,
) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) =>
          TransactionDetailPage(detail: detail, hideBalance: hideBalance),
    ),
  );
}

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

/// Meminta konfirmasi lalu menghapus transaksi. Mengembalikan true jika
/// transaksi benar-benar dihapus.
Future<bool> confirmDeleteTransaction(
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

  if (!confirmed) return false;

  await ref.read(transactionRepositoryProvider).delete(detail.transaction.id);
  if (context.mounted) {
    TopToast.show(
      context,
      'Transaksi berhasil dihapus.',
      type: TopToastType.success,
    );
  }
  return true;
}
