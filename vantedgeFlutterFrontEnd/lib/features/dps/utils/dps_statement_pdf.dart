import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../data/models/dps_statement_model.dart';
import '../data/models/dps_installment_model.dart';

class DpsStatementPdf {
  DpsStatementPdf._();

  static final _currFmt = NumberFormat.currency(
    symbol: '৳ ',
    decimalDigits: 2,
    locale: 'en_IN',
  );
  static final _dateFmt = DateFormat('dd MMM yyyy');

  static String _fmtAmt(double? v) => v != null ? _currFmt.format(v) : '—';
  static String _fmtDate(DateTime? d) => d != null ? _dateFmt.format(d) : '—';

  static pw.Widget _pdfSummaryItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  static Future<void> generate(
    DpsStatementModel statement, {
    bool share = true,
  }) async {
    final pdf = pw.Document();

    final paidInstallments = statement.installments
            ?.where((i) => i.status?.toUpperCase() == 'PAID')
            .toList() ??
        [];
    final pendingInstallments = statement.installments
            ?.where((i) => i.status?.toUpperCase() == 'PENDING')
            .toList() ??
        [];
    final overdueInstallments = statement.installments
            ?.where((i) => i.status?.toUpperCase() == 'OVERDUE')
            .toList() ??
        [];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          // ── Header ──────────────────────────────────────────────────────
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'DPS Statement',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Account: ${statement.dpsNumber ?? '—'}',
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                  if (statement.customerName != null)
                    pw.Text(
                      'Customer: ${statement.customerName}',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Generated',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                  ),
                  pw.Text(
                    _dateFmt.format(DateTime.now()),
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  if (statement.maturityDate != null) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Maturity Date',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                    ),
                    pw.Text(
                      _fmtDate(statement.maturityDate),
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ],
              ),
            ],
          ),

          pw.Divider(thickness: 1),
          pw.SizedBox(height: 8),

          // ── Summary Box ──────────────────────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _pdfSummaryItem(
                  'Monthly Installment',
                  _fmtAmt(statement.monthlyInstallment?.toDouble()),
                ),
                _pdfSummaryItem(
                  'Total Deposited',
                  _fmtAmt(statement.totalDeposited?.toDouble()),
                ),
                _pdfSummaryItem(
                  'Maturity Amount',
                  _fmtAmt(statement.maturityAmount?.toDouble()),
                ),
                _pdfSummaryItem(
                  'Paid / Total',
                  '${statement.paidInstallments ?? 0} / ${statement.totalInstallments ?? 0}',
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 16),

          // ── Progress Bar ─────────────────────────────────────────────────
          pw.Builder(builder: (context) {
            final paid = statement.paidInstallments ?? 0;
            final total = statement.totalInstallments ?? 1;
            final ratio = (paid / total).clamp(0.0, 1.0);

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Progress: ${(ratio * 100).toStringAsFixed(1)}% complete',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 4),
                pw.Stack(children: [
                  pw.Container(
                    height: 8,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey300,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                  ),
                  pw.Container(
                    height: 8,
                    width: 527 * ratio, // A4 width minus margins ≈ 527pt
                    decoration: pw.BoxDecoration(
                      color: PdfColors.green700,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                  ),
                ]),
              ],
            );
          }),

          pw.SizedBox(height: 20),

          // ── Installments Table ───────────────────────────────────────────
          pw.Text(
            'Installment Schedule (${statement.installments?.length ?? 0} total)',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),

          pw.TableHelper.fromTextArray(
            headers: ['#', 'Due Date', 'Amount', 'Paid Date', 'Status', 'Penalty', 'Ref / TXN'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignments: {
              0: pw.Alignment.center,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerLeft,
              4: pw.Alignment.center,
              5: pw.Alignment.centerRight,
              6: pw.Alignment.centerLeft,
            },
            data: (statement.installments ?? []).map((inst) {
              final status = inst.status?.toUpperCase() ?? 'PENDING';
              return [
                '${inst.installmentNumber ?? '?'}',
                _fmtDate(inst.dueDate),
                _fmtAmt(inst.amount?.toDouble()),
                _fmtDate(inst.paymentDate),
                status,
                (inst.penaltyAmount ?? 0) > 0
                    ? _fmtAmt(inst.penaltyAmount?.toDouble())
                    : '—',
                inst.transactionId ?? inst.receiptNumber ?? '—',
              ];
            }).toList(),
          ),

          pw.SizedBox(height: 20),

          // ── Footer Note ──────────────────────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey50,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('ℹ  ', style: const pw.TextStyle(fontSize: 9)),
                pw.Expanded(
                  child: pw.Text(
                    'This is a system-generated statement. '
                    'Paid: ${paidInstallments.length}  •  '
                    'Pending: ${pendingInstallments.length}  •  '
                    'Overdue: ${overdueInstallments.length}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (share) {
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename:
            'dps_statement_${statement.dpsNumber ?? 'unknown'}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      );
    } else {
      await Printing.layoutPdf(
        onLayout: (_) async => pdf.save(),
      );
    }
  }
}