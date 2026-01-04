import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/database/database_service.dart';
import '../../core/models/ledger_entry.dart';
import '../../core/services/file_save_service.dart';

/// Invoice options for customization
class InvoiceOptions {
  bool showVehicleName;
  bool showBillNumber;
  bool showDate;
  bool showAgentName;
  bool showAddress;
  bool showDepthDetails;
  bool showPvcDetails;
  bool showMsPipeDetails;
  bool showStepRate;
  bool showExtraCharges;
  bool showTotal;
  bool showReceived;
  bool showBalance;
  bool showLess;
  bool showNotes;
  bool showPaymentBreakdown;

  InvoiceOptions({
    this.showVehicleName = true,
    this.showBillNumber = true,
    this.showDate = true,
    this.showAgentName = true,
    this.showAddress = true,
    this.showDepthDetails = true,
    this.showPvcDetails = true,
    this.showMsPipeDetails = true,
    this.showStepRate = true,
    this.showExtraCharges = true,
    this.showTotal = true,
    this.showReceived = true,
    this.showBalance = true,
    this.showLess = true,
    this.showNotes = false,
    this.showPaymentBreakdown = true,
  });
}

class InvoiceScreen extends ConsumerStatefulWidget {
  final LedgerEntry entry;

  const InvoiceScreen({super.key, required this.entry});

  @override
  ConsumerState<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends ConsumerState<InvoiceScreen> {
  bool _isGenerating = false;
  bool _isPreviewMode = true;
  late InvoiceOptions _options;

  final NumberFormat _currencyFormat = NumberFormat('#,##0.00');
  final NumberFormat _feetFormat = NumberFormat('#,##0');
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _options = InvoiceOptions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Invoice #${widget.entry.billNumber}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isPreviewMode ? Icons.settings : Icons.preview),
            onPressed: () {
              setState(() {
                _isPreviewMode = !_isPreviewMode;
              });
            },
            tooltip: _isPreviewMode ? 'Options' : 'Preview',
          ),
        ],
      ),
      body: _isPreviewMode ? _buildPdfPreview() : _buildOptions(),
    );
  }

  Widget _buildOptions() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildOptionsCard(),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _isPreviewMode = true;
                  });
                },
                icon: const Icon(Icons.preview),
                label: const Text('Preview'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _exportInvoice,
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
                label: Text(_isGenerating ? 'Generating...' : 'Export'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOptionsCard() {
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
                'Invoice Contents',
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
                        _options = InvoiceOptions(
                          showVehicleName: true,
                          showBillNumber: true,
                          showDate: true,
                          showAgentName: true,
                          showAddress: true,
                          showDepthDetails: true,
                          showPvcDetails: true,
                          showMsPipeDetails: true,
                          showStepRate: true,
                          showExtraCharges: true,
                          showTotal: true,
                          showReceived: true,
                          showBalance: true,
                          showLess: true,
                          showNotes: true,
                          showPaymentBreakdown: true,
                        );
                      });
                    },
                    child: const Text('All'),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _options = InvoiceOptions(
                          showVehicleName: false,
                          showBillNumber: true,
                          showDate: true,
                          showAgentName: false,
                          showAddress: true,
                          showDepthDetails: true,
                          showPvcDetails: true,
                          showMsPipeDetails: true,
                          showStepRate: false,
                          showExtraCharges: true,
                          showTotal: true,
                          showReceived: false,
                          showBalance: false,
                          showLess: false,
                          showNotes: false,
                          showPaymentBreakdown: false,
                        );
                      });
                    },
                    child: const Text('Minimal'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildOptionSwitch('Vehicle Name', _options.showVehicleName,
              (v) => setState(() => _options.showVehicleName = v)),
          _buildOptionSwitch('Bill Number', _options.showBillNumber,
              (v) => setState(() => _options.showBillNumber = v)),
          _buildOptionSwitch('Date', _options.showDate,
              (v) => setState(() => _options.showDate = v)),
          _buildOptionSwitch('Agent Name', _options.showAgentName,
              (v) => setState(() => _options.showAgentName = v)),
          _buildOptionSwitch('Address', _options.showAddress,
              (v) => setState(() => _options.showAddress = v)),
          const Divider(height: 24),
          const Text(
            'Details',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          _buildOptionSwitch('Depth Details', _options.showDepthDetails,
              (v) => setState(() => _options.showDepthDetails = v)),
          _buildOptionSwitch('PVC Details', _options.showPvcDetails,
              (v) => setState(() => _options.showPvcDetails = v)),
          _buildOptionSwitch('MS Pipe Details', _options.showMsPipeDetails,
              (v) => setState(() => _options.showMsPipeDetails = v)),
          _buildOptionSwitch('Step Rate', _options.showStepRate,
              (v) => setState(() => _options.showStepRate = v)),
          _buildOptionSwitch('Extra Charges', _options.showExtraCharges,
              (v) => setState(() => _options.showExtraCharges = v)),
          const Divider(height: 24),
          const Text(
            'Financial',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          _buildOptionSwitch('Total', _options.showTotal,
              (v) => setState(() => _options.showTotal = v)),
          _buildOptionSwitch('Received', _options.showReceived,
              (v) => setState(() => _options.showReceived = v)),
          _buildOptionSwitch('Balance', _options.showBalance,
              (v) => setState(() => _options.showBalance = v)),
          _buildOptionSwitch('Less/Discount', _options.showLess,
              (v) => setState(() => _options.showLess = v)),
          _buildOptionSwitch('Payment Breakdown', _options.showPaymentBreakdown,
              (v) => setState(() => _options.showPaymentBreakdown = v)),
          _buildOptionSwitch('Notes', _options.showNotes,
              (v) => setState(() => _options.showNotes = v)),
        ],
      ),
    );
  }

  Widget _buildOptionSwitch(
      String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildPdfPreview() {
    return PdfPreview(
      build: (format) => _generateInvoicePdf(),
      canDebug: false,
      canChangeOrientation: false,
      canChangePageFormat: false,
      pdfFileName: 'invoice_${widget.entry.billNumber}.pdf',
      allowPrinting: true,
      allowSharing: true,
      maxPageWidth: 700,
      pdfPreviewPageDecoration: const BoxDecoration(),
      previewPageMargin: const EdgeInsets.all(8),
    );
  }

  Future<void> _exportInvoice() async {
    setState(() => _isGenerating = true);

    try {
      final pdfBytes = await _generateInvoicePdf();
      final fileName = 'invoice_${widget.entry.billNumber}.pdf';

      final saved = await FileSaveService.saveFile(
        context: context,
        bytes: pdfBytes,
        fileName: fileName,
        shareSubject: 'Invoice #${widget.entry.billNumber}',
      );

      if (mounted && saved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice exported successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export invoice: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<Uint8List> _generateInvoicePdf() async {
    final pdf = pw.Document();
    final entry = widget.entry;

    // Get current vehicle name
    final currentVehicle = DatabaseService.getCurrentVehicle();
    final vehicleName = currentVehicle?.name ?? 'RigLedger';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue800,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'INVOICE',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 28,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        if (_options.showVehicleName)
                          pw.Text(
                            vehicleName,
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        if (_options.showBillNumber)
                          pw.Text(
                            '#${entry.billNumber}',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        if (_options.showDate)
                          pw.Text(
                            _dateFormat.format(entry.date),
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              // Customer Info
              if (_options.showAgentName || _options.showAddress)
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Bill To:',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey600,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      if (_options.showAgentName)
                        pw.Text(
                          entry.agentName,
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      if (_options.showAddress)
                        pw.Text(
                          entry.address,
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                ),
              pw.SizedBox(height: 30),

              // Line Items Table
              pw.Text(
                'Details',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1.5),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(2),
                },
                children: [
                  // Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _buildTableHeader('Description'),
                      _buildTableHeader('Quantity'),
                      _buildTableHeader('Rate'),
                      _buildTableHeader('Amount'),
                    ],
                  ),
                  // Depth row
                  if (_options.showDepthDetails)
                    pw.TableRow(
                      children: [
                        _buildTableCell('Depth (${entry.depth})'),
                        _buildTableCell('${_feetFormat.format(entry.depthInFeet)} ft'),
                        _buildTableCell('₹${_currencyFormat.format(entry.depthPerFeetRate)}/ft'),
                        _buildTableCell('₹${_currencyFormat.format(entry.depthInFeet * entry.depthPerFeetRate)}'),
                      ],
                    ),
                  // Step Rate row
                  if (_options.showStepRate && entry.stepRate > 0)
                    pw.TableRow(
                      children: [
                        _buildTableCell('Step Rate'),
                        _buildTableCell('-'),
                        _buildTableCell('-'),
                        _buildTableCell('₹${_currencyFormat.format(entry.stepRate)}'),
                      ],
                    ),
                  // PVC row
                  if (_options.showPvcDetails && entry.pvcInFeet > 0)
                    pw.TableRow(
                      children: [
                        _buildTableCell('PVC (${entry.pvc})'),
                        _buildTableCell('${_feetFormat.format(entry.pvcInFeet)} ft'),
                        _buildTableCell('₹${_currencyFormat.format(entry.pvcPerFeetRate)}/ft'),
                        _buildTableCell('₹${_currencyFormat.format(entry.pvcInFeet * entry.pvcPerFeetRate)}'),
                      ],
                    ),
                  // MS Pipe row
                  if (_options.showMsPipeDetails && entry.msPipeInFeet > 0)
                    pw.TableRow(
                      children: [
                        _buildTableCell('MS Pipe (${entry.msPipe})'),
                        _buildTableCell('${_feetFormat.format(entry.msPipeInFeet)} ft'),
                        _buildTableCell('₹${_currencyFormat.format(entry.msPipePerFeetRate)}/ft'),
                        _buildTableCell('₹${_currencyFormat.format(entry.msPipeInFeet * entry.msPipePerFeetRate)}'),
                      ],
                    ),
                  // Extra charges
                  if (_options.showExtraCharges && entry.extraCharges > 0)
                    pw.TableRow(
                      children: [
                        _buildTableCell('Extra Charges'),
                        _buildTableCell('-'),
                        _buildTableCell('-'),
                        _buildTableCell('₹${_currencyFormat.format(entry.extraCharges)}'),
                      ],
                    ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Totals Section
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 250,
                    child: pw.Column(
                      children: [
                        if (_options.showTotal)
                          _buildTotalRow('Total', entry.total, isBold: true),
                        if (_options.showLess && entry.less > 0)
                          _buildTotalRow('Less/Discount', -entry.less),
                        if (_options.showReceived)
                          _buildTotalRow('Received', entry.received, color: PdfColors.green700),
                        if (_options.showBalance)
                          _buildTotalRow(
                            'Balance Due',
                            entry.balance,
                            isBold: true,
                            color: entry.balance > 0 ? PdfColors.orange700 : PdfColors.green700,
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              // Payment Breakdown
              if (_options.showPaymentBreakdown && (entry.receivedCash > 0 || entry.receivedPhonePe > 0)) ...[
                pw.SizedBox(height: 20),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Payment Breakdown',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      if (entry.receivedCash > 0)
                        pw.Text('Cash: ₹${_currencyFormat.format(entry.receivedCash)}'),
                      if (entry.receivedPhonePe > 0)
                        pw.Text(
                          'PhonePe: ₹${_currencyFormat.format(entry.receivedPhonePe)}${entry.phonePeName != null ? ' (${entry.phonePeName})' : ''}',
                        ),
                    ],
                  ),
                ),
              ],

              // Notes
              if (_options.showNotes && entry.notes != null && entry.notes!.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Notes:',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        entry.notes!,
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],

              pw.Spacer(),

              // Footer
              pw.Container(
                padding: const pw.EdgeInsets.only(top: 20),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Generated by RigLedger',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey500,
                      ),
                    ),
                    pw.Text(
                      DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now()),
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildTableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _buildTableCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
  }

  pw.Widget _buildTotalRow(String label, double amount,
      {bool isBold = false, PdfColor? color}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            '₹${_currencyFormat.format(amount.abs())}${amount < 0 ? ' (-)' : ''}',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
