import 'dart:async';

import 'package:drift/drift.dart';

import '../../core/enums/transaction_type.dart';
import '../../core/helpers/calculation_helper.dart';
import '../local/database/app_database.dart';
import 'app_models.dart';

class WalletRepository {
  const WalletRepository(this._database);

  final AppDatabase _database;

  Stream<List<WalletBalance>> watchWalletBalances() {
    final controller = StreamController<List<WalletBalance>>();
    List<WalletEntry>? wallets;
    List<TransactionEntry>? transactions;

    void emit() {
      final currentWallets = wallets;
      final currentTransactions = transactions;
      if (currentWallets == null || currentTransactions == null) return;

      controller.add([
        for (final wallet in currentWallets)
          WalletBalance(
            wallet: wallet,
            balance: CalculationHelper.walletBalance(
              walletId: wallet.id,
              initialBalance: wallet.initialBalance,
              transactions: currentTransactions.map(
                (transaction) => (
                  walletId: transaction.walletId,
                  transferWalletId: transaction.transferWalletId,
                  type: transaction.type,
                  amount: transaction.amount,
                ),
              ),
            ),
          ),
      ]);
    }

    final walletSub = _database.walletsDao.watchAll().listen((value) {
      wallets = value;
      emit();
    });
    final transactionSub = _database.transactionsDao.watchAll().listen((value) {
      transactions = value;
      emit();
    });

    controller.onCancel = () async {
      await walletSub.cancel();
      await transactionSub.cancel();
    };

    return controller.stream;
  }

  Future<List<WalletEntry>> getWallets() {
    return _database.walletsDao.getAll();
  }

  Future<void> addWallet({
    required String name,
    required String type,
    int initialBalance = 0,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Nama dompet belum diisi.');
    }
    final duplicateCount = await _database.walletsDao.countDuplicate(
      name: trimmedName,
    );
    if (duplicateCount > 0) {
      throw ArgumentError('Nama dompet sudah digunakan.');
    }
    final now = DateTime.now();
    await _database.walletsDao.add(
      WalletEntriesCompanion.insert(
        name: trimmedName,
        type: type,
        initialBalance: Value(initialBalance),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> updateWallet({
    required WalletEntry wallet,
    required String name,
    required String type,
    required int initialBalance,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Nama dompet belum diisi.');
    }
    final duplicateCount = await _database.walletsDao.countDuplicate(
      name: trimmedName,
      exceptId: wallet.id,
    );
    if (duplicateCount > 0) {
      throw ArgumentError('Nama dompet sudah digunakan.');
    }
    await _database.walletsDao.updateEntry(
      wallet
          .copyWith(
            name: trimmedName,
            type: type,
            initialBalance: initialBalance,
            updatedAt: DateTime.now(),
          )
          .toCompanion(true),
    );
  }

  Future<String?> deleteWallet(int walletId) async {
    final count = await _database.transactionsDao.countByWallet(walletId);
    if (count > 0) {
      return 'Dompet ini masih memiliki transaksi.';
    }

    await _database.walletsDao.deleteById(walletId);
    return null;
  }

  Future<int> transactionCount(int walletId) {
    return _database.transactionsDao.countByWallet(walletId);
  }

  /// Menyesuaikan saldo dompet ke [targetBalance]. Selisihnya dicatat sebagai
  /// transaksi "Penyesuaian Saldo". Mengembalikan selisih bertanda: positif
  /// untuk pemasukan, negatif untuk pengeluaran, dan 0 jika saldo sudah sesuai.
  Future<int> adjustBalance({
    required int walletId,
    required int targetBalance,
  }) async {
    if (targetBalance < 0) {
      throw ArgumentError('Saldo tidak boleh negatif.');
    }

    return _database.transaction(() async {
      final now = DateTime.now();
      final wallets = await _database.walletsDao.getAll();
      WalletEntry? wallet;
      for (final item in wallets) {
        if (item.id == walletId) wallet = item;
      }
      if (wallet == null) {
        throw ArgumentError('Dompet tidak ditemukan.');
      }

      final transactions = await _database.transactionsDao.getAll();
      final current = CalculationHelper.walletBalance(
        walletId: wallet.id,
        initialBalance: wallet.initialBalance,
        transactions: transactions.map(
          (transaction) => (
            walletId: transaction.walletId,
            transferWalletId: transaction.transferWalletId,
            type: transaction.type,
            amount: transaction.amount,
          ),
        ),
      );

      final difference = targetBalance - current;
      if (difference == 0) return 0;

      final type = difference > 0
          ? TransactionType.income
          : TransactionType.expense;
      final categoryId = await _adjustmentCategoryId(type, now);
      await _database.transactionsDao.add(
        TransactionEntriesCompanion(
          type: Value(type.value),
          amount: Value(difference.abs()),
          categoryId: Value(categoryId),
          walletId: Value(wallet.id),
          date: Value(now),
          note: const Value('Penyesuaian saldo'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      return difference;
    });
  }

  Future<int> _adjustmentCategoryId(TransactionType type, DateTime now) async {
    final categories = await _database.categoriesDao.getAll();
    for (final category in categories) {
      if (category.name == 'Penyesuaian Saldo' &&
          category.type == type.value &&
          !category.isArchived) {
        return category.id;
      }
    }

    return _database.categoriesDao.add(
      CategoryEntriesCompanion.insert(
        name: 'Penyesuaian Saldo',
        type: type.value,
        groupName: 'Lainnya',
        iconKey: 'adjustment',
        colorValue: 0xFF64748B,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> setArchived(WalletEntry wallet, bool value) async {
    await _database.walletsDao.updateEntry(
      wallet
          .copyWith(isArchived: value, updatedAt: DateTime.now())
          .toCompanion(true),
    );
  }
}
