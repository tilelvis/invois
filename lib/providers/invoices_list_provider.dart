import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/storage_service.dart';

/// Holds the full set of invoices persisted in Isar, plus loading state.
/// Screens (Dashboard, Invoices list, Clients) all read from this single
/// source of truth so that saving/deleting/marking-paid in one place is
/// reflected everywhere else immediately.
class InvoicesListNotifier extends StateNotifier<AsyncValue<List<Invoice>>> {
  InvoicesListNotifier() : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      if (!StorageService.isInitialized) {
        await StorageService.init();
      }
      final invoices = await StorageService.getAllInvoices();
      state = AsyncValue.data(invoices);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> togglePaid(String invoiceId, bool isPaid) async {
    await StorageService.setInvoicePaid(invoiceId, isPaid);
    await refresh();
  }

  Future<void> delete(String invoiceId) async {
    await StorageService.deleteInvoice(invoiceId);
    await refresh();
  }
}

final invoicesListProvider =
    StateNotifierProvider<InvoicesListNotifier, AsyncValue<List<Invoice>>>((ref) {
  return InvoicesListNotifier();
});
