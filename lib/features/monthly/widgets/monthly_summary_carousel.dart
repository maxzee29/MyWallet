import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/formatters/currency_formatter.dart';
import '../../../data/repositories/monthly_report_models.dart';

class MonthlySummaryCarousel extends StatefulWidget {
  const MonthlySummaryCarousel({
    super.key,
    required this.report,
    required this.hideBalance,
  });

  final MonthlyReport report;
  final bool hideBalance;

  @override
  State<MonthlySummaryCarousel> createState() => _MonthlySummaryCarouselState();
}

class _MonthlySummaryCarouselState extends State<MonthlySummaryCarousel> {
  final PageController _controller = PageController(viewportFraction: 0.92);
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    String money(int value) =>
        CurrencyFormatter.rupiah(value, hidden: widget.hideBalance);

    final net = report.net;
    final netStatus = net > 0 ? 'Surplus' : (net < 0 ? 'Defisit' : 'Seimbang');
    var netFooter = 'Belum ada pemasukan';
    if (report.income > 0) {
      final percent = (net / report.income * 100)
          .toStringAsFixed(1)
          .replaceAll('.', ',');
      netFooter = '$percent% dari pemasukan';
    }

    final topExpense = report.expenseCategories.isEmpty
        ? null
        : report.expenseCategories.first;
    final topIncome = report.incomeCategories.isEmpty
        ? null
        : report.incomeCategories.first;

    final cards = <Widget>[
      _CarouselCard(
        title: 'Arus Kas Bersih',
        icon: Icons.stacked_bar_chart_rounded,
        colors: net >= 0
            ? const [AppColors.incomeGreen, Color(0xFF166534)]
            : const [AppColors.expenseRed, Color(0xFF991B1B)],
        footer: netFooter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BigValue(money(net)),
            const SizedBox(height: AppSpacing.xs),
            _MutedText(netStatus),
          ],
        ),
      ),
      _CarouselCard(
        title: 'Masuk & Keluar',
        icon: Icons.swap_vert_rounded,
        colors: const [AppColors.primary, AppColors.primaryDark],
        footer: '${report.transactions.length} transaksi tercatat',
        child: Row(
          children: [
            Expanded(
              child: _Stat(label: 'Pemasukan', value: money(report.income)),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _Stat(label: 'Pengeluaran', value: money(report.expense)),
            ),
          ],
        ),
      ),
      _CarouselCard(
        title: 'Rata-rata Harian',
        icon: Icons.calendar_month_rounded,
        colors: const [AppColors.infoBlue, Color(0xFF1E3A8A)],
        footer: '${report.daysCounted} hari',
        child: Row(
          children: [
            Expanded(
              child: _Stat(
                label: 'Pengeluaran',
                value: money(report.averageDailyExpense),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _Stat(
                label: 'Pemasukan',
                value: money(report.averageDailyIncome),
              ),
            ),
          ],
        ),
      ),
      _CarouselCard(
        title: 'Kategori Teratas',
        icon: Icons.star_rounded,
        colors: const [AppColors.warningOrange, Color(0xFFC2410C)],
        footer: 'Berdasarkan total bulan ini',
        child: Row(
          children: [
            Expanded(
              child: _Stat(
                label: 'Pengeluaran',
                value: topExpense?.label ?? '-',
                caption: topExpense == null ? null : money(topExpense.amount),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _Stat(
                label: 'Pemasukan',
                value: topIncome?.label ?? '-',
                caption: topIncome == null ? null : money(topIncome.amount),
              ),
            ),
          ],
        ),
      ),
    ];

    return Column(
      children: [
        SizedBox(
          height: 196,
          child: PageView(
            controller: _controller,
            onPageChanged: (index) => setState(() => _index = index),
            children: [
              for (final card in cards)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  child: card,
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _Dots(count: cards.length, index: _index),
      ],
    );
  }
}

class _CarouselCard extends StatelessWidget {
  const _CarouselCard({
    required this.title,
    required this.icon,
    required this.colors,
    required this.child,
    required this.footer,
  });

  final String title;
  final IconData icon;
  final List<Color> colors;
  final Widget child;
  final String footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
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
          Row(
            children: [
              Icon(icon, color: AppColors.onDark, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.onDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          child,
          const Spacer(),
          Text(
            footer,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.onDarkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _BigValue extends StatelessWidget {
  const _BigValue(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        value,
        maxLines: 1,
        style: theme.textTheme.headlineSmall?.copyWith(
          color: AppColors.onDark,
          fontWeight: FontWeight.w900,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _MutedText extends StatelessWidget {
  const _MutedText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: AppColors.onDarkMuted),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.caption});

  final String label;
  final String value;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppColors.onDarkMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppColors.onDark,
              fontWeight: FontWeight.w900,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        if (caption != null) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            caption!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.onDarkMuted,
            ),
          ),
        ],
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 20 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == index
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
          ),
      ],
    );
  }
}
