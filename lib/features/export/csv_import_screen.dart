import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/ledger_entry.dart';
import '../../core/providers/ledger_provider.dart';
import '../../core/providers/agent_provider.dart';

class CsvImportScreen extends ConsumerStatefulWidget {
  const CsvImportScreen({super.key});

  @override
  ConsumerState<CsvImportScreen> createState() => _CsvImportScreenState();
}

class _CsvImportScreenState extends ConsumerState<CsvImportScreen> {
  List<List<dynamic>>? _csvData;
  List<String>? _headers;
  Map<String, int> _columnMapping = {};
  List<Map<String, String>> _errors = [];
  List<LedgerEntry> _validEntries = [];
  bool _createMissingAgents = true;
  bool _isImporting = false;
  int _currentStep = 0;

  final _uuid = const Uuid();

  // Expected headers
  static const expectedHeaders = [
    'Date',
    'Bill number',
    'Agent name',
    'Address',
    'Depth',
    'Depth in feet',
    'Depth per feet rate',
    'PVC',
    'PVC rate',
    'MS pipe',
    'MS pipe rate',
    'Extra-chargers',
    'TOTAL',
    'Received',
    'Balance',
    'Less',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Import from CSV'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: _onStepContinue,
        onStepCancel: _onStepCancel,
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                if (_currentStep > 0)
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Back'),
                  ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: details.onStepContinue,
                  child: Text(_getStepButtonText()),
                ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Select File'),
            subtitle: _csvData != null
                ? Text('${_csvData!.length - 1} rows found')
                : null,
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            content: _buildFileSelectionStep(),
          ),
          Step(
            title: const Text('Map Columns'),
            subtitle: _columnMapping.isNotEmpty
                ? Text('${_columnMapping.length} columns mapped')
                : null,
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            content: _buildColumnMappingStep(),
          ),
          Step(
            title: const Text('Preview & Import'),
            subtitle: _validEntries.isNotEmpty
                ? Text('${_validEntries.length} valid entries')
                : null,
            isActive: _currentStep >= 2,
            state: StepState.indexed,
            content: _buildPreviewStep(),
          ),
        ],
      ),
    );
  }

  String _getStepButtonText() {
    switch (_currentStep) {
      case 0:
        return _csvData != null ? 'Continue' : 'Select File';
      case 1:
        return 'Validate';
      case 2:
        return _isImporting ? 'Importing...' : 'Import';
      default:
        return 'Continue';
    }
  }

  void _onStepContinue() {
    switch (_currentStep) {
      case 0:
        if (_csvData == null) {
          _pickFile();
        } else {
          _autoMapColumns();
          setState(() {
            _currentStep = 1;
          });
        }
        break;
      case 1:
        _validateAndParse();
        setState(() {
          _currentStep = 2;
        });
        break;
      case 2:
        _importEntries();
        break;
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Widget _buildFileSelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Icon(
                _csvData != null
                    ? Icons.check_circle
                    : Icons.file_upload_outlined,
                size: 48,
                color: _csvData != null ? AppColors.success : AppColors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                _csvData != null
                    ? 'File loaded successfully'
                    : 'Select a CSV file to import',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (_csvData != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${_csvData!.length - 1} rows found (excluding header)',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.folder_open),
                label: Text(_csvData != null
                    ? 'Choose Different File'
                    : 'Browse Files'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Expected format:',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        const Text(
          '• UTF-8 encoded CSV file\n'
          '• First row should contain headers\n'
          '• Comma-separated values',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildColumnMappingStep() {
    if (_headers == null) {
      return const Center(child: Text('Please select a file first'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Map CSV columns to fields:',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        ...expectedHeaders.map((expected) {
          final mappedIndex = _columnMapping[expected];
          final isRequired =
              ['Date', 'Bill number', 'Agent name'].contains(expected);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    expected + (isRequired ? ' *' : ''),
                    style: TextStyle(
                      color: isRequired
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight:
                          isRequired ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward,
                    size: 16, color: AppColors.textHint),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<int>(
                    value: mappedIndex,
                    isExpanded: true,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('-- Skip --',
                            style: TextStyle(color: AppColors.textHint)),
                      ),
                      ...List.generate(_headers!.length, (index) {
                        return DropdownMenuItem<int>(
                          value: index,
                          child: Text(
                            _headers![index],
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        if (value == null) {
                          _columnMapping.remove(expected);
                        } else {
                          _columnMapping[expected] = value;
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
        SwitchListTile(
          value: _createMissingAgents,
          onChanged: (value) {
            setState(() {
              _createMissingAgents = value;
            });
          },
          title: const Text('Auto-create missing agents'),
          subtitle: const Text('Create agents if they don\'t exist'),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildPreviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary
        Row(
          children: [
            _SummaryChip(
              icon: Icons.check_circle,
              label: '${_validEntries.length} Valid',
              color: AppColors.success,
            ),
            const SizedBox(width: 8),
            _SummaryChip(
              icon: Icons.error,
              label: '${_errors.length} Errors',
              color: _errors.isNotEmpty ? AppColors.error : AppColors.textHint,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Errors
        if (_errors.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber, color: AppColors.error, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Errors found:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._errors.take(5).map((error) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'Row ${error['row']}: ${error['message']}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.error,
                        ),
                      ),
                    )),
                if (_errors.length > 5)
                  Text(
                    '... and ${_errors.length - 5} more errors',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.error,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Preview of valid entries
        if (_validEntries.isNotEmpty) ...[
          const Text(
            'Preview (first 5 entries):',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: _validEntries.take(5).map((entry) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '#${entry.billNumber} - ${entry.agentName}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '${entry.date.toString().split(' ')[0]} | ${entry.address}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        entry.total.toStringAsFixed(2),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.first.path!);
      final content = await file.readAsString();

      final csvData = const CsvToListConverter().convert(content);

      if (csvData.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('CSV file is empty'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      setState(() {
        _csvData = csvData;
        _headers = csvData.first.map((e) => e.toString()).toList();
        _columnMapping = {};
        _errors = [];
        _validEntries = [];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to read file: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _autoMapColumns() {
    if (_headers == null) return;

    final mapping = <String, int>{};

    for (int i = 0; i < _headers!.length; i++) {
      final header = _headers![i].toLowerCase().trim();

      for (final expected in expectedHeaders) {
        final expectedLower = expected.toLowerCase();
        if (header == expectedLower || header.contains(expectedLower)) {
          mapping[expected] = i;
          break;
        }
      }
    }

    setState(() {
      _columnMapping = mapping;
    });
  }

  void _validateAndParse() {
    if (_csvData == null || _csvData!.length < 2) return;

    final errors = <Map<String, String>>[];
    final validEntries = <LedgerEntry>[];
    final agents = ref.read(agentsProvider);

    for (int rowIndex = 1; rowIndex < _csvData!.length; rowIndex++) {
      final row = _csvData![rowIndex];
      final rowNum = rowIndex + 1;

      try {
        // Get values from mapped columns
        String getValue(String field) {
          final index = _columnMapping[field];
          if (index == null || index >= row.length) return '';
          return row[index].toString().trim();
        }

        final dateStr = getValue('Date');
        final billNumber = getValue('Bill number');
        final agentName = getValue('Agent name');
        final address = getValue('Address');

        // Validate required fields
        if (billNumber.isEmpty) {
          errors.add(
              {'row': rowNum.toString(), 'message': 'Bill number is required'});
          continue;
        }
        if (agentName.isEmpty) {
          errors.add(
              {'row': rowNum.toString(), 'message': 'Agent name is required'});
          continue;
        }

        // Parse date
        DateTime date;
        try {
          if (dateStr.isNotEmpty) {
            date = DateTime.parse(dateStr);
          } else {
            date = DateTime.now();
          }
        } catch (e) {
          errors.add(
              {'row': rowNum.toString(), 'message': 'Invalid date format'});
          continue;
        }

        // Find or create agent
        var agent = agents
            .where((a) => a.name.toLowerCase() == agentName.toLowerCase())
            .firstOrNull;
        String agentId;
        if (agent != null) {
          agentId = agent.id;
        } else if (_createMissingAgents) {
          agentId = _uuid.v4(); // Will be created during import
        } else {
          errors.add({
            'row': rowNum.toString(),
            'message': 'Agent "$agentName" not found'
          });
          continue;
        }

        // Parse numeric values
        double parseNum(String field) {
          final value = getValue(field);
          return double.tryParse(value) ?? 0;
        }

        final entry = LedgerEntry(
          id: _uuid.v4(),
          date: date,
          billNumber: billNumber,
          agentId: agentId,
          agentName: agentName,
          address: address,
          depth: getValue('Depth').isNotEmpty ? getValue('Depth') : '7inch',
          depthInFeet: parseNum('Depth in feet'),
          depthPerFeetRate: parseNum('Depth per feet rate'),
          pvc: getValue('PVC').isNotEmpty ? getValue('PVC') : '7inch',
          pvcRate: parseNum('PVC rate'),
          msPipe: getValue('MS pipe'),
          msPipeRate: parseNum('MS pipe rate'),
          extraCharges: parseNum('Extra-chargers'),
          total: parseNum('TOTAL'),
          isTotalManuallyEdited: false,
          received: parseNum('Received'),
          balance: parseNum('Balance'),
          less: parseNum('Less'),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        validEntries.add(entry);
      } catch (e) {
        errors.add({'row': rowNum.toString(), 'message': e.toString()});
      }
    }

    setState(() {
      _errors = errors;
      _validEntries = validEntries;
    });
  }

  Future<void> _importEntries() async {
    if (_validEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No valid entries to import'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _isImporting = true;
    });

    try {
      // Create missing agents first
      if (_createMissingAgents) {
        final existingAgents = ref.read(agentsProvider);
        final existingNames =
            existingAgents.map((a) => a.name.toLowerCase()).toSet();
        final newAgentNames = _validEntries
            .map((e) => e.agentName)
            .toSet()
            .where((name) => !existingNames.contains(name.toLowerCase()));

        for (final name in newAgentNames) {
          await ref.read(agentsProvider.notifier).addAgent(name);
        }

        // Refresh agents and update entry agent IDs
        ref.read(agentsProvider.notifier).refresh();
        final updatedAgents = ref.read(agentsProvider);

        for (int i = 0; i < _validEntries.length; i++) {
          final entry = _validEntries[i];
          final agent = updatedAgents.firstWhere(
            (a) => a.name.toLowerCase() == entry.agentName.toLowerCase(),
          );
          _validEntries[i] = entry.copyWith(agentId: agent.id);
        }
      }

      // Import entries
      await ref
          .read(ledgerEntriesProvider.notifier)
          .importEntries(_validEntries);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Successfully imported ${_validEntries.length} entries'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
