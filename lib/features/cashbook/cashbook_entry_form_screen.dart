import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/cash_entry.dart';
import '../../core/providers/cashbook_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/cashbook_calculator.dart';
import '../../core/utils/platform_helper.dart';
import 'cashbook_calculator_sheet.dart';
import 'cashbook_items_dialog.dart';
import 'widgets/cashbook_common.dart';

/// Add / edit form for an Account Ledger entry (PARITY-013..030, 048..051).
///
/// - Add: pass [bookId] and [initialCashIn]; optionally [prefill] (copy).
/// - Edit: pass [entry].
class CashbookEntryFormScreen extends ConsumerStatefulWidget {
  final CashEntry? entry;
  final String? bookId;
  final bool initialCashIn;
  final CashEntry? prefill;

  const CashbookEntryFormScreen({
    super.key,
    this.entry,
    this.bookId,
    this.initialCashIn = true,
    this.prefill,
  });

  @override
  ConsumerState<CashbookEntryFormScreen> createState() =>
      _CashbookEntryFormScreenState();
}

class _CashbookEntryFormScreenState
    extends ConsumerState<CashbookEntryFormScreen> {
  static const _maxAttachments = 3;

  late bool _isIn;
  late DateTime _date;
  late String _bookId;
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  final _desc = TextEditingController();
  final _notesFocus = FocusNode();
  final _amountFocus = FocusNode();
  String? _amountError;
  List<CashItem> _items = [];
  List<String> _attachments = [];
  late bool _showDesc;
  bool _saving = false;

  bool get _isEdit => widget.entry != null;

  /// Income created from a bill payment (type is fixed to income).
  bool get _isLinked => widget.entry?.sourceType != null;

  @override
  void initState() {
    super.initState();
    final src = widget.entry ?? widget.prefill;
    _isIn = src?.isCashIn ?? widget.initialCashIn;
    _date = src?.date ?? DateTime.now();
    _bookId = widget.entry?.bookId ??
        widget.bookId ??
        widget.prefill?.bookId ??
        ref.read(currentCashBookProvider)?.id ??
        '';
    if (src != null) {
      _amount.text = _plain(src.amount);
      _notes.text = src.notes;
      _desc.text = src.description ?? '';
      _items = CashItem.decodeList(src.itemsJson);
      _attachments = List.of(src.attachmentPaths ?? const []);
    }
    final settings = ref.read(cashSettingsProvider);
    _showDesc = settings.showDescription || _desc.text.isNotEmpty;
  }

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    _desc.dispose();
    _notesFocus.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  static String _plain(double v) =>
      CashbookCalculator.formatNumber(v).replaceAll(',', '');

  // ---- actions ----

  void _shiftDay(int delta) {
    setState(() {
      _date = DateTime(_date.year, _date.month, _date.day + delta, _date.hour,
          _date.minute, _date.second);
    });
  }

  Future<void> _pickTime() async {
    final settings = ref.read(cashSettingsProvider);
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx)
            .copyWith(alwaysUse24HourFormat: settings.use24Hour),
        child: child!,
      ),
    );
    if (t != null) {
      setState(() => _date =
          DateTime(_date.year, _date.month, _date.day, t.hour, t.minute));
    }
  }

  Future<void> _openCalculator() async {
    final result = await showCashCalculatorSheet(context,
        initial: parseAmount(_amount.text));
    if (result != null) setState(() => _amount.text = _plain(result));
  }

  Future<void> _openItems() async {
    final result = await showCashItemsDialog(context, _items);
    if (result == null) return;
    setState(() {
      _items = result;
      final total = CashItem.totalOf(result);
      if (total > 0) _amount.text = _plain(total);
    });
  }

  Future<String> _storeFile(String sourcePath) async {
    final dir = await getApplicationSupportDirectory();
    final folder = Directory('${dir.path}/cashbook_bills');
    if (!folder.existsSync()) folder.createSync(recursive: true);
    final name = sourcePath.split(Platform.pathSeparator).last;
    final dest = '${folder.path}/${const Uuid().v4()}_$name';
    await File(sourcePath).copy(dest);
    return dest;
  }

  Future<void> _addBill(String kind) async {
    if (_attachments.length >= _maxAttachments) {
      showCashSnack(context, 'Up to $_maxAttachments bills per entry',
          error: true);
      return;
    }
    try {
      String? path;
      if (kind == 'camera') {
        final x = await ImagePicker().pickImage(source: ImageSource.camera);
        path = x?.path;
      } else {
        final r = await FilePicker.platform.pickFiles(
          type: kind == 'pdf' ? FileType.custom : FileType.image,
          allowedExtensions: kind == 'pdf' ? ['pdf'] : null,
        );
        path = r?.files.single.path;
      }
      if (path == null) return;
      final stored = await _storeFile(path);
      if (mounted) setState(() => _attachments.add(stored));
    } catch (e) {
      if (mounted) {
        showCashSnack(context, 'Could not add bill: $e', error: true);
      }
    }
  }

  CashEntry? _buildForSave() {
    final amount = parseAmount(_amount.text);
    if (amount == null) {
      // An empty amount blocks saving (PARITY-018) and says why.
      setState(() => _amountError = 'Enter an amount');
      _amountFocus.requestFocus();
      return null;
    }
    return CashEntry(
      id: widget.entry?.id ?? '',
      bookId: _bookId,
      date: _date,
      amount: amount,
      isCashIn: _isIn,
      notes: _notes.text,
      description: _desc.text.isEmpty ? null : _desc.text,
      attachmentPaths: _attachments.isEmpty ? null : _attachments,
      itemsJson: CashItem.encodeList(_items),
      createdAt: widget.entry?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _save({required bool exit}) async {
    if (_saving) return;
    final built = _buildForSave();
    if (built == null) return;
    setState(() => _saving = true);
    String? error;
    if (_isEdit) {
      final e = widget.entry!;
      e.bookId = built.bookId;
      e.date = built.date;
      e.amount = built.amount;
      e.isCashIn = built.isCashIn;
      e.notes = built.notes;
      e.description = built.description;
      e.attachmentPaths = built.attachmentPaths;
      e.itemsJson = built.itemsJson;
      final (_, err) =
          await ref.read(cashEntriesProvider.notifier).updateEntry(e);
      error = err;
    } else {
      final (_, err) = await ref.read(cashEntriesProvider.notifier).addEntry(
            bookId: built.bookId,
            date: built.date,
            amount: built.amount,
            isCashIn: built.isCashIn,
            notes: built.notes,
            description: built.description,
            attachmentPaths: built.attachmentPaths,
            itemsJson: built.itemsJson,
          );
      error = err;
    }
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      showCashSnack(context, error, error: true);
      return;
    }
    if (exit || _isEdit) {
      Navigator.pop(context, true);
    } else {
      // Save and add another: clear amount and notes, keep the form open.
      setState(() {
        _amount.clear();
        _notes.clear();
        _items = [];
        _attachments = [];
      });
      // Short, so it does not sit on top of the Save buttons.
      showCashSnack(context, 'Saved', duration: const Duration(seconds: 1));
      _amountFocus.requestFocus();
    }
  }

  Future<void> _delete() async {
    final ok = await confirmCashDialog(context,
        title: 'Delete',
        message: 'Move this transaction to Deleted Transactions?');
    if (!ok || !mounted) return;
    await ref.read(cashEntriesProvider.notifier).moveToTrash(widget.entry!.id);
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _copy() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Copy'),
        children: [
          SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, 'same'),
              child: const Text('Copy to same account')),
          SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, 'other'),
              child: const Text('Copy to different account')),
        ],
      ),
    );
    if (choice == null || !mounted) return;
    var target = widget.entry!.bookId;
    if (choice == 'other') {
      final books = ref.read(cashBooksProvider);
      final picked = await showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('Select account'),
          children: [
            for (final b in books)
              SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, b.id),
                  child: Text(b.name)),
          ],
        ),
      );
      if (picked == null || !mounted) return;
      target = picked;
    }
    final copy = widget.entry!.copyWith(bookId: target);
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) =>
            CashbookEntryFormScreen(bookId: target, prefill: copy)));
  }

  // ---- UI ----

  Widget _typeChip(String label, bool value, Color color) {
    final active = _isIn == value;
    return ChoiceChip(
      label: Text(label,
          style: TextStyle(
              color: active ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600)),
      selected: active,
      selectedColor: color,
      backgroundColor: AppColors.surface,
      side: BorderSide(color: active ? color : AppColors.border),
      showCheckmark: false,
      onSelected: _isLinked ? null : (_) => setState(() => _isIn = value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(cashSettingsProvider);
    final books = ref.watch(cashBooksProvider);
    final suggestions = settings.notesSuggestion
        ? ref.watch(cashNoteSuggestionsProvider)
        : <String>[];
    final activeColor = _isIn ? CashColors.income : CashColors.expense;
    final amountLabel = _isIn ? CashLabels.income : CashLabels.expense;
    final title = _isEdit
        ? 'Edit Transaction'
        : (_isIn ? 'Add ${CashLabels.income}' : 'Add ${CashLabels.expense}');

    return Scaffold(
      appBar: cashAppBar(title, actions: [
        if (_isEdit)
          IconButton(
              tooltip: 'Copy',
              icon: const Icon(Icons.copy_outlined),
              onPressed: _copy),
        PopupMenuButton<String>(
          iconColor:
              PlatformHelper.isDesktop ? AppColors.textPrimary : Colors.white,
          onSelected: (v) {
            if (v == 'desc') setState(() => _showDesc = !_showDesc);
          },
          itemBuilder: (_) => [
            PopupMenuItem(
                value: 'desc',
                child: Text(_showDesc
                    ? 'Hide description / Category'
                    : 'Add description / Category')),
          ],
        ),
      ]),
      body: Column(
        children: [
          Expanded(
              child: CashPageBody(
            maxWidth: 700,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        _typeChip(CashLabels.income, true, CashColors.income),
                        const SizedBox(width: 8),
                        _typeChip(
                            CashLabels.expense, false, CashColors.expense),
                      ]),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                      tooltip: 'Previous day',
                                      icon: const Icon(Icons.chevron_left),
                                      onPressed: () => _shiftDay(-1)),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () async {
                                        final p = await showDatePicker(
                                          context: context,
                                          initialDate: _date,
                                          firstDate: DateTime(2000),
                                          lastDate: DateTime(2100),
                                        );
                                        if (p != null) {
                                          setState(() => _date = DateTime(
                                              p.year,
                                              p.month,
                                              p.day,
                                              _date.hour,
                                              _date.minute,
                                              _date.second));
                                        }
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        child: Text(settings.formatDate(_date),
                                            textAlign: TextAlign.center),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                      tooltip: 'Next day',
                                      icon: const Icon(Icons.chevron_right),
                                      onPressed: () => _shiftDay(1)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _pickTime,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.border),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(settings.formatTime(_date)),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.access_time,
                                        size: 18, color: AppColors.primary),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _amount,
                        focusNode: _amountFocus,
                        autofocus: !_isEdit,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [AmountInputFormatter()],
                        onChanged: (_) {
                          if (_amountError != null) {
                            setState(() => _amountError = null);
                          }
                        },
                        style: TextStyle(
                            color: activeColor,
                            fontSize: 20,
                            fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          labelText: amountLabel,
                          errorText: _amountError,
                          prefixText: '₹ ',
                          suffixIcon: IconButton(
                            tooltip: 'Calculator',
                            icon: const Icon(Icons.calculate_outlined,
                                color: AppColors.primary),
                            onPressed: _openCalculator,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      RawAutocomplete<String>(
                        textEditingController: _notes,
                        focusNode: _notesFocus,
                        optionsBuilder: (v) {
                          final q = v.text.trim().toLowerCase();
                          if (q.isEmpty) return const Iterable<String>.empty();
                          return suggestions
                              .where((s) =>
                                  s.toLowerCase().contains(q) &&
                                  s.toLowerCase() != q)
                              .take(5);
                        },
                        fieldViewBuilder: (ctx, c, f, _) => TextField(
                          controller: c,
                          focusNode: f,
                          minLines: 1,
                          maxLines: 3,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(labelText: 'Notes'),
                        ),
                        optionsViewBuilder: (ctx, onSelected, options) => Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(12),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                  maxHeight: 220, maxWidth: 460),
                              child: ListView(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                children: [
                                  for (final o in options)
                                    ListTile(
                                        dense: true,
                                        title: Text(o),
                                        onTap: () => onSelected(o)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_showDesc) ...[
                        const SizedBox(height: 16),
                        TextField(
                          controller: _desc,
                          decoration: const InputDecoration(
                              labelText: 'Description / Category'),
                        ),
                      ],
                      if (_isEdit) ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: books.any((b) => b.id == _bookId)
                              ? _bookId
                              : null,
                          decoration:
                              const InputDecoration(labelText: 'Accounts'),
                          items: [
                            for (final b in books)
                              DropdownMenuItem(
                                  value: b.id, child: Text(b.name)),
                          ],
                          onChanged: (v) =>
                              setState(() => _bookId = v ?? _bookId),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: PopupMenuButton<String>(
                              onSelected: _addBill,
                              itemBuilder: (_) => [
                                if (PlatformHelper.isMobile)
                                  const PopupMenuItem(
                                      value: 'camera', child: Text('Camera')),
                                const PopupMenuItem(
                                    value: 'gallery', child: Text('Gallery')),
                                const PopupMenuItem(
                                    value: 'pdf', child: Text('PDF')),
                              ],
                              child: _OutlinedAction(
                                  icon: Icons.add_a_photo_outlined,
                                  label: _attachments.isEmpty
                                      ? 'Add Bills'
                                      : 'Bills (${_attachments.length})'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _openItems,
                              child: _OutlinedAction(
                                  icon: Icons.list_alt_outlined,
                                  label: _items.isEmpty
                                      ? 'Add Items'
                                      : 'Items (${_items.length})'),
                            ),
                          ),
                        ],
                      ),
                      if (_attachments.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final p in _attachments)
                              InputChip(
                                label: Text(p
                                    .split(Platform.pathSeparator)
                                    .last
                                    .split('_')
                                    .skip(1)
                                    .join('_')),
                                onDeleted: () =>
                                    setState(() => _attachments.remove(p)),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          )),
          SafeArea(
            child: CashPageBody(
              maxWidth: 700,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: _isEdit
                    ? Row(children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error)),
                            onPressed: _delete,
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Delete'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _saving ? null : () => _save(exit: true),
                            icon: const Icon(Icons.check),
                            label: const Text('Save'),
                          ),
                        ),
                      ])
                    : Row(children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                _saving ? null : () => _save(exit: false),
                            child: const Text('Save and add another'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          // The filled button saves and goes back to the ledger.
                          child: ElevatedButton(
                            onPressed: _saving ? null : () => _save(exit: true),
                            child: const Text('Save'),
                          ),
                        ),
                      ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlinedAction extends StatelessWidget {
  final IconData icon;
  final String label;
  const _OutlinedAction({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(width: 8),
          Icon(icon, size: 20, color: AppColors.primary),
        ],
      ),
    );
  }
}
