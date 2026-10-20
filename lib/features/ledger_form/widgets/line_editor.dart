import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/ledger_line.dart';
import '../../../core/models/ledger_types.dart';
import '../../../core/theme/app_colors.dart';

/// Text controllers and type of one bill line while the form is open
/// (v2.0.2). The form owns these and disposes them.
class LineController {
  String type;
  final TextEditingController feet;
  final TextEditingController rate;
  final TextEditingController comm;

  LineController({
    required this.type,
    String feet = '',
    String rate = '',
    String comm = '',
  })  : feet = TextEditingController(text: feet),
        rate = TextEditingController(text: rate),
        comm = TextEditingController(text: comm);

  static String _t(double v) => v == 0 ? '' : v.toString();

  factory LineController.fromLine(LedgerLine l) => LineController(
        type: l.type,
        feet: _t(l.feet),
        rate: _t(l.rate),
        comm: _t(l.commissionRate),
      );

  double get feetValue => double.tryParse(feet.text) ?? 0;
  double get rateValue => double.tryParse(rate.text) ?? 0;
  double get commValue => double.tryParse(comm.text) ?? 0;

  LedgerLine toLine(String category) => LedgerLine(
        category: category,
        type: type,
        feet: feetValue,
        rate: rateValue,
        commissionRate: commValue,
      );

  /// A line the user left empty.
  bool get isEmpty => feetValue == 0 && rateValue == 0;

  void addListeners(VoidCallback calc, VoidCallback commChanged) {
    feet.addListener(calc);
    rate.addListener(calc);
    comm.addListener(commChanged);
  }

  void dispose() {
    feet.dispose();
    rate.dispose();
    comm.dispose();
  }
}

/// One category (depth, PVC or MS pipe) of the bill form: a card per line
/// with type, feet and rate, and an "add line" button.
class LinesSection extends StatelessWidget {
  final String category;
  final String title; // e.g. 'Depth'
  final LedgerTypes types;
  final List<LineController> lines;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final void Function(int index, String oldType, String newType) onTypeChanged;
  final VoidCallback onChanged;

  /// Side bore rigs have no depth types: only feet, rate and commission.
  final bool showType;

  const LinesSection({
    super.key,
    required this.category,
    required this.title,
    required this.types,
    required this.lines,
    required this.onAdd,
    required this.onRemove,
    required this.onTypeChanged,
    required this.onChanged,
    this.showType = true,
  });

  LedgerTypeCategory get _cat => switch (category) {
        LedgerLine.pvc => LedgerTypeCategory.pvc,
        LedgerLine.ms => LedgerTypeCategory.ms,
        _ => LedgerTypeCategory.depth,
      };

  static final _formatters = [
    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
  ];

  Widget _feetField(int i) => TextFormField(
        controller: lines[i].feet,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: _formatters,
        decoration: InputDecoration(
          labelText: showType ? '$title (feet)' : '$title (ft)',
          prefixIcon: showType ? null : const Icon(Icons.straighten),
        ),
      );

  Widget _rateField(int i, {bool short = false}) => TextFormField(
        controller: lines[i].rate,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: _formatters,
        decoration: InputDecoration(
          labelText: short ? 'Rate/ft (₹)' : '$title rate per feet (₹)',
          prefixIcon: const Icon(Icons.currency_rupee),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final multi = lines.length > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < lines.length; i++)
          Container(
            key: ValueKey('$category-line-$i'),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (multi)
                  Row(
                    children: [
                      Expanded(
                        child: Text('$title line ${i + 1}',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary)),
                      ),
                      IconButton(
                        onPressed: () => onRemove(i),
                        icon: const Icon(Icons.close, size: 18),
                        tooltip: 'Remove line',
                        visualDensity: VisualDensity.compact,
                        color: AppColors.error,
                      ),
                    ],
                  ),
                if (showType) ...[
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: lines[i].type,
                          isExpanded: true,
                          decoration: InputDecoration(labelText: '$title Type'),
                          items: types
                              .withCurrent(_cat, lines[i].type)
                              .map((t) =>
                                  DropdownMenuItem(value: t, child: Text(t)))
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            final old = lines[i].type;
                            lines[i].type = value;
                            onTypeChanged(i, old, value);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _feetField(i)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _rateField(i),
                ] else
                  Row(
                    children: [
                      Expanded(child: _feetField(i)),
                      const SizedBox(width: 12),
                      Expanded(child: _rateField(i, short: true)),
                    ],
                  ),
              ],
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: Text('Add $title line'),
          ),
        ),
      ],
    );
  }
}
