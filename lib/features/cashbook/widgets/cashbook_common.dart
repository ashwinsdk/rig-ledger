import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
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
