import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/invoices_list_provider.dart';
import '../services/pdf_service.dart';
import '../widgets/status_badge.dart';
import 'invoice_detail_view.dart';

/// null in the filter set means "All".
class InvoicesListView extends ConsumerStatefulWidget {
  const InvoicesListView({super.key});

  @override
  ConsumerState<InvoicesListView> createState() => _InvoicesListViewState();
}

class _InvoicesListViewState extends ConsumerState<InvoicesListView> {
  final _searchController = TextEditingController();
  String _query = '';
  InvoiceStatus? _statusFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(invoicesListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Invoices')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by client name or invoice ID',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('All', null),
                  _filterChip('Unpaid', InvoiceStatus.unpaid),
                  _filterChip('Paid', InvoiceStatus.paid),
                  _filterChip('Overdue', InvoiceStatus.overdue),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(invoicesListProvider.notifier).refresh(),
              child: invoicesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Could not load invoices: $err')),
                data: (invoices) {
                  final filtered = invoices.where((inv) {
                    final matchesStatus = _statusFilter == null || inv.status == _statusFilter;
                    final q = _query.trim().toLowerCase();
                    final matchesQuery = q.isEmpty ||
                        inv.client.fullName.toLowerCase().contains(q) ||
                        inv.id.toLowerCase().contains(q);
                    return matchesStatus && matchesQuery;
                  }).toList();

                  if (filtered.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 100),
                        Center(child: Text('No matching invoices.', style: TextStyle(color: Colors.black54))),
                      ],
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final invoice = filtered[index];
                      return Dismissible(
                        key: ValueKey(invoice.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red[700],
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (_) => _confirmDismiss(context),
                        onDismissed: (_) =>
                            ref.read(invoicesListProvider.notifier).delete(invoice.id),
                        child: ListTile(
                          title: Text(invoice.client.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            '${invoice.id} · ${PdfService.dateFormatter.format(invoice.issueDate)}',
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                PdfService.currencyFormatter.format(invoice.grandTotal),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              StatusBadge(status: invoice.status),
                            ],
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => InvoiceDetailView(invoice: invoice)),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, InvoiceStatus? status) {
    final selected = _statusFilter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _statusFilter = status),
      ),
    );
  }

  Future<bool> _confirmDismiss(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete invoice?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
