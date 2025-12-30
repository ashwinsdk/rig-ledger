import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/database/database_service.dart';
import '../../core/models/ledger_entry.dart';
import '../../core/services/file_save_service.dart';

class PdfColumn {
  final String id;
  final String label;
  final String Function(LedgerEntry) getValue;
  final double flex;

  const PdfColumn({
    required this.id,
    required this.label,
    required this.getValue,
    this.flex = 1.0,
  });
}

class PdfExportScreen extends ConsumerStatefulWidget {
  const PdfExportScreen({super.key});

  @override
  ConsumerState<PdfExportScreen> createState() => _PdfExportScreenState();
}

class _PdfExportScreenState extends ConsumerState<PdfExportScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isGenerating = false;
  bool _isPreviewMode = false;

  final NumberFormat _currencyFormat = NumberFormat('#,##0.00');
  final NumberFormat _feetFormat = NumberFormat('#,##0');
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  // Available columns for selection
  late final List<PdfColumn> _allColumns;
  late Set<String> _selectedColumnIds;

  @override
  void initState() {
    super.initState();
    _allColumns = [
      PdfColumn(
          id: 'date',
          label: 'Date',
          getValue: (e) => _dateFormat.format(e.date),
          flex: 0.9),
      PdfColumn(
          id: 'billNumber',
          label: 'Bill#',
          getValue: (e) => e.billNumber,
          flex: 0.7),
      PdfColumn(
          id: 'agent', label: 'Agent', getValue: (e) => e.agentName, flex: 1.0),
      PdfColumn(
          id: 'address',
          label: 'Address',
          getValue: (e) => e.address,
          flex: 1.0),
      PdfColumn(
          id: 'depthType', label: 'Depth', getValue: (e) => e.depth, flex: 0.5),
      PdfColumn(
          id: 'depthFeet',
          label: 'Depth ft',
          getValue: (e) => _feetFormat.format(e.depthInFeet),
          flex: 0.5),
      PdfColumn(
          id: 'depthRate',
          label: 'Depth Rate',
          getValue: (e) => _currencyFormat.format(e.depthPerFeetRate),
          flex: 0.5),
      PdfColumn(
          id: 'stepRate',
          label: 'Step Rate',
          getValue: (e) => _currencyFormat.format(e.stepRate),
          flex: 0.6),
      PdfColumn(id: 'pvcType', label: 'PVC', getValue: (e) => e.pvc, flex: 0.5),
      PdfColumn(
          id: 'pvcFeet',
          label: 'PVC ft',
          getValue: (e) => _feetFormat.format(e.pvcInFeet),
          flex: 0.5),
      PdfColumn(
          id: 'pvcRate',
          label: 'PVC Rate',
          getValue: (e) => _currencyFormat.format(e.pvcPerFeetRate),
          flex: 0.5),
      PdfColumn(
          id: 'msPipeType',
          label: 'MS Type',
          getValue: (e) => e.msPipe,
          flex: 0.5),
      PdfColumn(
          id: 'msPipeFeet',
          label: 'MS ft',
          getValue: (e) => _feetFormat.format(e.msPipeInFeet),
          flex: 0.5),
      PdfColumn(
          id: 'msPipeRate',
          label: 'MS Rate',
          getValue: (e) => _currencyFormat.format(e.msPipePerFeetRate),
          flex: 0.5),
      PdfColumn(
          id: 'extra',
          label: 'Extra',
          getValue: (e) => _currencyFormat.format(e.extraCharges),
          flex: 0.5),
      PdfColumn(
          id: 'total',
          label: 'Total',
          getValue: (e) => _currencyFormat.format(e.total),
          flex: 0.6),
      PdfColumn(
          id: 'received',
          label: 'Received',
          getValue: (e) => _currencyFormat.format(e.received),
          flex: 0.6),
      PdfColumn(
          id: 'balance',
          label: 'Balance',
          getValue: (e) => _currencyFormat.format(e.balance),
          flex: 0.6),
      PdfColumn(
          id: 'less',
          label: 'Less',
          getValue: (e) => _currencyFormat.format(e.less),
          flex: 0.5),
    ];
    // Default: select all columns
    _selectedColumnIds = _allColumns.map((c) => c.id).toSet();
  }

  List<PdfColumn> get _selectedColumns =>
      _allColumns.where((c) => _selectedColumnIds.contains(c.id)).toList();

  @override
  Widget build(BuildContext context) {
    final entries =
        DatabaseService.getLedgerEntriesByDateRange(_startDate, _endDate);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Export to PDF'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (entries.isNotEmpty && !_isPreviewMode)
            IconButton(
              icon: const Icon(Icons.preview),
              onPressed: () {
                setState(() {
                  _isPreviewMode = true;
                });
              },
              tooltip: 'Preview',
            ),
          if (_isPreviewMode)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isPreviewMode = false;
                });
              },
              tooltip: 'Close Preview',
            ),
        ],
      ),
      body: _isPreviewMode ? _buildPdfPreview(entries) : _buildOptions(entries),
    );
  }

  Widget _buildOptions(List<LedgerEntry> entries) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Date range
        _buildDateRangeCard(dateFormat),
        const SizedBox(height: 16),

        // Column Selection
        _buildColumnSelectionCard(),
        const SizedBox(height: 16),

        // Summary with feet totals
        _buildSummaryCard(entries),
        const SizedBox(height: 24),

        // Export buttons
        SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: entries.isEmpty || _isGenerating ? null : _exportPdf,
            icon: _isGenerating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.picture_as_pdf),
            label: Text(_isGenerating ? 'Generating...' : 'Export PDF'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 50,
          child: OutlinedButton.icon(
            onPressed: entries.isEmpty
                ? null
                : () {
                    setState(() {
                      _isPreviewMode = true;
                    });
                  },
            icon: const Icon(Icons.preview),
            label: const Text('Preview'),
          ),
        ),

        if (entries.isEmpty) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.warning),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No entries found in the selected date range.',
                    style: TextStyle(color: AppColors.warning),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDateRangeCard(DateFormat dateFormat) {
    return Container(
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
      ),
    );
  }

  Widget _buildColumnSelectionCard() {
    return Container(
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
                'Columns to Export',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedColumnIds =
                            _allColumns.map((c) => c.id).toSet();
                      });
                    },
                    child: const Text('All'),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedColumnIds = {};
                      });
                    },
                    child: const Text('None'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allColumns.map((column) {
              final isSelected = _selectedColumnIds.contains(column.id);
              return FilterChip(
                label: Text(column.label),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedColumnIds.add(column.id);
                    } else {
                      _selectedColumnIds.remove(column.id);
                    }
                  });
                },
                selectedColor: AppColors.primary.withOpacity(0.2),
                checkmarkColor: AppColors.primary,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(List<LedgerEntry> entries) {
    // Calculate totals
    double totalSum = 0;
    double receivedSum = 0;
    double balanceSum = 0;
    double depth7inch = 0;
    double depth8inch = 0;
    double pvc7inch = 0;
    double pvc8inch = 0;
    double msPipeTotal = 0;

    for (final e in entries) {
      totalSum += e.total;
      receivedSum += e.received;
      balanceSum += e.balance;

      if (e.depth == '7inch') {
        depth7inch += e.depthInFeet;
      } else if (e.depth == '8inch') {
        depth8inch += e.depthInFeet;
      }

      if (e.pvc == '7inch') {
        pvc7inch += e.pvcInFeet;
      } else if (e.pvc == '8inch') {
        pvc8inch += e.pvcInFeet;
      }

      msPipeTotal += e.msPipeInFeet;
    }

    return Container(
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
                'Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accentLight.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${entries.length} entries',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (entries.isNotEmpty) ...[
            const SizedBox(height: 16),
            // Financial Summary
            _buildSummaryRow(
                'Total', 'Rs. ${_currencyFormat.format(totalSum)}'),
            _buildSummaryRow(
                'Received', 'Rs. ${_currencyFormat.format(receivedSum)}'),
            _buildSummaryRow(
                'Balance', 'Rs. ${_currencyFormat.format(balanceSum)}'),
            const Divider(height: 24),
            // Feet Totals
            const Text(
              'Feet Totals',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            _buildSummaryRow(
                '7" Depth', '${_feetFormat.format(depth7inch)} ft'),
            _buildSummaryRow(
                '8" Depth', '${_feetFormat.format(depth8inch)} ft'),
            _buildSummaryRow('7" PVC', '${_feetFormat.format(pvc7inch)} ft'),
            _buildSummaryRow('8" PVC', '${_feetFormat.format(pvc8inch)} ft'),
            _buildSummaryRow(
                'MS Pipe', '${_feetFormat.format(msPipeTotal)} ft'),
          ],
        ],
      ),
    );
  }

  Widget _buildPdfPreview(List<LedgerEntry> entries) {
    return PdfPreview(
      build: (format) => _generatePdf(entries),
      canDebug: false,
      canChangeOrientation: false,
      canChangePageFormat: false,
      pdfFileName: _getPdfFileName(),
      allowPrinting: true,
      allowSharing: true,
      maxPageWidth: 700,
      pdfPreviewPageDecoration: const BoxDecoration(),
      previewPageMargin: const EdgeInsets.all(8),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
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

  String _getPdfFileName() {
    final dateFormat = DateFormat('yyyyMMdd');
    return 'rigledger_${dateFormat.format(_startDate)}_to_${dateFormat.format(_endDate)}.pdf';
  }

  Future<Uint8List> _generatePdf(List<LedgerEntry> entries) async {
    final pdf = pw.Document();

    // Calculate totals
    double totalSum = 0;
    double receivedSum = 0;
    double balanceSum = 0;
    double depth7inch = 0;
    double depth8inch = 0;
    double pvc7inch = 0;
    double pvc8inch = 0;
    double msPipeTotal = 0;

    for (final e in entries) {
      totalSum += e.total;
      receivedSum += e.received;
      balanceSum += e.balance;

      if (e.depth == '7inch') {
        depth7inch += e.depthInFeet;
      } else if (e.depth == '8inch') {
        depth8inch += e.depthInFeet;
      }

      if (e.pvc == '7inch') {
        pvc7inch += e.pvcInFeet;
      } else if (e.pvc == '8inch') {
        pvc8inch += e.pvcInFeet;
      }

      msPipeTotal += e.msPipeInFeet;
    }

    // Sort entries by date
    entries.sort((a, b) => a.date.compareTo(b.date));

    final columns = _selectedColumns;
    final rowsPerPage = 22;
    final totalPages = (entries.length / rowsPerPage).ceil().clamp(1, 999);

    for (int page = 0; page < totalPages; page++) {
      final startIndex = page * rowsPerPage;
      final endIndex = (startIndex + rowsPerPage).clamp(0, entries.length);
      final pageEntries = entries.sublist(startIndex, endIndex);
      final isLastPage = page == totalPages - 1;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'RigLedger Report',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Page ${page + 1} of $totalPages',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Period: ${_dateFormat.format(_startDate)} to ${_dateFormat.format(_endDate)}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Generated: ${_dateFormat.format(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 16),

                // Summary on first page
                if (page == 0) ...[
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                      children: [
                        _buildPdfSummaryItem(
                            'Entries', entries.length.toString()),
                        _buildPdfSummaryItem(
                            'Total', 'Rs. ${_currencyFormat.format(totalSum)}'),
                        _buildPdfSummaryItem('Received',
                            'Rs. ${_currencyFormat.format(receivedSum)}'),
                        _buildPdfSummaryItem('Balance',
                            'Rs. ${_currencyFormat.format(balanceSum)}'),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 16),
                ],

                // Table
                pw.Expanded(
                  child: pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                    columnWidths: {
                      for (int i = 0; i < columns.length; i++)
                        i: pw.FlexColumnWidth(columns[i].flex),
                    },
                    children: [
                      // Header row
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.blue100,
                        ),
                        children: columns
                            .map(
                                (c) => _buildTableCell(c.label, isHeader: true))
                            .toList(),
                      ),
                      // Data rows
                      ...pageEntries.map((entry) => pw.TableRow(
                            children: columns
                                .map((c) => _buildTableCell(c.getValue(entry)))
                                .toList(),
                          )),
                    ],
                  ),
                ),

                // Feet totals on last page
                if (isLastPage) ...[
                  pw.SizedBox(height: 16),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Feet Totals',
                          style: pw.TextStyle(
                              fontSize: 12, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                          children: [
                            _buildPdfSummaryItem('7" Depth',
                                '${_feetFormat.format(depth7inch)} ft'),
                            _buildPdfSummaryItem('8" Depth',
                                '${_feetFormat.format(depth8inch)} ft'),
                            _buildPdfSummaryItem(
                                '7" PVC', '${_feetFormat.format(pvc7inch)} ft'),
                            _buildPdfSummaryItem(
                                '8" PVC', '${_feetFormat.format(pvc8inch)} ft'),
                            _buildPdfSummaryItem('MS Pipe',
                                '${_feetFormat.format(msPipeTotal)} ft'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  pw.Widget _buildPdfSummaryItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(label,
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        pw.SizedBox(height: 4),
        pw.Text(value,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 7 : 6,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        maxLines: 2,
      ),
    );
  }

  Future<void> _exportPdf() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final entries =
          DatabaseService.getLedgerEntriesByDateRange(_startDate, _endDate);
      final pdfBytes = await _generatePdf(entries);

      final fileName = _getPdfFileName();

      final saved = await FileSaveService.saveFile(
        context: context,
        bytes: Uint8List.fromList(pdfBytes),
        fileName: fileName,
        shareSubject: 'RigLedger PDF Report',
        dialogTitle: 'Save PDF Report',
      );

      if (mounted && saved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF exported successfully'),
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
          _isGenerating = false;
        });
      }
    }
  }
}
