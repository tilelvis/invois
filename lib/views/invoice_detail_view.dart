import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../models/models.dart';
import '../providers/invoices_list_provider.dart';
import '../services/pdf_service.dart';
import '../widgets/invoice_timeline.dart';
import '../widgets/status_badge.dart';

class InvoiceDetailView extends ConsumerWidget {
  final Invoice invoice;
  const InvoiceDetailView({super.key, required this.invoice});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = PdfService.currencyFormatter;
    final dateFmt = PdfService.dateFormatter;
    final isPaid = invoice.status == InvoiceStatus.paid;

    return Scaffold(
      appBar: AppBar(
        title: Text(invoice.id),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete invoice',
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                invoice.client.fullName,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              StatusBadge(status: invoice.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(invoice.client.phoneNumber, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 16),
          _row('Issue date', dateFmt.format(invoice.issueDate)),
          _row('Due date', dateFmt.format(invoice.dueDate)),
          _row('Items', '${invoice.items.length}'),
          const Divider(height: 32),
          _row('Subtotal', currency.format(invoice.totalSubtotal)),
          _row('VAT', currency.format(invoice.totalVat)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Grand total', style: TextStyle(color: Colors.black54)),
                Hero(
                  tag: 'invoice-amount-${invoice.id}',
                  child: Material(
                    type: MaterialType.transparency,
                    child: Text(
                      currency.format(invoice.grandTotal),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Timeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          InvoiceTimeline(invoice: invoice),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Mark as paid'),
            subtitle: Text(isPaid ? 'Client has settled this invoice' : 'Awaiting payment'),
            value: isPaid,
            onChanged: (value) async {
              await ref.read(invoicesListProvider.notifier).togglePaid(invoice.id, value);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(value ? 'Marked as paid' : 'Marked as unpaid')),
                );
              }
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final bytes = await PdfService.generateInvoicePdf(invoice);
                    await Printing.sharePdf(bytes: bytes, filename: 'Invoice-${invoice.id}.pdf');
                  },
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Share PDF'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                  onPressed: () => PdfService.shareInvoiceToWhatsapp(invoice),
                  icon: const Icon(Icons.share, color: Colors.white),
                  label: const Text('WhatsApp', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(
            value,
            style: TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.w500, fontSize: bold ? 16 : 14),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete invoice?'),
        content: Text('This will permanently remove invoice ${invoice.id}. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref.read(invoicesListProvider.notifier).delete(invoice.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
