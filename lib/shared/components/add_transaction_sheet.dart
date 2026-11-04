import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_accent.dart';
import '../../app/providers/app_providers.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_durations.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_shadows.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/enums/transaction_type.dart';
import '../../core/formatters/currency_formatter.dart';
import '../../core/formatters/report_date_formatter.dart';
import '../../data/local/database/app_database.dart';
import '../../data/repositories/app_models.dart';
import '../helpers/category_icon_mapper.dart';
import '../widgets/top_toast.dart';
import '../widgets/pressable_surface.dart';
import 'amount_keypad.dart';
import 'transaction_type_segmented_control.dart';

enum _NoticeTone { info, warning }

enum _WalletTarget { single, from, to }

class AddTransactionSheet extends ConsumerStatefulWidget {
  const AddTransactionSheet({super.key, this.transaction});

  final TransactionDetail? transaction;

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _adminFeeController = TextEditingController();

  TransactionType _type = TransactionType.expense;
  String _amountDigits = '';
  int? _selectedCategoryId;
  int? _selectedWalletId;
  int? _fromWalletId;
  int? _toWalletId;
  DateTime _selectedDate = DateTime.now();
  String _dateLabel = 'Hari ini';
  String? _noticeMessage;
  _NoticeTone _noticeTone = _NoticeTone.info;
  bool _saving = false;
  bool _showKeypad = true;

  int get _amount => int.tryParse(_amountDigits) ?? 0;

  int get _adminFee => int.tryParse(_adminFeeController.text) ?? 0;

  bool get _showsAdminFee =>
      _type == TransactionType.transfer && widget.transaction == null;

  Color get _accentColor {
    switch (_type) {
      case TransactionType.expense:
        return AppColors.expenseRed;
      case TransactionType.income:
        return AppColors.incomeGreen;
      case TransactionType.transfer:
        return AppColors.infoBlue;
    }
  }

  String get _amountHelper {
    switch (_type) {
      case TransactionType.expense:
        return 'Uang keluar dari dompet pilihan.';
      case TransactionType.income:
        return 'Uang masuk ke dompet pilihan.';
      case TransactionType.transfer:
        return 'Pindahkan saldo tanpa dihitung sebagai pemasukan.';
    }
  }

  @override
  void initState() {
    super.initState();
    final transaction = widget.transaction;
    if (transaction != null) {
      _type = transaction.type;
      _amountDigits = transaction.transaction.amount.toString();
      _selectedCategoryId = transaction.transaction.categoryId;
      _selectedWalletId = transaction.transaction.walletId;
      _fromWalletId = transaction.transaction.walletId;
      _toWalletId = transaction.transaction.transferWalletId;
      _selectedDate = transaction.transaction.date;
      _dateLabel = 'Pilih tanggal';
      _noteController.text = transaction.transaction.note ?? '';
      _showKeypad = false;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _adminFeeController.dispose();
    super.dispose();
  }

  void _selectType(int index, List<CategoryEntry> categories) {
    setState(() {
      _type = TransactionType.values[index];
      _noticeMessage = null;
      if (_type != TransactionType.transfer) {
        _selectedCategoryId = _firstCategory(categories)?.id;
      }
    });
  }

  void _appendDigit(String value) {
    setState(() {
      final next = (_amountDigits + value).replaceFirst(RegExp(r'^0+'), '');
      _amountDigits = next.length > 12 ? next.substring(0, 12) : next;
      _noticeMessage = null;
    });
  }

  void _backspace() {
    if (_amountDigits.isEmpty) return;

    setState(() {
      _amountDigits = _amountDigits.substring(0, _amountDigits.length - 1);
      _noticeMessage = null;
    });
  }

  Future<void> _selectDate(String label) async {
    if (label == 'Pilih tanggal') {
      final picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      );
      if (picked == null) return;
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
        _dateLabel = label;
        _noticeMessage = null;
      });
      return;
    }

    if (label == 'Pilih waktu') {
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );
      if (picked == null) return;
      setState(() {
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          picked.hour,
          picked.minute,
        );
        _dateLabel = label;
        _noticeMessage = null;
      });
      return;
    }

    final now = DateTime.now();
    setState(() {
      final value = label == 'Kemarin'
          ? now.subtract(const Duration(days: 1))
          : now;
      _selectedDate = DateTime(
        value.year,
        value.month,
        value.day,
        value.hour,
        value.minute,
      );
      _dateLabel = label;
      _noticeMessage = null;
    });
  }

  Future<void> _submit(List<WalletBalance> wallets) async {
    if (_amount <= 0) {
      _showNotice('Masukkan nominal terlebih dahulu.', _NoticeTone.warning);
      return;
    }

    final walletId = _type == TransactionType.transfer
        ? _fromWalletId
        : _selectedWalletId;
    if (walletId == null) {
      _showNotice('Pilih dompet terlebih dahulu.', _NoticeTone.warning);
      return;
    }

    if (_type != TransactionType.transfer && _selectedCategoryId == null) {
      _showNotice('Pilih kategori terlebih dahulu.', _NoticeTone.warning);
      return;
    }

    if (_type == TransactionType.transfer) {
      if (_toWalletId == null) {
        _showNotice(
          'Pilih dompet tujuan terlebih dahulu.',
          _NoticeTone.warning,
        );
        return;
      }
      if (_toWalletId == walletId) {
        _showNotice('Pilih dompet tujuan yang berbeda.', _NoticeTone.warning);
        return;
      }
    }

    setState(() => _saving = true);

    try {
      await ref
          .read(transactionRepositoryProvider)
          .save(
            id: widget.transaction?.transaction.id,
            type: _type,
            amount: _amount,
            categoryId: _selectedCategoryId,
            walletId: walletId,
            transferWalletId: _toWalletId,
            date: _selectedDate,
            note: _noteController.text,
            adminFee: _showsAdminFee ? _adminFee : 0,
          );

      if (!mounted) return;
      TopToast.show(
        context,
        widget.transaction == null
            ? 'Transaksi berhasil disimpan.'
            : 'Transaksi berhasil diperbarui.',
        type: TopToastType.success,
      );
      Navigator.pop(context);
    } on ArgumentError catch (error) {
      _showNotice(error.message.toString(), _NoticeTone.warning);
    } catch (_) {
      _showNotice('Transaksi belum bisa disimpan.', _NoticeTone.warning);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _showNotice(String message, _NoticeTone tone) {
    TopToast.show(
      context,
      message,
      type: tone == _NoticeTone.warning
          ? TopToastType.warning
          : TopToastType.info,
    );
    setState(() {
      _noticeMessage = message;
      _noticeTone = tone;
    });
  }

  @override
  Widget build(BuildContext context) {
    final walletsAsync = ref.watch(walletBalancesProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return walletsAsync.when(
      data: (wallets) => categoriesAsync.when(
        data: (categories) => _buildSheet(context, wallets, categories),
        loading: () => const _SheetLoading(),
        error: (_, _) =>
            const _SheetLoading(message: 'Kategori belum bisa dimuat'),
      ),
      loading: () => const _SheetLoading(),
      error: (_, _) => const _SheetLoading(message: 'Dompet belum bisa dimuat'),
    );
  }

  Widget _buildSheet(
    BuildContext context,
    List<WalletBalance> wallets,
    List<CategoryEntry> categories,
  ) {
    _ensureDefaults(wallets, categories);

    final theme = Theme.of(context);
    final brightness = theme.colorScheme.brightness;
    final isDark = brightness == Brightness.dark;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final visibleCategories = _visibleCategories(categories);
    final selectableWallets = _selectableWallets(wallets);

    if (selectableWallets.isEmpty) {
      return const _SheetLoading(message: 'Aktifkan dompet terlebih dahulu');
    }

    final selectedCategory = _categoryById(categories, _selectedCategoryId);
    final singleWallet = _walletById(selectableWallets, _selectedWalletId);
    final fromWallet = _walletById(selectableWallets, _fromWalletId);
    final toWallet = _walletById(selectableWallets, _toWalletId);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: FractionallySizedBox(
        heightFactor: 1,
        alignment: Alignment.bottomCenter,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: kIsWeb ? AppSpacing.webMaxWidth : double.infinity,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.surface,
                borderRadius: AppRadius.sheet,
                border: Border.all(
                  color: isDark
                      ? AppColors.darkBorderSubtle
                      : AppColors.borderSubtle,
                ),
                boxShadow: AppShadows.nav(brightness),
              ),
              clipBehavior: Clip.antiAlias,
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    _PageHeader(
                      title: widget.transaction == null
                          ? 'Tambah Transaksi'
                          : 'Ubah Transaksi',
                      onBack: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screen,
                          AppSpacing.sm,
                          AppSpacing.screen,
                          AppSpacing.xl,
                        ),
                        children: [
                          TransactionTypeSegmentedControl(
                            labels: TransactionType.values
                                .map((type) => type.label)
                                .toList(),
                            selectedIndex: _type.index,
                            accentColor: _accentColor,
                            onChanged: (index) =>
                                _selectType(index, categories),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _AmountCard(
                            amountText: CurrencyFormatter.rupiah(
                              _amount,
                            ).replaceFirst('Rp', ''),
                            isEmpty: _amount == 0,
                            helper: _amountHelper,
                            accentColor: _accentColor,
                            showKeypad: _showKeypad,
                            onToggleKeypad: () =>
                                setState(() => _showKeypad = !_showKeypad),
                            onDigitPressed: _appendDigit,
                            onBackspacePressed: _backspace,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          const _FormSectionLabel('Detail transaksi'),
                          const SizedBox(height: AppSpacing.md),
                          _TitleField(controller: _noteController),
                          const SizedBox(height: AppSpacing.lg),
                          _FormCard(
                            children: [
                              if (_type == TransactionType.transfer) ...[
                                _PickerRow(
                                  icon: Icons.logout_rounded,
                                  color: _accentColor,
                                  label: 'Dari dompet',
                                  value: fromWallet?.wallet.name ??
                                      'Pilih dompet',
                                  caption: fromWallet == null
                                      ? null
                                      : 'Saldo ${CurrencyFormatter.rupiah(fromWallet.balance)}',
                                  onTap: () => _pickWallet(
                                    selectableWallets,
                                    _WalletTarget.from,
                                  ),
                                ),
                                _PickerRow(
                                  icon: Icons.login_rounded,
                                  color: _accentColor,
                                  label: 'Ke dompet',
                                  value:
                                      toWallet?.wallet.name ?? 'Pilih dompet',
                                  caption: toWallet == null
                                      ? null
                                      : 'Saldo ${CurrencyFormatter.rupiah(toWallet.balance)}',
                                  onTap: () => _pickWallet(
                                    selectableWallets,
                                    _WalletTarget.to,
                                  ),
                                ),
                              ] else ...[
                                _PickerRow(
                                  icon: selectedCategory == null
                                      ? Icons.category_rounded
                                      : categoryIconForEntry(selectedCategory),
                                  color: selectedCategory == null
                                      ? _accentColor
                                      : Color(selectedCategory.colorValue),
                                  label: 'Kategori',
                                  value:
                                      selectedCategory?.name ??
                                      'Pilih kategori',
                                  onTap: () => _pickCategory(visibleCategories),
                                ),
                                _PickerRow(
                                  icon: singleWallet == null
                                      ? Icons.account_balance_wallet_rounded
                                      : _walletIcon(singleWallet.wallet.type),
                                  color: AppColors.infoBlue,
                                  label: 'Dompet',
                                  value:
                                      singleWallet?.wallet.name ??
                                      'Pilih dompet',
                                  caption: singleWallet == null
                                      ? null
                                      : 'Saldo ${CurrencyFormatter.rupiah(singleWallet.balance)}',
                                  onTap: () => _pickWallet(
                                    selectableWallets,
                                    _WalletTarget.single,
                                  ),
                                ),
                              ],
                              _PickerRow(
                                icon: Icons.event_rounded,
                                color: AppColors.warningOrange,
                                label: 'Tanggal & waktu',
                                value:
                                    '${ReportDateFormatter.fullDayLong(_selectedDate)} • ${ReportDateFormatter.time(_selectedDate)}',
                                onTap: _pickDate,
                              ),
                            ],
                          ),
                          if (_showsAdminFee) ...[
                            const SizedBox(height: AppSpacing.xl),
                            _AdminFeeField(
                              controller: _adminFeeController,
                              transferAmount: _amount,
                              onChanged: () => setState(() {}),
                            ),
                          ],
                        ],
                      ),
                    ),
                    _SheetFooter(
                      noticeMessage: _noticeMessage,
                      noticeTone: _noticeTone,
                      saving: _saving,
                      onSubmit: () => _submit(selectableWallets),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  CategoryEntry? _categoryById(List<CategoryEntry> categories, int? id) {
    if (id == null) return null;
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  WalletBalance? _walletById(List<WalletBalance> wallets, int? id) {
    if (id == null) return null;
    for (final item in wallets) {
      if (item.wallet.id == id) return item;
    }
    return null;
  }

  void _pickCategory(List<CategoryEntry> categories) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _CategorySheet(
        categories: categories,
        type: _type,
        selectedId: _selectedCategoryId,
        onSelected: (category) {
          Navigator.pop(sheetContext);
          setState(() {
            _selectedCategoryId = category.id;
            _noticeMessage = null;
          });
        },
      ),
    );
  }

  void _pickWallet(List<WalletBalance> wallets, _WalletTarget target) {
    final selected = switch (target) {
      _WalletTarget.single => _selectedWalletId,
      _WalletTarget.from => _fromWalletId,
      _WalletTarget.to => _toWalletId,
    };
    final title = switch (target) {
      _WalletTarget.single => 'Pilih dompet',
      _WalletTarget.from => 'Dari dompet',
      _WalletTarget.to => 'Ke dompet',
    };

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _WalletSheet(
        title: title,
        wallets: wallets,
        selectedId: selected,
        onSelected: (id) {
          Navigator.pop(sheetContext);
          setState(() {
            switch (target) {
              case _WalletTarget.single:
                _selectedWalletId = id;
              case _WalletTarget.from:
                _fromWalletId = id;
                if (_toWalletId == id) {
                  _toWalletId = wallets
                      .map((item) => item.wallet.id)
                      .firstWhere((item) => item != id, orElse: () => id);
                }
              case _WalletTarget.to:
                _toWalletId = id;
                if (_fromWalletId == id) {
                  _fromWalletId = wallets
                      .map((item) => item.wallet.id)
                      .firstWhere((item) => item != id, orElse: () => id);
                }
            }
            _noticeMessage = null;
          });
        },
      ),
    );
  }

  void _pickDate() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => _DateSheet(
        selectedOption: _dateLabel,
        onSelected: (label) {
          Navigator.pop(sheetContext);
          _selectDate(label);
        },
      ),
    );
  }

  void _ensureDefaults(
    List<WalletBalance> wallets,
    List<CategoryEntry> categories,
  ) {
    if (wallets.isNotEmpty) {
      final selectableWallets = _selectableWallets(wallets);
      if (selectableWallets.isEmpty) return;
      _selectedWalletId ??= selectableWallets.first.wallet.id;
      _fromWalletId ??= selectableWallets.first.wallet.id;
      if (selectableWallets.length > 1) {
        _toWalletId ??= selectableWallets[1].wallet.id;
      } else {
        _toWalletId ??= selectableWallets.first.wallet.id;
      }
    }

    if (_type != TransactionType.transfer) {
      _selectedCategoryId ??= _firstCategory(categories)?.id;
    }
  }

  List<CategoryEntry> _visibleCategories(List<CategoryEntry> categories) {
    return categories
        .where(
          (category) =>
              !category.isArchived &&
              (category.type == _type.value || category.type == 'both'),
        )
        .toList();
  }

  List<WalletBalance> _selectableWallets(List<WalletBalance> wallets) {
    final selectedIds = {
      if (_selectedWalletId != null) _selectedWalletId,
      if (_fromWalletId != null) _fromWalletId,
      if (_toWalletId != null) _toWalletId,
    };
    return wallets
        .where(
          (wallet) =>
              !wallet.wallet.isArchived ||
              selectedIds.contains(wallet.wallet.id),
        )
        .toList();
  }

  CategoryEntry? _firstCategory(List<CategoryEntry> categories) {
    final visible = _visibleCategories(categories);
    if (visible.isEmpty) return null;
    final frequent = _frequentLabels(_type);
    return visible.firstWhere(
      (category) => frequent.contains(category.name),
      orElse: () => visible.first,
    );
  }
}

class _AdminFeeField extends StatelessWidget {
  const _AdminFeeField({
    required this.controller,
    required this.transferAmount,
    required this.onChanged,
  });

  final TextEditingController controller;
  final int transferAmount;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.colorScheme.brightness == Brightness.dark;
    final fee = int.tryParse(controller.text) ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SheetSectionTitle(
          title: 'Biaya admin',
          subtitle: 'Opsional. Dipotong dari dompet asal sebagai pengeluaran.',
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(9),
          ],
          onChanged: (_) => onChanged(),
          cursorColor: theme.colorScheme.primary,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            prefixText: 'Rp ',
            hintText: '0',
            hintStyle: theme.textTheme.bodyMedium,
            filled: true,
            fillColor: isDark
                ? AppColors.darkSurfaceSoft
                : AppColors.surfaceSoft,
            contentPadding: const EdgeInsets.all(AppSpacing.lg),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.input,
              borderSide: BorderSide(
                color: isDark
                    ? AppColors.darkBorderSubtle
                    : AppColors.borderSubtle,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.input,
              borderSide: BorderSide(
                color: theme.colorScheme.primary.withValues(alpha: 0.46),
              ),
            ),
          ),
        ),
        if (fee > 0 && transferAmount > 0) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            'Total keluar dari dompet asal: ${CurrencyFormatter.rupiah(transferAmount + fee)}',
            style: theme.textTheme.labelMedium,
          ),
        ],
      ],
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.colorScheme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.lg,
        AppSpacing.screen,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Kembali',
            child: GestureDetector(
              onTap: onBack,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: AppSpacing.iconTile,
                height: AppSpacing.iconTile,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceSoft
                      : AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(child: Text(title, style: theme.textTheme.headlineSmall)),
        ],
      ),
    );
  }
}

class _AmountCard extends StatelessWidget {
  const _AmountCard({
    required this.amountText,
    required this.isEmpty,
    required this.helper,
    required this.accentColor,
    required this.showKeypad,
    required this.onToggleKeypad,
    required this.onDigitPressed,
    required this.onBackspacePressed,
  });

  final String amountText;
  final bool isEmpty;
  final String helper;
  final Color accentColor;
  final bool showKeypad;
  final VoidCallback onToggleKeypad;
  final ValueChanged<String> onDigitPressed;
  final VoidCallback onBackspacePressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.colorScheme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(
          color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nominal', style: theme.textTheme.labelLarge),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isDark ? 0.18 : 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Text(
                  'Rp IDR',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      amountText,
                      maxLines: 1,
                      style: theme.textTheme.displayMedium?.copyWith(
                        color: isEmpty
                            ? theme.colorScheme.onSurfaceVariant
                            : accentColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Semantics(
                button: true,
                label: showKeypad ? 'Sembunyikan tombol angka' : 'Tampilkan tombol angka',
                child: GestureDetector(
                  onTap: onToggleKeypad,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: AppSpacing.iconTile,
                    height: AppSpacing.iconTile,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(
                        alpha: showKeypad ? 0.22 : 0.12,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Icon(Icons.dialpad_rounded, color: accentColor),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(helper, style: theme.textTheme.labelSmall),
          if (showKeypad) ...[
            const SizedBox(height: AppSpacing.lg),
            AmountKeypad(
              accentColor: accentColor,
              onDigitPressed: onDigitPressed,
              onBackspacePressed: onBackspacePressed,
            ),
          ],
        ],
      ),
    );
  }
}

class _FormSectionLabel extends StatelessWidget {
  const _FormSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        letterSpacing: 1.2,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _TitleField extends StatelessWidget {
  const _TitleField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.colorScheme.brightness == Brightness.dark;

    return TextField(
      controller: controller,
      maxLength: 120,
      cursorColor: theme.colorScheme.primary,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        counterText: '',
        hintText: 'Judul (mis. Makan siang)',
        hintStyle: theme.textTheme.bodyMedium,
        prefixIcon: Icon(
          Icons.edit_note_rounded,
          color: context.accent.color,
        ),
        filled: true,
        fillColor: isDark ? AppColors.darkSurfaceElevated : AppColors.surfaceSoft,
        contentPadding: const EdgeInsets.all(AppSpacing.lg),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.46),
          ),
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    final border = isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0) Divider(height: 1, color: border),
            children[index],
          ],
        ],
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.onTap,
    this.caption,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String? caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.colorScheme.brightness == Brightness.dark;

    return PressableSurface(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.18 : 0.10),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
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
                  if (caption != null) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(caption!, style: theme.textTheme.labelSmall),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceSoft
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategorySheet extends StatelessWidget {
  const _CategorySheet({
    required this.categories,
    required this.type,
    required this.selectedId,
    required this.onSelected,
  });

  final List<CategoryEntry> categories;
  final TransactionType type;
  final int? selectedId;
  final ValueChanged<CategoryEntry> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxHeight = MediaQuery.of(context).size.height * 0.8;

    final frequent = <CategoryEntry>[];
    for (final name in _frequentLabels(type)) {
      for (final category in categories) {
        if (category.name == name) {
          frequent.add(category);
          break;
        }
      }
    }
    final grouped = <String, List<CategoryEntry>>{};
    for (final category in categories) {
      grouped.putIfAbsent(category.groupName, () => []).add(category);
    }

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
            Text('Pilih kategori', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            if (frequent.isNotEmpty) ..._section(context, 'Sering dipakai', frequent),
            for (final entry in grouped.entries)
              ..._section(context, entry.key, entry.value),
          ],
        ),
      ),
    );
  }

  List<Widget> _section(
    BuildContext context,
    String title,
    List<CategoryEntry> items,
  ) {
    final theme = Theme.of(context);

    return [
      Padding(
        padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.xs),
        child: Text(title, style: theme.textTheme.labelLarge),
      ),
      for (final item in items)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(categoryIconForEntry(item), color: Color(item.colorValue)),
          title: Text(item.name),
          trailing: selectedId == item.id
              ? Icon(Icons.check_rounded, color: theme.colorScheme.primary)
              : null,
          onTap: () => onSelected(item),
        ),
    ];
  }
}

class _WalletSheet extends StatelessWidget {
  const _WalletSheet({
    required this.title,
    required this.wallets,
    required this.selectedId,
    required this.onSelected,
  });

  final String title;
  final List<WalletBalance> wallets;
  final int? selectedId;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxHeight = MediaQuery.of(context).size.height * 0.7;

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
            const SizedBox(height: AppSpacing.sm),
            for (final item in wallets)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  _walletIcon(item.wallet.type),
                  color: theme.colorScheme.primary,
                ),
                title: Text(item.wallet.name),
                subtitle: Text('Saldo ${CurrencyFormatter.rupiah(item.balance)}'),
                trailing: selectedId == item.wallet.id
                    ? Icon(Icons.check_rounded, color: theme.colorScheme.primary)
                    : null,
                onTap: () => onSelected(item.wallet.id),
              ),
          ],
        ),
      ),
    );
  }
}

class _DateSheet extends StatelessWidget {
  const _DateSheet({required this.selectedOption, required this.onSelected});

  final String selectedOption;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const options = ['Hari ini', 'Kemarin', 'Pilih tanggal', 'Pilih waktu'];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          0,
          AppSpacing.screen,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tanggal & waktu', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            for (final option in options)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(option),
                trailing: selectedOption == option
                    ? Icon(Icons.check_rounded, color: theme.colorScheme.primary)
                    : null,
                onTap: () => onSelected(option),
              ),
          ],
        ),
      ),
    );
  }
}

class _SheetFooter extends StatelessWidget {
  const _SheetFooter({
    required this.noticeMessage,
    required this.noticeTone,
    required this.saving,
    required this.onSubmit,
  });

  final String? noticeMessage;
  final _NoticeTone noticeTone;
  final bool saving;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.colorScheme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.lg,
        AppSpacing.screen,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (noticeMessage != null) ...[
            _InlineNotice(message: noticeMessage!, tone: noticeTone),
            const SizedBox(height: AppSpacing.md),
          ],
          PressableSurface(
            onTap: onSubmit,
            enabled: !saving,
            child: AnimatedContainer(
              duration: AppDurations.normal,
              curve: AppDurations.easeOut,
              width: double.infinity,
              constraints: const BoxConstraints(
                minHeight: AppSpacing.huge + AppSpacing.lg,
              ),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.accent.color,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: [
                  BoxShadow(
                    color: context.accent.color
                        .withValues(alpha: isDark ? 0.18 : 0.14),
                    blurRadius: AppSpacing.xxl,
                    offset: const Offset(0, AppSpacing.md),
                  ),
                ],
              ),
              child: Text(
                saving ? 'Menyimpan...' : 'Simpan Transaksi',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: isDark ? AppColors.darkBackground : AppColors.onDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.message, required this.tone});

  final String message;
  final _NoticeTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.colorScheme.brightness == Brightness.dark;
    final color = tone == _NoticeTone.warning
        ? AppColors.warningOrange
        : AppColors.infoBlue;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: theme.textTheme.labelLarge?.copyWith(color: color),
      ),
    );
  }
}

class _SheetSectionTitle extends StatelessWidget {
  const _SheetSectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(subtitle, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

class _SheetLoading extends StatelessWidget {
  const _SheetLoading({this.message = 'Menyiapkan data lokal'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.sheet,
      ),
      child: Text(message),
    );
  }
}

List<String> _frequentLabels(TransactionType type) {
  switch (type) {
    case TransactionType.expense:
      return [
        'Makanan',
        'Transportasi',
        'Belanja Harian',
        'Tagihan',
        'Langganan Aplikasi',
        'Lainnya',
      ];
    case TransactionType.income:
      return ['Gaji', 'Jasa', 'Project', 'Uang Saku', 'Cashback', 'Lainnya'];
    case TransactionType.transfer:
      return const [];
  }
}

IconData _walletIcon(String type) {
  switch (type) {
    case 'ewallet':
      return Icons.account_balance_wallet_rounded;
    case 'bank':
      return Icons.account_balance_rounded;
    case 'savings':
      return Icons.savings_rounded;
    default:
      return Icons.payments_rounded;
  }
}
