import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:faddompet/app/providers/app_providers.dart';
import 'package:faddompet/app/theme/app_theme.dart';
import 'package:faddompet/core/enums/transaction_type.dart';
import 'package:faddompet/data/local/database/app_database.dart';
import 'package:faddompet/data/repositories/app_models.dart';
import 'package:faddompet/features/dashboard/widgets/dashboard_history_section.dart';

final _stamp = DateTime(2026, 1, 1);

final _wallet = WalletEntry(
  id: 1,
  name: 'Gopay',
  type: 'ewallet',
  initialBalance: 0,
  isArchived: false,
  createdAt: _stamp,
  updatedAt: _stamp,
);

final _food = CategoryEntry(
  id: 1,
  name: 'Makanan',
  type: 'expense',
  groupName: 'Harian',
  iconKey: 'food',
  colorValue: 0xFFDC2626,
  isDefault: true,
  isArchived: false,
  createdAt: _stamp,
  updatedAt: _stamp,
);

TransactionDetail _expense({
  required int id,
  required int amount,
  required DateTime date,
  String? note,
}) {
  return TransactionDetail(
    transaction: TransactionEntry(
      id: id,
      type: TransactionType.expense.value,
      amount: amount,
      categoryId: _food.id,
      walletId: _wallet.id,
      date: date,
      note: note,
      createdAt: _stamp,
      updatedAt: _stamp,
    ),
    wallet: _wallet,
    category: _food,
  );
}

Widget _app(List<TransactionDetail> items) {
  return ProviderScope(
    overrides: [
      transactionDetailsProvider.overrideWith((ref) => Stream.value(items)),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SingleChildScrollView(
          child: DashboardHistorySection(hideBalance: false, onSeeAll: () {}),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  testWidgets('history groups transactions by day with a daily total', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _app([
        _expense(
          id: 1,
          amount: 37000,
          date: DateTime(2026, 10, 30, 12, 2),
          note: 'janjiw',
        ),
        _expense(id: 2, amount: 3000, date: DateTime(2026, 10, 29, 14, 8)),
      ]),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Riwayat Transaksi'), findsOneWidget);
    expect(find.text('Jumat, 30 Oktober 2026'), findsOneWidget);
    expect(find.text('Kamis, 29 Oktober 2026'), findsOneWidget);
    expect(find.text('janjiw'), findsOneWidget);
    // Total harian dan nominal baris sama-sama tampil.
    expect(find.text('-Rp37.000'), findsNWidgets(2));
    expect(find.text('-Rp3.000'), findsNWidgets(2));
  });

  testWidgets('history shows an empty state without transactions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_app(const []));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Belum ada transaksi'), findsOneWidget);
  });
}
