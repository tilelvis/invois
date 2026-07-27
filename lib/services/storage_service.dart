import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';
import '../models/stored_invoice.dart';

class StorageService {
  static Isar? _isar;

  /// Initializes the Isar offline database.
  static Future<void> init() async {
    if (_isar != null) return;

    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [StoredInvoiceSchema],
      directory: dir.path,
    );
  }

  /// Saves a localized Invoice to Isar storage offline.
  static Future<void> saveInvoice(Invoice invoice) async {
    final isar = _isar;
    if (isar == null) throw StateError('Isar database is not initialized. Call init() first.');

    final jsonStr = jsonEncode(invoice.toJson());
    final stored = StoredInvoice()
      ..invoiceId = invoice.id
      ..clientName = invoice.client.fullName
      ..date = invoice.issueDate.toIso8601String()
      ..grandTotal = invoice.grandTotal
      ..rawJson = jsonStr;

    await isar.writeTxn(() async {
      await isar.storedInvoices.putByInvoiceId(stored);
    });
  }

  /// Lists all previously saved Invoices offline.
  static Future<List<Invoice>> getAllInvoices() async {
    final isar = _isar;
    if (isar == null) throw StateError('Isar database is not initialized. Call init() first.');

    final storedList = await isar.storedInvoices.where().sortByDateDesc().findAll();
    return storedList.map((stored) {
      final decodedMap = jsonDecode(stored.rawJson) as Map<String, dynamic>;
      return Invoice.fromJson(decodedMap);
    }).toList();
  }

  /// Retrieves a specific Invoice by its ID.
  static Future<Invoice?> getInvoice(String invoiceId) async {
    final isar = _isar;
    if (isar == null) throw StateError('Isar database is not initialized. Call init() first.');

    final stored = await isar.storedInvoices.getByInvoiceId(invoiceId);
    if (stored == null) return null;

    final decodedMap = jsonDecode(stored.rawJson) as Map<String, dynamic>;
    return Invoice.fromJson(decodedMap);
  }

  /// Deletes a specific Invoice from storage.
  static Future<void> deleteInvoice(String invoiceId) async {
    final isar = _isar;
    if (isar == null) throw StateError('Isar database is not initialized. Call init() first.');

    await isar.writeTxn(() async {
      await isar.storedInvoices.deleteByInvoiceId(invoiceId);
    });
  }

  /// Closes the Isar database. Only used for testing or cleaning resources.
  static Future<void> close() async {
    final isar = _isar;
    if (isar != null) {
      await isar.close();
      _isar = null;
    }
  }

  /// Checks if initialized
  static bool get isInitialized => _isar != null;
}
