import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/cashbook_calculator.dart';
import '../../../core/utils/platform_helper.dart';

/// Colors with a functional meaning in the Account Ledger.
class CashColors {
  CashColors._();
  static const Color income = Color(0xFF059669);
  static const Color expense = Color(0xFFDC2626);
  static const Color balance = AppColors.primary;
}

/// Gradient app bar for pushed Account Ledger screens (slim on desktop).
PreferredSizeWidget cashAppBar(
  String title, {
  List<Widget> actions = const [],
  PreferredSizeWidget? bottom,
}) {
  final desktop = PlatformHelper.isDesktop;
  return AppBar(
    title: Text(title,
        style: TextStyle(
          color: desktop ? AppColors.textPrimary : Colors.white,
          fontSize: desktop ? 18 : 20,
          fontWeight: FontWeight.w600,
        )),
    centerTitle: !desktop,
    iconTheme:
        IconThemeData(color: desktop ? AppColors.textPrimary : Colors.white),
    actionsIconTheme:
        IconThemeData(color: desktop ? AppColors.textPrimary : Colors.white),
    backgroundColor: desktop ? AppColors.surface : null,
    flexibleSpace: desktop
        ? null
        : Container(
            decoration: const BoxDecoration(gradient: AppColors.appBarGradient),
          ),
    shape: desktop
        ? const Border(bottom: BorderSide(color: AppColors.border))
        : null,
    actions: actions,
    bottom: bottom,
  );
}

/// Wraps page content so it does not stretch across wide desktop windows.
class CashPageBody extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const CashPageBody({super.key, required this.child, this.maxWidth = 900});

  @override
  Widget build(BuildContext context) {
    if (!PlatformHelper.isDesktop) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Digits and a single dot only (amounts are never negative).
class AmountInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final buf = StringBuffer();
    var dot = false;
    for (final c in newValue.text.split('')) {
      if (c == '.' && !dot) {
        dot = true;
        buf.write(c);
      } else if (RegExp(r'[0-9]').hasMatch(c)) {
        buf.write(c);
      }
    }
    final text = buf.toString();
    if (text == newValue.text) return newValue;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(
          offset: newValue.selection.end.clamp(0, text.length)),
    );
  }
}

/// Parses user typed amounts ("1,234.5"). Null when empty or invalid.
double? parseAmount(String text) {
  final t = text.replaceAll(',', '').trim();
  if (t.isEmpty) return null;
  return double.tryParse(t);
}

void showCashSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    backgroundColor: error ? AppColors.error : null,
  ));
}

/// Simple confirm dialog. Returns true when the user confirms.
Future<bool> confirmCashDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel,
              style: const TextStyle(color: AppColors.error)),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// "+" / "-" sign selector used by the opening balance dialogs.
class CashSignToggle extends StatelessWidget {
  final bool positive;
  final ValueChanged<bool> onChanged;
  const CashSignToggle(
      {super.key, required this.positive, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment(value: true, label: Text('+ Income')),
        ButtonSegment(value: false, label: Text('- Expense')),
      ],
      selected: {positive},
      onSelectionChanged: (s) => onChanged(s.first),
      showSelectedIcon: false,
    );
  }
}

/// Tappable date field that opens the platform date picker.
class CashDateField extends StatelessWidget {
  final DateTime value;
  final String Function(DateTime) format;
  final ValueChanged<DateTime> onChanged;
  const CashDateField(
      {super.key,
      required this.value,
      required this.format,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          onChanged(DateTime(picked.year, picked.month, picked.day, value.hour,
              value.minute, value.second));
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          suffixIcon: Icon(Icons.calendar_today, size: 20),
        ),
        child: Text(format(value)),
      ),
    );
  }
}

/// "Select Date Range" dialog: start and end date, returns a half-open range
/// covering both days, or null when cancelled.
Future<CashDateRange?> pickCashDateRange(
  BuildContext context,
  String Function(DateTime) format,
) async {
  var start = DateTime.now();
  var end = DateTime.now();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => AlertDialog(
        title: const Text('Select Date Range'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Align(
                alignment: Alignment.centerLeft, child: Text('Start Date')),
            const SizedBox(height: 4),
            CashDateField(
                value: start,
                format: format,
                onChanged: (d) => setLocal(() => start = d)),
            const SizedBox(height: 12),
            const Align(
                alignment: Alignment.centerLeft, child: Text('End Date')),
            const SizedBox(height: 4),
            CashDateField(
                value: end,
                format: format,
                onChanged: (d) => setLocal(() => end = d)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('OK')),
        ],
      ),
    ),
  );
  if (ok != true) return null;
  var a = CashbookCalculator.dateOnly(start);
  var b = CashbookCalculator.dateOnly(end);
  if (b.isBefore(a)) {
    final t = a;
    a = b;
    b = t;
  }
  return CashDateRange(a, DateTime(b.year, b.month, b.day + 1));
}

/// Single text field prompt. The controller lives in the dialog's State, so it
/// is disposed only after the dialog has fully left the tree (disposing it
/// right after `await showDialog` crashes during the exit transition).
/// Returns the trimmed text, or null when cancelled.
Future<String?> showCashTextPrompt(
  BuildContext context, {
  required String title,
  required String label,
  String initial = '',
  String? helper,
  String confirmLabel = 'Save',
  int maxLines = 1,
  TextCapitalization capitalization = TextCapitalization.words,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _TextPromptDialog(
      title: title,
      label: label,
      initial: initial,
      helper: helper,
      confirmLabel: confirmLabel,
      maxLines: maxLines,
      capitalization: capitalization,
    ),
  );
}

class _TextPromptDialog extends StatefulWidget {
  final String title;
  final String label;
  final String initial;
  final String? helper;
  final String confirmLabel;
  final int maxLines;
  final TextCapitalization capitalization;

  const _TextPromptDialog({
    required this.title,
    required this.label,
    required this.initial,
    required this.helper,
    required this.confirmLabel,
    required this.maxLines,
    required this.capitalization,
  });

  @override
  State<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<_TextPromptDialog> {
  late final TextEditingController _c =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _c,
        autofocus: true,
        maxLines: widget.maxLines,
        textCapitalization: widget.capitalization,
        decoration:
            InputDecoration(labelText: widget.label, helperText: widget.helper),
        onSubmitted: (_) => Navigator.pop(context, _c.text.trim()),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
            onPressed: () => Navigator.pop(context, _c.text.trim()),
            child: Text(widget.confirmLabel)),
      ],
    );
  }
}
