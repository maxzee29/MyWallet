import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:faddompet/l10n/app_language.dart';
import 'package:faddompet/l10n/app_text.dart' as app;
import 'package:faddompet/l10n/tr.dart';

void main() {
  tearDown(() {
    AppLocale.current = AppLanguage.indonesian;
  });

  test('plain texts are translated from the dictionary', () {
    expect(translateToEnglish('Pengaturan'), 'Settings');
    expect(translateToEnglish('Simpan Transaksi'), 'Save Transaction');
    expect(translateToEnglish('TOTAL SALDO'), 'TOTAL BALANCE');
    expect(translateToEnglish('Makanan'), 'Food');
  });

  test('unknown texts such as notes stay as typed', () {
    expect(translateToEnglish('janjiw'), 'janjiw');
    expect(translateToEnglish('Rp••••'), 'Rp••••');
    expect(translateToEnglish(''), '');
  });

  test('texts with numbers and names use patterns', () {
    expect(translateToEnglish('Selamat siang, Rina'), 'Good afternoon, Rina');
    expect(translateToEnglish('1 dompet'), '1 wallet');
    expect(translateToEnglish('4 dompet'), '4 wallets');
    expect(translateToEnglish('Terbesar: Makanan'), 'Largest: Food');
    expect(translateToEnglish('Keluar Rp37.000'), 'Spent Rp37.000');
    expect(
      translateToEnglish('Rp760.500 dari Rp2.000.000'),
      'Rp760.500 of Rp2.000.000',
    );
    expect(translateToEnglish('dari Rp2.000.000'), 'of Rp2.000.000');
  });

  test('generated insight sentences are translated', () {
    expect(
      translateToEnglish(
        'Pemasukan lebih besar Rp945.000 dari pengeluaran. '
        'Kamu menyisihkan 94% dari pemasukan.',
      ),
      'Income is Rp945.000 higher than spending. You saved 94% of your income.',
    );
    expect(
      translateToEnglish('Makanan, Parkir, dan 2 lainnya melewati batas yang kamu atur.'),
      'Food, Parking, and 2 more went over the limit you set.',
    );
  });

  test('dates and times switch to English names and format', () {
    expect(translateToEnglish('Kamis, 5 November'), 'Thursday, 5 November');
    expect(
      translateToEnglish('Jumat, 30 Oktober 2026 • 12.02'),
      'Friday, 30 October 2026 • 12:02',
    );
    expect(translateToEnglish('Hari ini, 18.43'), 'Today, 18:43');
    expect(translateToEnglish('Minggu, 1 November 2026'), 'Sunday, 1 November 2026');
  });

  test('parts joined with bullets are translated one by one', () {
    expect(
      translateToEnglish('Makanan • Gopay • 12.02'),
      'Food • Gopay • 12:02',
    );
    expect(
      translateToEnglish('Ikuti perangkat • Material You • English'),
      'Follow device • Material You • English',
    );
  });

  test('tr keeps Indonesian unless English is selected', () {
    expect(tr('Pengaturan'), 'Pengaturan');

    AppLocale.current = AppLanguage.english;
    expect(tr('Pengaturan'), 'Settings');
  });

  testWidgets('Text widget follows the active language', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: app.Text('Pengaturan'))),
    );
    expect(find.text('Pengaturan'), findsOneWidget);

    AppLocale.current = AppLanguage.english;
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: app.Text('Pengaturan', key: ValueKey('english'))),
      ),
    );
    expect(find.text('Settings'), findsOneWidget);
  });
}
