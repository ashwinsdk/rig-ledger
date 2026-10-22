import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/step_rates.dart';
import '../../core/models/vehicle.dart';
import '../../core/providers/step_rates_provider.dart';
import '../../core/providers/vehicle_provider.dart';
import '../../core/theme/app_colors.dart';

/// Settings > Step Rates (v2.0.4): the 7 inch and 8 inch step rate tables of
/// each main bore rig. Saved bills keep the step rate they were saved with;
/// the tables apply to new bills (and to saved bills whose depth is edited).
class StepRatesScreen extends ConsumerStatefulWidget {
  const StepRatesScreen({super.key});

  @override
  ConsumerState<StepRatesScreen> createState() => _StepRatesScreenState();
}

class _StepRatesScreenState extends ConsumerState<StepRatesScreen> {
  String? _rigId;
  int _generation = 0; // bumps to rebuild the editors (rig change, reset)
  final _key7 = GlobalKey<_TableEditorState>();
  final _key8 = GlobalKey<_TableEditorState>();

  List<Vehicle> _mainBoreRigs() => ref
      .read(vehiclesProvider)
      .where((v) => v.vehicleType == VehicleType.mainBore)
      .toList();

  Future<void> _save(String rigId) async {
    final t7 = _key7.currentState?.value();
    final t8 = _key8.currentState?.value();
    if (t7 == null || t8 == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Fill every rate with a number'),
        backgroundColor: AppColors.error,
      ));
      return;
    }
    await ref.read(stepRatesProvider.notifier).saveRig(rigId, t7, t8);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Step rates saved. New bills use them'),
      backgroundColor: AppColors.success,
    ));
  }

  Future<void> _reset(String rigId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset step rates'),
        content: const Text(
            'Go back to the standard 7 inch and 8 inch tables for this rig? '
            'Saved bills keep their step rate.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Reset')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(stepRatesProvider.notifier).resetRig(rigId);
    if (mounted) setState(() => _generation++);
  }

  @override
  Widget build(BuildContext context) {
    final rigs = _mainBoreRigs();
    final current = ref.watch(currentVehicleProvider);
    _rigId ??= rigs.any((r) => r.id == current?.id)
        ? current!.id
        : (rigs.isEmpty ? null : rigs.first.id);
    final rates = ref.watch(stepRatesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Step Rates'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _rigId == null
          ? const Center(child: Text('No main bore rig yet'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<String>(
                  value: _rigId,
                  decoration: const InputDecoration(
                    labelText: 'Rig',
                    prefixIcon: Icon(Icons.precision_manufacturing_outlined),
                  ),
                  items: [
                    for (final r in rigs)
                      DropdownMenuItem(value: r.id, child: Text(r.name)),
                  ],
                  onChanged: (v) => setState(() {
                    _rigId = v;
                    _generation++;
                  }),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'The step rate is extra money charged on depth beyond the '
                    'point where it starts. Each 100 ft bracket has its own '
                    'extra rate per foot. Changes apply to new bills only: '
                    'saved bills keep the step rate they were saved with. A '
                    'saved bill uses the new tables only if you edit its depth.',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 16),
                _TableEditor(
                  key: _key7,
                  title: '7 inch table',
                  initial: rates.forRig(_rigId!).table7,
                  generation: _generation,
                ),
                const SizedBox(height: 16),
                _TableEditor(
                  key: _key8,
                  title: '8 inch table',
                  initial: rates.forRig(_rigId!).table8,
                  generation: _generation,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _reset(_rigId!),
                        child: const Text('Reset to standard'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _save(_rigId!),
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }
}

/// One table: where the step starts, the extra per foot of each 100 ft
/// bracket (add and remove rows), the extra for each further 100 ft, and a
/// live example.
class _TableEditor extends StatefulWidget {
  final String title;
  final StepTable initial;
  final int generation;
  const _TableEditor({
    super.key,
    required this.title,
    required this.initial,
    required this.generation,
  });

  @override
  State<_TableEditor> createState() => _TableEditorState();
}

class _TableEditorState extends State<_TableEditor> {
  late TextEditingController _threshold;
  late TextEditingController _beyond;
  late List<TextEditingController> _extras;
  int _seenGeneration = 0;

  static String _t(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  @override
  void initState() {
    super.initState();
    _load();
    _seenGeneration = widget.generation;
  }

  void _load() {
    final t = widget.initial;
    _threshold = TextEditingController(text: _t(t.threshold));
    _beyond = TextEditingController(text: _t(t.beyondIncrement));
    _extras = [for (final e in t.extras) TextEditingController(text: _t(e))];
  }

  void _disposeAll() {
    _threshold.dispose();
    _beyond.dispose();
    for (final c in _extras) {
      c.dispose();
    }
  }

  @override
  void didUpdateWidget(covariant _TableEditor old) {
    super.didUpdateWidget(old);
    if (widget.generation != _seenGeneration) {
      _seenGeneration = widget.generation;
      _disposeAll();
      _load();
    }
  }

  @override
  void dispose() {
    _disposeAll();
    super.dispose();
  }

  /// The table as typed, or null when a field is empty or not a number.
  StepTable? value() {
    final th = double.tryParse(_threshold.text);
    final be = double.tryParse(_beyond.text);
    final ex = [for (final c in _extras) double.tryParse(c.text)];
    if (th == null || be == null || ex.any((e) => e == null) || ex.isEmpty) {
      return null;
    }
    return StepTable(
        threshold: th, extras: [for (final e in ex) e!], beyondIncrement: be);
  }

  Widget _num(TextEditingController c, String label, {String? suffix}) =>
      TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
        ],
        decoration: InputDecoration(
            labelText: label,
            prefixText: suffix == null ? '₹ ' : null,
            suffixText: suffix),
        onChanged: (_) => setState(() {}),
      );

  @override
  Widget build(BuildContext context) {
    final th = double.tryParse(_threshold.text) ?? 0;
    final table = value();
    final money = NumberFormat('#,##0.##');
    final exampleFeet = th + 100.0 * (_extras.length + 1);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _num(_threshold, 'Step rate starts after', suffix: 'ft'),
          const SizedBox(height: 12),
          for (var i = 0; i < _extras.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: _num(_extras[i],
                        '${money.format(th + 100.0 * i)} to ${money.format(th + 100.0 * (i + 1))} ft, extra per ft'),
                  ),
                  IconButton(
                    onPressed: _extras.length <= 1
                        ? null
                        : () => setState(() => _extras.removeAt(i).dispose()),
                    icon: const Icon(Icons.close, size: 20),
                    tooltip: 'Remove bracket',
                  ),
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _extras.add(TextEditingController(
                  text: _t(_extras.isEmpty
                      ? 10
                      : (double.tryParse(_extras.last.text) ?? 0) +
                          (double.tryParse(_beyond.text) ?? 0))))),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add bracket'),
            ),
          ),
          const SizedBox(height: 4),
          _num(_beyond, 'After the last bracket, extra per ft grows by',
              suffix: 'per 100 ft'),
          const SizedBox(height: 12),
          Text(
            table == null
                ? 'Fill every rate to see an example'
                : 'Example: ${money.format(exampleFeet)} ft gives a step rate of ₹${money.format(table.calculate(exampleFeet))}',
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
