import 'package:isar/isar.dart';

part 'stored_invoice.g.dart';

@collection
class StoredInvoice {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String invoiceId;

  late String clientName;
  late String date;
  late double grandTotal;
  late String rawJson;
}
