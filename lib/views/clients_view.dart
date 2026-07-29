import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/invoices_list_provider.dart';
import '../services/pdf_service.dart';
import '../widgets/app_design_system.dart';
import '../widgets/empty_state.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/status_badge.dart';
import 'invoice_detail_view.dart';

class ClientsView extends ConsumerWidget {
  const ClientsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(invoicesListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Clients')),
      body: invoicesAsync.when(
        loading: () => const InvoiceListSkeleton(),
        error: (err, _) => Center(child: Text('Could not load clients: $err')),
        data: (invoices) {
          // Group invoices by client phone number (unique per client).
          final Map<String, List<Invoice>> byClient = {};
          for (final inv in invoices) {
            byClient.putIfAbsent(inv.client.phoneNumber, () => []).add(inv);
          }

          if (byClient.isEmpty) {
            return const EmptyStateView(
              icon: Icons.people_outline,
              title: 'No clients yet',
              message: 'Clients appear here once you save an invoice for them.',
            );
          }

          final clientEntries = byClient.entries.toList()
            ..sort((a, b) => a.value.first.client.fullName.compareTo(b.value.first.client.fullName));

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: clientEntries.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final entry = clientEntries[index];
              final clientInvoices = entry.value;
              final client = clientInvoices.first.client;
              final totalBilled = clientInvoices.fold<double>(0, (sum, i) => sum + i.grandTotal);
              final outstandingCount = clientInvoices.where((i) => i.status != InvoiceStatus.paid).length;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Text(
                    client.fullName.isNotEmpty ? client.fullName[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(client.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${client.phoneNumber} · ${clientInvoices.length} invoice(s)'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(PdfService.currencyFormatter.format(totalBilled),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (outstandingCount > 0)
                      Text(
                        '$outstandingCount unpaid',
                        style: TextStyle(fontSize: 11, color: AppColors.danger(Theme.of(context).brightness)),
                      ),
                  ],
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _ClientHistoryView(client: client, invoices: clientInvoices),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ClientHistoryView extends StatelessWidget {
  final Client client;
  final List<Invoice> invoices;
  const _ClientHistoryView({required this.client, required this.invoices});

  @override
  Widget build(BuildContext context) {
    final sorted = [...invoices]..sort((a, b) => b.issueDate.compareTo(a.issueDate));
    return Scaffold(
      appBar: AppBar(title: Text(client.fullName)),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: sorted.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final invoice = sorted[index];
          return ListTile(
            title: Text(invoice.id),
            subtitle: Text(PdfService.dateFormatter.format(invoice.issueDate)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(PdfService.currencyFormatter.format(invoice.grandTotal),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                StatusBadge(status: invoice.status),
              ],
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => InvoiceDetailView(invoice: invoice)),
            ),
          );
        },
      ),
    );
  }
}
