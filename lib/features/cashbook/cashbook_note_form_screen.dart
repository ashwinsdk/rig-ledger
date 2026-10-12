import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/cash_note.dart';
import '../../core/providers/cashbook_provider.dart';
import 'widgets/cashbook_common.dart';

/// Add / edit a Notebook note (PARITY-066). Edit mode adds Delete with a
/// confirmation.
class CashbookNoteFormScreen extends ConsumerStatefulWidget {
  final CashNote? note;
  const CashbookNoteFormScreen({super.key, this.note});

  @override
  ConsumerState<CashbookNoteFormScreen> createState() =>
      _CashbookNoteFormScreenState();
}

class _CashbookNoteFormScreenState
    extends ConsumerState<CashbookNoteFormScreen> {
  late DateTime _date = widget.note?.date ?? DateTime.now();
  late final _text = TextEditingController(text: widget.note?.text ?? '');

  bool get _isEdit => widget.note != null;

  @override
  void dispose() {
    _text.dispose();
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

  Future<void> _save() async {
    final notifier = ref.read(cashNotesProvider.notifier);
    if (_isEdit) {
      if (_text.text.trim().isEmpty) {
        showCashSnack(context, 'Enter a note', error: true);
        return;
      }
      await notifier.updateNote(
          widget.note!.copyWith(date: _date, text: _text.text.trim()));
    } else {
      final (_, error) = await notifier.addNote(date: _date, text: _text.text);
      if (error != null) {
        if (mounted) showCashSnack(context, error, error: true);
        return;
      }
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await confirmCashDialog(context,
        title: 'Delete', message: 'Delete this note?');
    if (!ok) return;
    await ref.read(cashNotesProvider.notifier).deleteNote(widget.note!.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(cashSettingsProvider);
    return Scaffold(
      appBar: cashAppBar(_isEdit ? 'Edit' : 'Notes'),
      body: CashPageBody(
        maxWidth: 600,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
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
                                  suffixIcon:
                                      Icon(Icons.access_time, size: 20)),
                              child: Text(settings.formatTime(_date)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _text,
                      autofocus: !_isEdit,
                      minLines: 4,
                      maxLines: 8,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(labelText: 'Notes'),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    if (_isEdit) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _delete,
                          style: OutlinedButton.styleFrom(
                              foregroundColor: CashColors.expense,
                              side:
                                  const BorderSide(color: CashColors.expense)),
                          child: const Text('Delete'),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: ElevatedButton(
                          onPressed: _save, child: const Text('Save')),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
