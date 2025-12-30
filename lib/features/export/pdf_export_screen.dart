import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/database/database_service.dart';
import '../../core/models/ledger_entry.dart';

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

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
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
      body: _isPreviewMode
          ? _buildPdfPreview(entries)
          : _buildOptions(dateFormat, entries),
    );
  }

  Widget _buildOptions(DateFormat dateFormat, List<LedgerEntry> entries) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Date range
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
        ),
        const SizedBox(height: 16),

        // Summary
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
                _buildSummaryRow(
                  'Total',
                  entries.fold<double>(0, (sum, e) => sum + e.total),
                ),
                _buildSummaryRow(
                  'Received',
                  entries.fold<double>(0, (sum, e) => sum + e.received),
                ),
                _buildSummaryRow(
                  'Balance',
                  entries.fold<double>(0, (sum, e) => sum + e.balance),
                ),
              ],
            ],
          ),
        ),
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

  Widget _buildPdfPreview(List<LedgerEntry> entries) {
    return PdfPreview(
      build: (format) => _generatePdf(entries),
      canDebug: false,
      canChangeOrientation: false,
      canChangePageFormat: false,
      pdfFileName: _getPdfFileName(),
    );
  }

  Widget _buildSummaryRow(String label, double value) {
    final format = NumberFormat('#,##0.00');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(
            format.format(value),
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
    final dateFormat = DateFormat('yyyy-MM-dd');
    final currencyFormat = NumberFormat('#,##0.00');

    // Calculate totals
    final totalSum = entries.fold<double>(0, (sum, e) => sum + e.total);
    final receivedSum = entries.fold<double>(0, (sum, e) => sum + e.received);
    final balanceSum = entries.fold<double>(0, (sum, e) => sum + e.balance);

    // Sort entries by date
    entries.sort((a, b) => a.date.compareTo(b.date));

    const rowsPerPage = 20; // Fewer rows for landscape with more columns
    final totalPages = (entries.length / rowsPerPage).ceil().clamp(1, 999);

    for (int page = 0; page < totalPages; page++) {
      final startIndex = page * rowsPerPage;
      final endIndex = (startIndex + rowsPerPage).clamp(0, entries.length);
      final pageEntries = entries.sublist(startIndex, endIndex);

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
                  'Period: ${dateFormat.format(_startDate)} to ${dateFormat.format(_endDate)}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Generated: ${dateFormat.format(DateTime.now())}',
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
                            'Total Entries', entries.length.toString()),
                        _buildPdfSummaryItem(
                            'Total', currencyFormat.format(totalSum)),
                        _buildPdfSummaryItem(
                            'Received', currencyFormat.format(receivedSum)),
                        _buildPdfSummaryItem(
                            'Balance', currencyFormat.format(balanceSum)),
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
                      0: const pw.FlexColumnWidth(0.9), // Date
                      1: const pw.FlexColumnWidth(0.7), // Bill No
                      2: const pw.FlexColumnWidth(1.0), // Agent
                      3: const pw.FlexColumnWidth(1.0), // Address
                      4: const pw.FlexColumnWidth(0.5), // Depth
                      5: const pw.FlexColumnWidth(0.5), // Depth ft
                      6: const pw.FlexColumnWidth(0.5), // Depth Rate
                      7: const pw.FlexColumnWidth(0.5), // PVC
                      8: const pw.FlexColumnWidth(0.5), // PVC Rate
                      9: const pw.FlexColumnWidth(0.6), // MS Pipe
                      10: const pw.FlexColumnWidth(0.5), // MS Rate
                      11: const pw.FlexColumnWidth(0.5), // Extra
                      12: const pw.FlexColumnWidth(0.6), // Total
                      13: const pw.FlexColumnWidth(0.6), // Received
                      14: const pw.FlexColumnWidth(0.6), // Balance
                      15: const pw.FlexColumnWidth(0.5), // Less
                    },
                    children: [
                      // Header row
                      pw.TableRow(
                        decoration: pw.BoxDecoration(
                          color: PdfColors.blue100,
                        ),
                        children: [
                          _buildTableCell('Date', isHeader: true),
                          _buildTableCell('Bill#', isHeader: true),
                          _buildTableCell('Agent', isHeader: true),
                          _buildTableCell('Address', isHeader: true),
                          _buildTableCell('Depth', isHeader: true),
                          _buildTableCell('Feet', isHeader: true),
                          _buildTableCell('Rate', isHeader: true),
                          _buildTableCell('PVC', isHeader: true),
                          _buildTableCell('PVC₹', isHeader: true),
                          _buildTableCell('MS Pipe', isHeader: true),
                          _buildTableCell('MS₹', isHeader: true),
                          _buildTableCell('Extra', isHeader: true),
                          _buildTableCell('Total', isHeader: true),
                          _buildTableCell('Recd', isHeader: true),
                          _buildTableCell('Balance', isHeader: true),
                          _buildTableCell('Less', isHeader: true),
                        ],
                      ),
                      // Data rows
                      ...pageEntries.map((entry) => pw.TableRow(
                            children: [
                              _buildTableCell(dateFormat.format(entry.date)),
                              _buildTableCell(entry.billNumber),
                              _buildTableCell(entry.agentName),
                              _buildTableCell(entry.address),
                              _buildTableCell(entry.depth),
                              _buildTableCell(entry.depthInFeet.toStringAsFixed(0)),
                              _buildTableCell(currencyFormat.format(entry.depthPerFeetRate)),
                              _buildTableCell(entry.pvc),
                              _buildTableCell(currencyFormat.format(entry.pvcRate)),
                              _buildTableCell(entry.msPipe),
                              _buildTableCell(currencyFormat.format(entry.msPipeRate)),
                              _buildTableCell(currencyFormat.format(entry.extraCharges)),
                              _buildTableCell(currencyFormat.format(entry.total)),
                              _buildTableCell(currencyFormat.format(entry.received)),
                              _buildTableCell(currencyFormat.format(entry.balance)),
                              _buildTableCell(currencyFormat.format(entry.less)),
                            ],
                          )),
                    ],
                  ),
                ),
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
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
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

      final directory = await getApplicationDocumentsDirectory();
      final fileName = _getPdfFileName();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'RigLedger PDF Report',
      );

      if (mounted) {
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
