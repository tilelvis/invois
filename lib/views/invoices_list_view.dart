import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/invoices_list_provider.dart';
import '../services/pdf_service.dart';
import '../widgets/app_design_system.dart';
import '../widgets/empty_state.dart';
import '../widgets/invoice_action_sheet.dart';
import '../widgets/shimmer_loading.dart';
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
          // Floating rounded search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(28),
              shadowColor: Colors.black26,
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
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
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
                loading: () => const InvoiceListSkeleton(),
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

                  if (invoices.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 40),
                        EmptyStateView(
                          icon: Icons.receipt_long_outlined,
                          title: 'No invoices yet',
                          message: 'Invoices you save from the New tab will show up here.',
                        ),
                      ],
                    );
                  }

                  if (filtered.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 40),
                        EmptyStateView(
                          icon: Icons.search_off,
                          title: 'No matches',
                          message: 'Try a different search term or filter.',
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final invoice = filtered[index];
                      final isPaid = invoice.status == InvoiceStatus.paid;
                      final brightness = Theme.of(context).brightness;

                      return Dismissible(
                        key: ValueKey(invoice.id),
                        direction: DismissDirection.horizontal,
                        background: Container(
                          color: AppColors.success(brightness),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 20),
                          child: Row(
                            children: [
                              Icon(isPaid ? Icons.undo : Icons.check_circle, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(isPaid ? 'Mark unpaid' : 'Mark paid', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        secondaryBackground: Container(
                          color: AppColors.danger(brightness),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            // Swipe right = toggle paid status; snap back, don't remove the tile.
                            await ref.read(invoicesListProvider.notifier).togglePaid(invoice.id, !isPaid);
                            return false;
                          }
                          return _confirmDelete(context);
                        },
                        onDismissed: (direction) {
                          if (direction == DismissDirection.endToStart) {
                            _deleteWithUndo(context, invoice);
                          }
                        },
                        child: ListTile(
                          onLongPress: () => showInvoiceActionSheet(
                            context: context,
                            invoice: invoice,
                            onTogglePaid: (paid) => ref.read(invoicesListProvider.notifier).togglePaid(invoice.id, paid),
                            onDelete: () async => _deleteWithUndo(context, invoice),
                          ),
                          title: Text(invoice.client.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            '${invoice.id} · ${PdfService.dateFormatter.format(invoice.issueDate)}',
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Hero(
                                tag: 'invoice-amount-${invoice.id}',
                                child: Material(
                                  type: MaterialType.transparency,
                                  child: Text(
                                    PdfService.currencyFormatter.format(invoice.grandTotal),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
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

  Future<bool> _confirmDelete(BuildContext context) async {
    final danger = AppColors.danger(Theme.of(context).brightness);
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete invoice?'),
        content: const Text('You can undo this from the snackbar right after.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Delete', style: TextStyle(color: danger)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _deleteWithUndo(BuildContext context, Invoice invoice) {
    ref.read(invoicesListProvider.notifier).delete(invoice.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted invoice for ${invoice.client.fullName}'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () => ref.read(invoicesListProvider.notifier).restore(invoice),
        ),
      ),
    );
  }
}
