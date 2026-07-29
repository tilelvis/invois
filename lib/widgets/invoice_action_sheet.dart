import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../models/models.dart';
import '../services/pdf_service.dart';
import 'app_design_system.dart';

/// Shows a slide-up sheet of quick actions for an invoice
/// (share, toggle paid, delete) without leaving the current list.
Future<void> showInvoiceActionSheet({
  required BuildContext context,
  required Invoice invoice,
  required Future<void> Function(bool isPaid) onTogglePaid,
  required Future<void> Function() onDelete,
}) {
  final isPaid = invoice.status == InvoiceStatus.paid;
  return showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      final danger = AppColors.danger(Theme.of(sheetContext).brightness);
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.slate400, borderRadius: BorderRadius.circular(4)),
            ),
            ListTile(
              title: Text(invoice.client.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${invoice.id} · ${PdfService.currencyFormatter.format(invoice.grandTotal)}'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('Share PDF'),
              onTap: () async {
                Navigator.pop(sheetContext);
                final bytes = await PdfService.generateInvoicePdf(invoice);
                await Printing.sharePdf(bytes: bytes, filename: 'Invoice-${invoice.id}.pdf');
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_outlined),
              title: const Text('Share via WhatsApp'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await PdfService.shareInvoiceToWhatsapp(invoice);
              },
            ),
            ListTile(
              leading: Icon(isPaid ? Icons.undo : Icons.check_circle_outline),
              title: Text(isPaid ? 'Mark as unpaid' : 'Mark as paid'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await onTogglePaid(!isPaid);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: danger),
              title: Text('Delete', style: TextStyle(color: danger)),
              onTap: () async {
                Navigator.pop(sheetContext);
                await onDelete();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
