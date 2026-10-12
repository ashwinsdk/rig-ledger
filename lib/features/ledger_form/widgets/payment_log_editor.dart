import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/ledger_payment.dart';
import '../../../core/providers/cashbook_provider.dart';
import '../../../core/providers/ledger_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../cashbook/widgets/cashbook_common.dart';

final _money = NumberFormat('#,##0.00');
final _dateFmt = DateFormat('dd MMM yyyy');

/// Payment log of a bill (v2.0.0): every payment with its date, mode and the
/// receiver (a book of the Account Ledger). Replaces the single cash/PhonePe
/// inputs so earlier payments are never overwritten.
///
/// [baseCash] and [basePhonePe] are the amounts received without a log entry
/// (older bills); they stay editable through the "Earlier received" row.
class PaymentLogEditor extends ConsumerWidget {
  final List<LedgerPayment> payments;
  final double baseCash;
  final double basePhonePe;
  final bool allowPhonePe;
  final ValueChanged<List<LedgerPayment>> onChanged;
  final void Function(double cash, double phonePe) onBaseChanged;

  const PaymentLogEditor({
    super.key,
    required this.payments,
    required this.baseCash,
    required this.basePhonePe,
    required this.allowPhonePe,
    required this.onChanged,
    required this.onBaseChanged,
  });

  double get total =>
      baseCash +
      basePhonePe +
      LedgerPayment.totalCash(payments) +
      LedgerPayment.totalPhonePe(payments);

  String _receiverName(WidgetRef ref, String? id) {
    if (id == null) return 'No receiver';
    for (final b in ref.read(cashBooksProvider)) {
      if (b.id == id) return b.name;
    }
    return 'Deleted book';
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final p = await showPaymentDialog(context, allowPhonePe: allowPhonePe);
    if (p != null) onChanged([...payments, p]);
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, int i) async {
    final p = await showPaymentDialog(context,
        initial: payments[i], allowPhonePe: allowPhonePe);
    if (p != null) {
      final copy = [...payments];
      copy[i] = p;
      onChanged(copy);
    }
  }

  Future<void> _editBase(BuildContext context) async {
    final result = await showDialog<(double, double)>(
      context: context,
      builder: (_) => _BaseDialog(
          cash: baseCash, phonePe: basePhonePe, allowPhonePe: allowPhonePe),
    );
    if (result != null) {
      onBaseChanged(result.$1, allowPhonePe ? result.$2 : 0);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final base = baseCash + basePhonePe;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
            child: Row(
              children: [
                const Icon(Icons.payments_outlined,
                    color: AppColors.success, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Payments received',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
                TextButton.icon(
                  onPressed: () => _add(context, ref),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add payment'),
                ),
              ],
            ),
          ),
          if (base > 0)
            ListTile(
              dense: true,
              title: const Text('Earlier received'),
              subtitle: const Text('Before payments were logged, no receiver'),
              trailing: Text('₹${_money.format(base)}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              onTap: () => _editBase(context),
            ),
          if (payments.isEmpty && base == 0)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text('No payments yet',
                  style: TextStyle(color: AppColors.textHint, fontSize: 13)),
            ),
          for (var i = 0; i < payments.length; i++)
            ListTile(
              dense: true,
              onTap: () => _edit(context, ref, i),
              title: Text(
                  '₹${_money.format(payments[i].amount)}  ${payments[i].isCash ? 'Cash' : 'PhonePe'}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                [
                  _dateFmt.format(payments[i].date),
                  _receiverName(ref, payments[i].receiverBookId),
                  if ((payments[i].payerName ?? '').isNotEmpty)
                    'from ${payments[i].payerName}',
                  if ((payments[i].notes ?? '').isNotEmpty) payments[i].notes!,
                ].join('  |  '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                tooltip: 'Remove payment',
                icon: const Icon(Icons.delete_outline,
                    size: 20, color: AppColors.error),
                onPressed: () {
                  final copy = [...payments]..removeAt(i);
                  onChanged(copy);
                },
              ),
            ),
          if (base == 0 && payments.isNotEmpty) const SizedBox(height: 4),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Text('Total Received',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                const Spacer(),
                Text('₹${_money.format(total)}',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Earlier received" editor. Controllers live in the State (see
/// showCashTextPrompt for why).
class _BaseDialog extends StatefulWidget {
  final double cash;
  final double phonePe;
  final bool allowPhonePe;
  const _BaseDialog(
      {required this.cash, required this.phonePe, required this.allowPhonePe});

  @override
  State<_BaseDialog> createState() => _BaseDialogState();
}

class _BaseDialogState extends State<_BaseDialog> {
  late final _cash =
      TextEditingController(text: widget.cash == 0 ? '' : '${widget.cash}');
  late final _pe = TextEditingController(
      text: widget.phonePe == 0 ? '' : '${widget.phonePe}');

  @override
  void dispose() {
    _cash.dispose();
    _pe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Earlier received'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Amount received before payments were logged. It has no receiver.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          _amountField(_cash, 'Cash (₹)'),
          if (widget.allowPhonePe) ...[
            const SizedBox(height: 12),
            _amountField(_pe, 'PhonePe (₹)'),
          ],
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
            onPressed: () => Navigator.pop(context, (
                  double.tryParse(_cash.text) ?? 0,
                  double.tryParse(_pe.text) ?? 0
                )),
            child: const Text('Save')),
      ],
    );
  }
}

Widget _amountField(TextEditingController c, String label) => TextField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
      ],
      decoration: InputDecoration(labelText: label),
    );

/// Add / edit one payment. Returns the payment or null when cancelled.
Future<LedgerPayment?> showPaymentDialog(
  BuildContext context, {
  LedgerPayment? initial,
  required bool allowPhonePe,
}) {
  return showDialog<LedgerPayment>(
    context: context,
    builder: (_) =>
        _PaymentDialog(initial: initial, allowPhonePe: allowPhonePe),
  );
}

class _PaymentDialog extends ConsumerStatefulWidget {
  final LedgerPayment? initial;
  final bool allowPhonePe;
  const _PaymentDialog({this.initial, required this.allowPhonePe});

  @override
  ConsumerState<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends ConsumerState<_PaymentDialog> {
  late final _amount = TextEditingController(
      text: widget.initial == null ? '' : '${widget.initial!.amount}');
  late final _payer =
      TextEditingController(text: widget.initial?.payerName ?? '');
  late final _notes = TextEditingController(text: widget.initial?.notes ?? '');
  late String _mode = widget.initial?.mode ?? LedgerPayment.modeCash;
  late DateTime _date = widget.initial?.date ?? DateTime.now();
  String? _receiverId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _receiverId = widget.initial?.receiverBookId;
  }

  @override
  void dispose() {
    _amount.dispose();
    _payer.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _newReceiver() async {
    final name = await showCashTextPrompt(
      context,
      title: 'New receiver',
      label: 'Name',
      helper: 'Creates a book in Account Ledger',
      confirmLabel: 'Add',
    );
    if (name == null || name.isEmpty) return;
    final (book, error) =
        await ref.read(cashBooksProvider.notifier).addBook(name: name, kind: 1);
    if (!mounted) return;
    if (book != null) {
      setState(() => _receiverId = book.id);
    } else if (error != null) {
      setState(() => _error = error);
    }
  }

  void _save() {
    final amount = double.tryParse(_amount.text);
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter an amount');
      return;
    }
    final isPe = widget.allowPhonePe && _mode == LedgerPayment.modePhonePe;
    Navigator.pop(
      context,
      LedgerPayment(
        id: widget.initial?.id ?? const Uuid().v4(),
        date: _date,
        amount: (amount * 100).round() / 100,
        mode: isPe ? LedgerPayment.modePhonePe : LedgerPayment.modeCash,
        receiverBookId: _receiverId,
        payerName:
            isPe && _payer.text.trim().isNotEmpty ? _payer.text.trim() : null,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final books = [...ref.watch(cashBooksProvider)]..sort((a, b) {
        if (a.isReceiver != b.isReceiver) return a.isReceiver ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    final payerNames = ref.watch(phonePeNamesProvider);
    final validReceiver = books.any((b) => b.id == _receiverId);

    return AlertDialog(
      title: Text(widget.initial == null ? 'Add payment' : 'Edit payment'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _amount,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
              ],
              decoration:
                  InputDecoration(labelText: 'Amount (₹)', errorText: _error),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            if (widget.allowPhonePe) ...[
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                      value: LedgerPayment.modeCash, label: Text('Cash')),
                  ButtonSegment(
                      value: LedgerPayment.modePhonePe, label: Text('PhonePe')),
                ],
                selected: {_mode},
                onSelectionChanged: (s) => setState(() => _mode = s.first),
                showSelectedIcon: false,
              ),
            ],
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (d != null) {
                  setState(() => _date = DateTime(
                      d.year, d.month, d.day, _date.hour, _date.minute));
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                    labelText: 'Date',
                    suffixIcon: Icon(Icons.calendar_today, size: 20)),
                child: Text(_dateFmt.format(_date)),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              // A new key makes the field pick up programmatic changes (a
              // receiver created from this dialog).
              key: ValueKey(_receiverId),
              initialValue: validReceiver ? _receiverId : '',
              decoration: const InputDecoration(
                  labelText: 'Received by',
                  helperText: 'Adds the amount to this book in Account Ledger'),
              items: [
                const DropdownMenuItem(value: '', child: Text('No receiver')),
                for (final b in books)
                  DropdownMenuItem(
                      value: b.id,
                      child: Text(b.isReceiver ? b.name : '${b.name} (book)')),
                const DropdownMenuItem(
                  value: '__new__',
                  child: Row(children: [
                    Icon(Icons.add, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('New receiver',
                        style: TextStyle(color: AppColors.primary)),
                  ]),
                ),
              ],
              onChanged: (v) {
                if (v == '__new__') {
                  _newReceiver();
                } else {
                  setState(
                      () => _receiverId = (v == null || v.isEmpty) ? null : v);
                }
              },
            ),
            if (widget.allowPhonePe && _mode == LedgerPayment.modePhonePe) ...[
              const SizedBox(height: 12),
              Autocomplete<String>(
                initialValue: TextEditingValue(text: _payer.text),
                optionsBuilder: (v) => payerNames.where((n) =>
                    n.toLowerCase().contains(v.text.trim().toLowerCase())),
                onSelected: (v) => _payer.text = v,
                fieldViewBuilder: (ctx, c, f, _) => TextField(
                  controller: c,
                  focusNode: f,
                  textCapitalization: TextCapitalization.words,
                  decoration:
                      const InputDecoration(labelText: 'PhonePe payer name'),
                  onChanged: (v) => _payer.text = v,
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
