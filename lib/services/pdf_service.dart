import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../models/models.dart';

class PdfService {
  static final currencyFormatter = NumberFormat.currency(locale: 'en_KE', symbol: 'KES ');
  static final dateFormatter = DateFormat('dd MMM yyyy');

  /// Generates a KRA/eTIMS compliant PDF document bytes for a given Invoice.
  static Future<Uint8List> generateInvoicePdf(Invoice invoice) async {
    final pdf = pw.Document();

    // Calculate totals for tax categories
    double standardVatBasis = 0.0;
    double standardVatAmount = 0.0;
    double zeroRatedTotal = 0.0;
    double exemptTotal = 0.0;

    for (final item in invoice.items) {
      if (item.vatCategory == VatCategory.standard16) {
        standardVatBasis += item.subtotal;
        standardVatAmount += item.vatAmount;
      } else if (item.vatCategory == VatCategory.zeroRated) {
        zeroRatedTotal += item.subtotal;
      } else {
        exemptTotal += item.subtotal;
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // 1. INVOICE HEADER & BUSINESS INFO
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'TAX INVOICE',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.teal800,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Invois Micro-Service Provider Ltd.', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      pw.Text('Nairobi, Kenya', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text('Seller KRA PIN: A001234567Z (eTIMS Registered)', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Invoice Ref: ${invoice.id}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                      pw.Text('Date: ${dateFormatter.format(invoice.issueDate)}', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('Due Date: ${dateFormatter.format(invoice.dueDate)}', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 10),

              // 2. CLIENT INFO & PAYMENT GATEWAY DETAILS
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('BILLED TO (M-Pesa Registered):', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                        pw.SizedBox(height: 4),
                        pw.Text(invoice.client.fullName.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                        pw.Text('Phone: ${invoice.client.phoneNumber}', style: const pw.TextStyle(fontSize: 9)),
                        if (invoice.client.kraPin != null && invoice.client.kraPin!.isNotEmpty) ...[
                          pw.SizedBox(height: 2),
                          pw.Text('KRA PIN: ${invoice.client.kraPin!.toUpperCase()}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.blue800)),
                        ],
                        if (invoice.client.email != null) ...[
                          pw.Text('Email: ${invoice.client.email}', style: const pw.TextStyle(fontSize: 9)),
                        ],
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('PAYMENT METHOD (KES):', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          invoice.paymentDetails.mpesaType == MpesaType.paybill ? 'M-PESA PAYBILL' : 'M-PESA TILL NUMBER',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.green800),
                        ),
                        pw.Text('Number: ${invoice.paymentDetails.mpesaNumber}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                        if (invoice.paymentDetails.mpesaType == MpesaType.paybill && invoice.paymentDetails.accountName != null) ...[
                          pw.Text('Account: ${invoice.paymentDetails.accountName}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // 3. LINE ITEMS TABLE
              pw.Text('BILLING LINE ITEMS', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
              pw.SizedBox(height: 6),
              pw.Table(
                border: const pw.TableBorder(
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                  horizontalInside: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1),
                  3: const pw.FlexColumnWidth(1.2),
                  4: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      _buildHeaderCell('Description / Type'),
                      _buildHeaderCell('Qty / Hrs', align: pw.TextAlign.right),
                      _buildHeaderCell('Rate (KES)', align: pw.TextAlign.right),
                      _buildHeaderCell('Tax Code', align: pw.TextAlign.right),
                      _buildHeaderCell('Total (KES)', align: pw.TextAlign.right),
                    ],
                  ),
                  // Table Body Rows
                  ...invoice.items.map((item) {
                    final isLabor = item.type == ItemType.labor;
                    final taxCodeStr = item.vatCategory == VatCategory.standard16
                        ? '16% VAT'
                        : item.vatCategory == VatCategory.zeroRated
                            ? '0% ZR'
                            : 'Exempt';

                    return pw.TableRow(
                      children: [
                        _buildTableCell(
                          '${item.description}\n(${isLabor ? "Labor service" : "Physical material"})',
                          style: pw.TextStyle(fontSize: 9, color: PdfColors.black),
                        ),
                        _buildTableCell('${item.quantity}', align: pw.TextAlign.right),
                        _buildTableCell(currencyFormatter.format(item.unitPrice).replaceFirst('KES ', ''), align: pw.TextAlign.right),
                        _buildTableCell(taxCodeStr, align: pw.TextAlign.right),
                        _buildTableCell(currencyFormatter.format(item.totalWithVat).replaceFirst('KES ', ''), align: pw.TextAlign.right, isBold: true),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 15),

              // 4. TAX SUMMARY & TOTALS CARD
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('KRA TAX COMPLIANCE BREAKDOWN (KES):', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                        pw.SizedBox(height: 4),
                        _buildTaxRow('Standard 16% VAT Sales:', currencyFormatter.format(standardVatBasis)),
                        _buildTaxRow('Standard 16% VAT Amount:', currencyFormatter.format(standardVatAmount)),
                        _buildTaxRow('Zero-Rated Sales (0%):', currencyFormatter.format(zeroRatedTotal)),
                        _buildTaxRow('Exempt Sales:', currencyFormatter.format(exemptTotal)),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 40),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey100,
                        borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                        children: [
                          _buildTotalRow('Subtotal:', currencyFormatter.format(invoice.totalSubtotal)),
                          _buildTotalRow('VAT obligations:', currencyFormatter.format(invoice.totalVat)),
                          pw.Divider(color: PdfColors.grey400, thickness: 1),
                          _buildTotalRow('GRAND TOTAL:', currencyFormatter.format(invoice.grandTotal), isLarge: true),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 25),

              // 5. eTIMS VERIFICATION BLOCK
              if (invoice.isEtimsValidated && invoice.etimsInvoiceNumber != null) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.green700, width: 1.5),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Container(
                        width: 14,
                        height: 14,
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.green700,
                          shape: pw.BoxShape.circle,
                        ),
                        child: pw.Center(
                          child: pw.Text('V', style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('KRA eTIMS COMPLIANCE CONFIRMED', style: pw.TextStyle(color: PdfColors.green900, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                          pw.Text('eTIMS Ref: ${invoice.etimsInvoiceNumber!}', style: pw.TextStyle(font: pw.Font.courier(), fontSize: 8, color: PdfColors.grey700)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              pw.Spacer(),

              // 6. FOOTER
              pw.Align(
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'Asante kwa kufanya biashara nasi. / Thank you for your business.',
                  style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: PdfColors.grey600),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeaderCell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900),
      ),
    );
  }

  static pw.Widget _buildTableCell(String text, {pw.TextAlign align = pw.TextAlign.left, pw.TextStyle? style, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: pw.Text(
        text,
        textAlign: align,
        style: style ?? pw.TextStyle(fontSize: 8, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal),
      ),
    );
  }

  static pw.Widget _buildTaxRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          pw.Text(value, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.Widget _buildTotalRow(String label, String value, {bool isLarge = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: isLarge ? 10 : 8, fontWeight: isLarge ? pw.FontWeight.bold : pw.FontWeight.normal)),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: isLarge ? 11 : 8,
            fontWeight: pw.FontWeight.bold,
            color: isLarge ? PdfColors.green900 : PdfColors.black,
          ),
        ),
      ],
    );
  }

  /// Triggers standard WhatsApp sharing using share_plus, formatting a clean receipt summary.
  static Future<void> shareInvoiceToWhatsapp(Invoice invoice) async {
    final clientName = invoice.client.fullName;
    final totalKES = currencyFormatter.format(invoice.grandTotal);
    final mpesaRefStr = invoice.paymentDetails.mpesaType == MpesaType.paybill
        ? 'M-Pesa Paybill ${invoice.paymentDetails.mpesaNumber} (Account: ${invoice.paymentDetails.accountName})'
        : 'M-Pesa Till Number ${invoice.paymentDetails.mpesaNumber}';

    final text = 'Habari $clientName,\n\n'
        'Here is your Invoice summary for your review:\n'
        'Invoice Reference: ${invoice.id}\n'
        'KRA eTIMS Validated: ${invoice.isEtimsValidated ? "YES (${invoice.etimsInvoiceNumber})" : "NO (Exempt/Pending)"}\n'
        'Total Amount: $totalKES\n\n'
        'Please complete payment via: $mpesaRefStr.\n\n'
        'Generated securely via Invois App Kenya.';

    await Share.share(text, subject: 'Invoice ${invoice.id} from Invois App');
  }
}
