import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import '../../core/theme/app_colors.dart';
import '../../core/database/database_service.dart';
import '../../core/models/ledger_entry.dart';
import '../../core/models/diesel_entry.dart';
import '../../core/models/pvc_entry.dart';
import '../../core/models/bit_entry.dart';
import '../../core/models/hammer_entry.dart';
import '../../core/services/file_save_service.dart';

enum ExportType {
  ledger('Ledger'),
  diesel('Diesel'),
  pvc('PVC'),
  bit('Bit'),
  hammer('Hammer');

  final String label;
  const ExportType(this.label);
}

class CsvExportScreen extends ConsumerStatefulWidget {
  const CsvExportScreen({super.key});

  @override
  ConsumerState<CsvExportScreen> createState() => _CsvExportScreenState();
}

class _CsvExportScreenState extends ConsumerState<CsvExportScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _exportAll = true;
  bool _isExporting = false;
  ExportType _exportType = ExportType.ledger;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final entriesCount = _getEntriesCount();
    final headers = _getHeaders();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Export to CSV'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Export type selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Export Type',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ExportType.values.map((type) {
                    final isSelected = _exportType == type;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _exportType = type;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          type.label,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Date range options
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Date Range',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                // Export all toggle
                SwitchListTile(
                  value: _exportAll,
                  onChanged: (value) {
                    setState(() {
                      _exportAll = value;
                    });
                  },
                  title: const Text('Export all entries'),
                  subtitle: const Text('Export entire dataset'),
                  contentPadding: EdgeInsets.zero,
                ),
                if (!_exportAll) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(isStart: true),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'From',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.border),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today,
                                        size: 16, color: AppColors.primary),
                                    const SizedBox(width: 8),
                                    Text(dateFormat.format(_startDate)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(isStart: false),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'To',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.border),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today,
                                        size: 16, color: AppColors.primary),
                                    const SizedBox(width: 8),
                                    Text(dateFormat.format(_endDate)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Preview
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Preview',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accentLight.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '$entriesCount entries',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Columns info
                const Text(
                  'Columns to export:',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: headers.map((header) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        header,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Export button
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: entriesCount == 0 || _isExporting ? null : _exportCsv,
              icon: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.file_download),
              label: Text(_isExporting
                  ? 'Exporting...'
                  : 'Export ${_exportType.label} CSV'),
            ),
          ),
        ],
      ),
    );
  }

  int _getEntriesCount() {
    final vehicleId = DatabaseService.currentVehicleId;
    switch (_exportType) {
      case ExportType.ledger:
        return _exportAll
            ? DatabaseService.getAllLedgerEntries().length
            : DatabaseService.getLedgerEntriesByDateRange(_startDate, _endDate)
                .length;
      case ExportType.diesel:
        return _exportAll
            ? DatabaseService.getDieselEntriesByVehicle(vehicleId).length
            : DatabaseService.getDieselEntriesByDateRange(
                    vehicleId, _startDate, _endDate)
                .length;
      case ExportType.pvc:
        return _exportAll
            ? DatabaseService.getPvcEntriesByVehicle(vehicleId).length
            : DatabaseService.getPvcEntriesByDateRange(
                    vehicleId, _startDate, _endDate)
                .length;
      case ExportType.bit:
        return _exportAll
            ? DatabaseService.getBitEntriesByVehicle(vehicleId).length
            : DatabaseService.getBitEntriesByDateRange(
                    vehicleId, _startDate, _endDate)
                .length;
      case ExportType.hammer:
        return _exportAll
            ? DatabaseService.getHammerEntriesByVehicle(vehicleId).length
            : DatabaseService.getHammerEntriesByDateRange(
                    vehicleId, _startDate, _endDate)
                .length;
    }
  }

  List<String> _getHeaders() {
    switch (_exportType) {
      case ExportType.ledger:
        return LedgerEntry.csvHeaders;
      case ExportType.diesel:
        return DieselEntry.csvHeaders;
      case ExportType.pvc:
        return PvcEntry.csvHeaders;
      case ExportType.bit:
        return BitEntry.csvHeaders;
      case ExportType.hammer:
        return HammerEntry.csvHeaders;
    }
  }

  Future<void> _selectDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _exportCsv() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final vehicleId = DatabaseService.currentVehicleId;
      List<List<String>> rows;
      String typeLabel;

      switch (_exportType) {
        case ExportType.ledger:
          final entries = _exportAll
              ? DatabaseService.getAllLedgerEntries()
              : DatabaseService.getLedgerEntriesByDateRange(
                  _startDate, _endDate);
          rows = [
            LedgerEntry.csvHeaders,
            ...entries.map((e) => e.toCsvRow()),
          ];
          typeLabel = 'ledger';
          break;
        case ExportType.diesel:
          final entries = _exportAll
              ? DatabaseService.getDieselEntriesByVehicle(vehicleId)
              : DatabaseService.getDieselEntriesByDateRange(
                  vehicleId, _startDate, _endDate);
          rows = [
            DieselEntry.csvHeaders,
            ...entries.map((e) => e.toCsvRow()),
          ];
          typeLabel = 'diesel';
          break;
        case ExportType.pvc:
          final entries = _exportAll
              ? DatabaseService.getPvcEntriesByVehicle(vehicleId)
              : DatabaseService.getPvcEntriesByDateRange(
                  vehicleId, _startDate, _endDate);
          rows = [
            PvcEntry.csvHeaders,
            ...entries.map((e) => e.toCsvRow()),
          ];
          typeLabel = 'pvc';
          break;
        case ExportType.bit:
          final entries = _exportAll
              ? DatabaseService.getBitEntriesByVehicle(vehicleId)
              : DatabaseService.getBitEntriesByDateRange(
                  vehicleId, _startDate, _endDate);
          rows = [
            BitEntry.csvHeaders,
            ...entries.map((e) => e.toCsvRow()),
          ];
          typeLabel = 'bit';
          break;
        case ExportType.hammer:
          final entries = _exportAll
              ? DatabaseService.getHammerEntriesByVehicle(vehicleId)
              : DatabaseService.getHammerEntriesByDateRange(
                  vehicleId, _startDate, _endDate);
          rows = [
            HammerEntry.csvHeaders,
            ...entries.map((e) => e.toCsvRow()),
          ];
          typeLabel = 'hammer';
          break;
      }

      final csv = const ListToCsvConverter().convert(rows);

      final dateFormat = DateFormat('yyyyMMdd');
      final fileName = _exportAll
          ? 'rigledger_${typeLabel}_export_all_${dateFormat.format(DateTime.now())}.csv'
          : 'rigledger_${typeLabel}_export_${dateFormat.format(_startDate)}_to_${dateFormat.format(_endDate)}.csv';

      final saved = await FileSaveService.saveStringFile(
        context: context,
        content: csv,
        fileName: fileName,
        shareSubject: 'RigLedger ${_exportType.label} CSV Export',
        dialogTitle: 'Save CSV Export',
      );

      if (mounted && saved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CSV exported successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }
}
