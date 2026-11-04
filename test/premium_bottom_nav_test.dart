import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:faddompet/app/theme/app_theme.dart';
import 'package:faddompet/shared/widgets/premium_bottom_nav.dart';

Widget _app({required bool showLabels}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: Align(
        alignment: Alignment.bottomCenter,
        child: PremiumBottomNav(
          currentIndex: 0,
          showLabels: showLabels,
          onChanged: (_) {},
          onAddPressed: () {},
          items: const [
            PremiumBottomNavItem(
              icon: Icons.home_outlined,
              selectedIcon: Icons.home_rounded,
              label: 'Beranda',
            ),
            PremiumBottomNavItem(
              icon: Icons.insights_outlined,
              selectedIcon: Icons.insights_rounded,
              label: 'Laporan',
            ),
            PremiumBottomNavItem(
              icon: Icons.account_balance_wallet_outlined,
              selectedIcon: Icons.account_balance_wallet_rounded,
              label: 'Dompet',
            ),
            PremiumBottomNavItem(
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings_rounded,
              label: 'Pengaturan',
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('menu labels are shown by default', (WidgetTester tester) async {
    await tester.pumpWidget(_app(showLabels: true));

    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Laporan'), findsOneWidget);
  });

  testWidgets('menu labels can be hidden', (WidgetTester tester) async {
    await tester.pumpWidget(_app(showLabels: false));

    expect(find.text('Beranda'), findsNothing);
    expect(find.text('Pengaturan'), findsNothing);
  });
}
