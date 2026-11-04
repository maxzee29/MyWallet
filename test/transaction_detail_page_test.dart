import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:faddompet/app/providers/app_providers.dart';
import 'package:faddompet/app/theme/app_theme.dart';
import 'package:faddompet/core/enums/transaction_type.dart';
import 'package:faddompet/data/local/database/app_database.dart';
import 'package:faddompet/data/repositories/app_models.dart';
import 'package:faddompet/features/monthly/widgets/transaction_detail_page.dart';

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

final _detail = TransactionDetail(
  transaction: TransactionEntry(
    id: 1,
    type: TransactionType.expense.value,
    amount: 37000,
    categoryId: _food.id,
    walletId: _wallet.id,
    date: DateTime(2026, 10, 30, 12, 2),
    note: 'janjiw',
    createdAt: _stamp,
    updatedAt: _stamp,
  ),
  wallet: _wallet,
  category: _food,
);

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  testWidgets('detail page shows the amount card and the detail rows', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionDetailsProvider.overrideWith(
            (ref) => Stream.value([_detail]),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: TransactionDetailPage(detail: _detail, hideBalance: false),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Rincian Transaksi'), findsOneWidget);
    expect(find.text('janjiw'), findsOneWidget);
    expect(find.text('-Rp37.000'), findsOneWidget);
    expect(find.text('Makanan'), findsOneWidget);
    expect(find.text('Gopay'), findsOneWidget);
    expect(find.text('Jumat, 30 Oktober 2026 • 12.02'), findsOneWidget);
  });
}
