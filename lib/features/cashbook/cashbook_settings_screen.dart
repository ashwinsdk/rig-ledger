import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/cashbook_provider.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/cashbook_common.dart';

/// Account Ledger settings (PARITY-076): date and time formats, number style
/// and display options. Defaults match the reference app.
class CashbookSettingsScreen extends ConsumerWidget {
  const CashbookSettingsScreen({super.key});

  static const _numberStyles = {
    'Grouped (1,234)': (true, false),
    'Plain (1234)': (false, false),
    'Two decimals (1,234.00)': (true, true),
  };

  Future<T?> _choose<T>(
      BuildContext context, String title, Map<String, T> options, T current) {
    return showDialog<T>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(title),
        children: [
          for (final e in options.entries)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, e.value),
              child: Row(
                children: [
                  Expanded(child: Text(e.key)),
                  if (e.value == current)
                    const Icon(Icons.check, color: AppColors.primary, size: 18),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(cashSettingsProvider);
    final notifier = ref.read(cashSettingsProvider.notifier);
    final now = DateTime.now();
    final styleLabel = _numberStyles.entries
        .firstWhere((e) => e.value == (s.groupDigits, s.fixedDecimals),
            orElse: () => _numberStyles.entries.first)
        .key;

    SwitchListTile sw(String title, bool value, ValueChanged<bool> onChanged,
            {String? subtitle}) =>
        SwitchListTile(
            title: Text(title),
            subtitle: subtitle == null ? null : Text(subtitle),
            value: value,
            onChanged: onChanged);

    return Scaffold(
      appBar: cashAppBar('Settings'),
      body: CashPageBody(
        maxWidth: 700,
        child: ListView(
          children: [
            ListTile(
              title: const Text('Format Date'),
              subtitle: Text(s.formatDate(now)),
              onTap: () async {
                final v = await _choose<String>(
                  context,
                  'Format Date',
                  {
                    for (final f in CashSettings.dateFormats)
                      s.copyWith(dateFormat: f).formatDate(now): f,
                  },
                  s.dateFormat,
                );
                if (v != null) {
                  await notifier.updateSettings(s.copyWith(dateFormat: v));
                }
              },
            ),
            sw('Show Time', s.showTime,
                (v) => notifier.updateSettings(s.copyWith(showTime: v))),
            ListTile(
              title: const Text('Time Format'),
              subtitle: Text(s.use24Hour ? '24 hour' : '12 hour'),
              onTap: () async {
                final v = await _choose<bool>(context, 'Time Format',
                    {'12 hour': false, '24 hour': true}, s.use24Hour);
                if (v != null) {
                  await notifier.updateSettings(s.copyWith(use24Hour: v));
                }
              },
            ),
            ListTile(
              title: const Text('Currency Format'),
              subtitle: Text(styleLabel),
              onTap: () async {
                final v = await _choose<(bool, bool)>(
                    context,
                    'Currency Format',
                    _numberStyles,
                    (s.groupDigits, s.fixedDecimals));
                if (v != null) {
                  await notifier.updateSettings(
                      s.copyWith(groupDigits: v.$1, fixedDecimals: v.$2));
                }
              },
            ),
            const Divider(),
            sw('Show date in each entry', s.showDateInEntry,
                (v) => notifier.updateSettings(s.copyWith(showDateInEntry: v))),
            sw(
                'Previous Balance',
                s.showPreviousBalance,
                (v) =>
                    notifier.updateSettings(s.copyWith(showPreviousBalance: v)),
                subtitle:
                    'Carry the balance before the period into period tabs'),
            sw(
                'Show balance after each transaction',
                s.showBalancePerEntry,
                (v) => notifier
                    .updateSettings(s.copyWith(showBalancePerEntry: v))),
            sw('Add description / Category', s.showDescription,
                (v) => notifier.updateSettings(s.copyWith(showDescription: v))),
            sw('Notes suggestion', s.notesSuggestion,
                (v) => notifier.updateSettings(s.copyWith(notesSuggestion: v))),
            sw(
                'Show time in reports',
                s.showTimeInReports,
                (v) =>
                    notifier.updateSettings(s.copyWith(showTimeInReports: v))),
            const Divider(),
            ListTile(
              title: const Text('Your Name and Address'),
              subtitle: Text(s.reporterName.isEmpty
                  ? 'Printed at the top of reports'
                  : s.reporterName),
              onTap: () async {
                final text =
                    await showReporterNameDialog(context, s.reporterName);
                if (text != null) {
                  await notifier.updateSettings(s.copyWith(reporterName: text));
                }
              },
            ),
            const ListTile(
              title: Text('Labels'),
              subtitle: Text('Income / Expense'),
              enabled: false,
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog to edit the name and address printed on reports. Returns the new
/// text or null when cancelled.
Future<String?> showReporterNameDialog(BuildContext context, String current) {
  return showCashTextPrompt(
    context,
    title: 'Your Name and Address',
    label: 'Name and address',
    initial: current,
    maxLines: 4,
    capitalization: TextCapitalization.sentences,
  );
}
