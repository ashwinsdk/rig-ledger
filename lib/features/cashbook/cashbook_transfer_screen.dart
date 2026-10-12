import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/cashbook_provider.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/cashbook_common.dart';

/// Transfer between two books (PARITY-057..060). Creates an expense in the
/// source book and an income in the destination, linked by transferGroupId.
class CashbookTransferScreen extends ConsumerStatefulWidget {
  const CashbookTransferScreen({super.key});

  @override
  ConsumerState<CashbookTransferScreen> createState() =>
      _CashbookTransferScreenState();
}

class _CashbookTransferScreenState
    extends ConsumerState<CashbookTransferScreen> {
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  String? _from;
  String? _to;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    final books = ref.read(cashBooksProvider);
    _from = ref.read(currentCashBookProvider)?.id ??
        (books.isEmpty ? null : books.first.id);
    final others = books.where((b) => b.id != _from);
    _to = others.isEmpty ? null : others.first.id;
  }

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(_date));
    if (t != null) {
      setState(() => _date =
          DateTime(_date.year, _date.month, _date.day, t.hour, t.minute));
    }
  }

  Future<void> _transfer() async {
    final amount = parseAmount(_amount.text);
    // Empty amount does nothing (PARITY-060).
    if (amount == null || _from == null || _to == null) return;
    final (ok, error) = await ref.read(cashEntriesProvider.notifier).transfer(
          fromBookId: _from!,
          toBookId: _to!,
          amount: amount,
          date: _date,
          notes: _notes.text.trim(),
        );
    if (!mounted) return;
    if (!ok) {
      showCashSnack(context, error ?? 'Transfer failed', error: true);
      return;
    }
    // The form stays open and is cleared (PARITY-059).
    setState(() {
      _amount.clear();
      _notes.clear();
      _date = DateTime.now();
    });
    showCashSnack(context, 'Transferred');
  }

  @override
  Widget build(BuildContext context) {
    final books = ref.watch(cashBooksProvider);
    final settings = ref.watch(cashSettingsProvider);
    DropdownButtonFormField<String> picker(
        String label, String? value, ValueChanged<String?> onChanged) {
      return DropdownButtonFormField<String>(
        initialValue: books.any((b) => b.id == value) ? value : null,
        decoration: InputDecoration(labelText: label),
        items: [
          for (final b in books)
            DropdownMenuItem(value: b.id, child: Text(b.name)),
        ],
        onChanged: onChanged,
      );
    }

    return Scaffold(
      appBar: cashAppBar('Transfer'),
      body: CashPageBody(
        maxWidth: 600,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _amount,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [AmountInputFormatter()],
                    decoration: const InputDecoration(
                        labelText: 'Amount', prefixText: 'Rs. '),
                  ),
                  const SizedBox(height: 16),
                  picker('From', _from, (v) => setState(() => _from = v)),
                  const SizedBox(height: 16),
                  picker('To', _to, (v) => setState(() => _to = v)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: CashDateField(
                            value: _date,
                            format: settings.formatDate,
                            onChanged: (d) => setState(() => _date = d)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _pickTime,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                                suffixIcon: Icon(Icons.access_time, size: 20)),
                            child: Text(settings.formatTime(_date)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _notes,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Notes'),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary),
                      onPressed: _transfer,
                      child: const Text('Transfer'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
