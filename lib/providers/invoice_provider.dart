import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

class InvoiceState {
  final String id;
  final Client? client;
  final List<InvoiceItem> items;
  final DateTime issueDate;
  final DateTime dueDate;
  final PaymentDetails? paymentDetails;
  final String? etimsInvoiceNumber;
  final bool isEtimsValidated;

  InvoiceState({
    required this.id,
    this.client,
    this.items = const [],
    required this.issueDate,
    required this.dueDate,
    this.paymentDetails,
    this.etimsInvoiceNumber,
    this.isEtimsValidated = false,
  });

  InvoiceState copyWith({
    String? id,
    Client? client,
    List<InvoiceItem>? items,
    DateTime? issueDate,
    DateTime? dueDate,
    PaymentDetails? paymentDetails,
    String? etimsInvoiceNumber,
    bool? isEtimsValidated,
  }) {
    return InvoiceState(
      id: id ?? this.id,
      client: client ?? this.client,
      items: items ?? this.items,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      paymentDetails: paymentDetails ?? this.paymentDetails,
      etimsInvoiceNumber: etimsInvoiceNumber ?? this.etimsInvoiceNumber,
      isEtimsValidated: isEtimsValidated ?? this.isEtimsValidated,
    );
  }

  double get totalSubtotal => items.fold(0.0, (sum, item) => sum + item.subtotal);
  double get totalVat => items.fold(0.0, (sum, item) => sum + item.vatAmount);
  double get grandTotal => totalSubtotal + totalVat;

  bool get isValid {
    return client != null && paymentDetails != null && items.isNotEmpty;
  }

  Invoice toInvoice() {
    if (!isValid) {
      throw StateError('Cannot build invoice: missing client, payment details, or items.');
    }
    return Invoice(
      id: id,
      client: client!,
      items: items,
      issueDate: issueDate,
      dueDate: dueDate,
      paymentDetails: paymentDetails!,
      etimsInvoiceNumber: etimsInvoiceNumber,
      isEtimsValidated: isEtimsValidated,
    );
  }
}

class InvoiceNotifier extends StateNotifier<InvoiceState> {
  InvoiceNotifier()
      : super(InvoiceState(
          id: 'INV-${const Uuid().v4().substring(0, 8).toUpperCase()}',
          issueDate: DateTime.now(),
          dueDate: DateTime.now().add(const Duration(days: 7)),
        ));

  void reset() {
    state = InvoiceState(
      id: 'INV-${const Uuid().v4().substring(0, 8).toUpperCase()}',
      issueDate: DateTime.now(),
      dueDate: DateTime.now().add(const Duration(days: 7)),
    );
  }

  void updateClient(Client client) {
    state = state.copyWith(client: client);
  }

  void clearClient() {
    state = InvoiceState(
      id: state.id,
      items: state.items,
      issueDate: state.issueDate,
      dueDate: state.dueDate,
      paymentDetails: state.paymentDetails,
      etimsInvoiceNumber: state.etimsInvoiceNumber,
      isEtimsValidated: state.isEtimsValidated,
    );
  }

  void updatePaymentDetails(PaymentDetails paymentDetails) {
    state = state.copyWith(paymentDetails: paymentDetails);
  }

  void clearPaymentDetails() {
    state = InvoiceState(
      id: state.id,
      client: state.client,
      items: state.items,
      issueDate: state.issueDate,
      dueDate: state.dueDate,
      etimsInvoiceNumber: state.etimsInvoiceNumber,
      isEtimsValidated: state.isEtimsValidated,
    );
  }

  void addItem(InvoiceItem item) {
    state = state.copyWith(items: [...state.items, item]);
  }

  void updateItem(int index, InvoiceItem updatedItem) {
    if (index >= 0 && index < state.items.length) {
      final newItems = List<InvoiceItem>.from(state.items);
      newItems[index] = updatedItem;
      state = state.copyWith(items: newItems);
    }
  }

  void removeItem(int index) {
    if (index >= 0 && index < state.items.length) {
      final newItems = List<InvoiceItem>.from(state.items)..removeAt(index);
      state = state.copyWith(items: newItems);
    }
  }

  void updateDates(DateTime issueDate, DateTime dueDate) {
    state = state.copyWith(issueDate: issueDate, dueDate: dueDate);
  }

  void updateEtims({String? invoiceNumber, bool isValidated = false}) {
    state = state.copyWith(
      etimsInvoiceNumber: invoiceNumber,
      isEtimsValidated: isValidated,
    );
  }
}

final invoiceProvider = StateNotifierProvider<InvoiceNotifier, InvoiceState>((ref) {
  return InvoiceNotifier();
});
