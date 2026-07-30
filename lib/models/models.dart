/// Enum to distinguish billing types specifically needed for Contractors/Electricians.
enum ItemType { labor, material }

/// Enum to distinguish the three kinds of stock ledger entries (feature 001).
/// `adjustment` is a direct set of on-hand quantity (correcting a physical
/// count), kept distinct from ordinary `restock`/`reduction` movements so the
/// history reads clearly (FR-008).
enum StockMovementType { restock, reduction, adjustment }

/// Enum to map standard Kenyan KRA VAT categories.
enum VatCategory {
  standard16, // 16% VAT
  zeroRated,  // 0% VAT
  exempt      // Exempt from VAT
}

/// Enum to specify the target M-Pesa receiving channel.
enum MpesaType { tillNumber, paybill }

/// Effective payment status of an invoice, derived from isPaid + dueDate.
enum InvoiceStatus { paid, unpaid, overdue }

// ==========================================
// 1. PAYMENT DETAILS MODEL
// ==========================================
class PaymentDetails {
  final MpesaType mpesaType;
  final String mpesaNumber; // 5-6 digit Till or Paybill number
  final String? accountName; // Required if mpesaType is paybill (e.g., "PROJ-001")

  PaymentDetails({
    required this.mpesaType,
    required this.mpesaNumber,
    this.accountName,
  }) {
    _validate();
  }

  void _validate() {
    final mpesaRegExp = RegExp(r'^\d{5,6}$');
    if (!mpesaRegExp.hasMatch(mpesaNumber)) {
      throw ArgumentError('M-Pesa Till/Paybill must be a 5 or 6 digit number.');
    }
    if (mpesaType == MpesaType.paybill && (accountName == null || accountName!.trim().isEmpty)) {
      throw ArgumentError('Account name/number is required for M-Pesa Paybill transfers.');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'mpesaType': mpesaType.name,
      'mpesaNumber': mpesaNumber,
      'accountName': accountName,
    };
  }

  factory PaymentDetails.fromJson(Map<String, dynamic> json) {
    return PaymentDetails(
      mpesaType: MpesaType.values.byName(json['mpesaType'] as String),
      mpesaNumber: json['mpesaNumber'] as String,
      accountName: json['accountName'] as String?,
    );
  }
}

// ==========================================
// 2. CLIENT MODEL
// ==========================================
class Client {
  final String id;
  final String fullName;
  final String phoneNumber; // Validated Kenyan Format (+254, 07, 01)
  final String? kraPin;     // Optional, validated 11-character tax PIN
  final String? email;

  Client({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    this.kraPin,
    this.email,
  }) {
    _validate();
  }

  void _validate() {
    // Validates: +2547..., +2541..., 07..., 01... matching Kenyan telco standards
    final kePhoneRegExp = RegExp(r'^(?:\+254|0)[71]\d{8}$');
    if (!kePhoneRegExp.hasMatch(phoneNumber)) {
      throw ArgumentError('Invalid Kenyan phone number format. Use 07..., 01..., or +254...');
    }

    // Validates KRA PIN format: 11 characters, starts with A/P/etc, 9 digits, ends with a letter
    if (kraPin != null && kraPin!.isNotEmpty) {
      final kraRegExp = RegExp(r'^[A-Za-z]\d{9}[A-Za-z]$');
      if (!kraRegExp.hasMatch(kraPin!)) {
        throw ArgumentError('Invalid KRA PIN format. Expected format like A123456789B.');
      }
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'kraPin': kraPin,
      'email': email,
    };
  }

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      phoneNumber: json['phoneNumber'] as String,
      kraPin: json['kraPin'] as String?,
      email: json['email'] as String?,
    );
  }
}

// ==========================================
// 3. INVOICE ITEM MODEL
// ==========================================
class InvoiceItem {
  final String description;
  final ItemType type;        // Labor vs. Material
  final double quantity;      // Supports decimals (e.g., 2.5 hours of labor or 10.5 meters of cable)
  final double unitPrice;     // Price in KES
  final VatCategory vatCategory;

  InvoiceItem({
    required this.description,
    required this.type,
    required this.quantity,
    required this.unitPrice,
    this.vatCategory = VatCategory.exempt, // Defaulting to exempt for informal sector flexibility
  });

  /// Calculates baseline subtotal before statutory taxation
  double get subtotal => quantity * unitPrice;

  /// Calculates dynamic tax components in KES based on KRA regulations
  double get vatAmount {
    switch (vatCategory) {
      case VatCategory.standard16:
        return subtotal * 0.16;
      case VatCategory.zeroRated:
      case VatCategory.exempt:
        return 0.0;
    }
  }

  /// Total cost of item line inclusive of tax components
  double get totalWithVat => subtotal + vatAmount;

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'type': type.name,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'vatCategory': vatCategory.name,
    };
  }

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      description: json['description'] as String,
      type: ItemType.values.byName(json['type'] as String),
      quantity: (json['quantity'] as num).toDouble(),
      unitPrice: (json['unitPrice'] as num).toDouble(),
      vatCategory: VatCategory.values.byName(json['vatCategory'] as String),
    );
  }
}

// ==========================================
// 4. INVOICE CONTAINER MODEL
// ==========================================
class Invoice {
  final String id;
  final Client client;
  final List<InvoiceItem> items;
  final DateTime issueDate;
  final DateTime dueDate;
  final PaymentDetails paymentDetails;

  // Future-proofing eTIMS hooks directly inside core architecture
  final String? etimsInvoiceNumber;
  final bool isEtimsValidated;

  /// Whether the client has settled this invoice. Defaults to false (unpaid) on creation.
  final bool isPaid;

  Invoice({
    required this.id,
    required this.client,
    required this.items,
    required this.issueDate,
    required this.dueDate,
    required this.paymentDetails,
    this.etimsInvoiceNumber,
    this.isEtimsValidated = false,
    this.isPaid = false,
  });

  /// Derives the effective display status of the invoice.
  InvoiceStatus get status {
    if (isPaid) return InvoiceStatus.paid;
    if (dueDate.isBefore(DateTime.now())) return InvoiceStatus.overdue;
    return InvoiceStatus.unpaid;
  }

  Invoice copyWith({
    String? id,
    Client? client,
    List<InvoiceItem>? items,
    DateTime? issueDate,
    DateTime? dueDate,
    PaymentDetails? paymentDetails,
    String? etimsInvoiceNumber,
    bool? isEtimsValidated,
    bool? isPaid,
  }) {
    return Invoice(
      id: id ?? this.id,
      client: client ?? this.client,
      items: items ?? this.items,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      paymentDetails: paymentDetails ?? this.paymentDetails,
      etimsInvoiceNumber: etimsInvoiceNumber ?? this.etimsInvoiceNumber,
      isEtimsValidated: isEtimsValidated ?? this.isEtimsValidated,
      isPaid: isPaid ?? this.isPaid,
    );
  }

  /// Computes cumulative subtotal across all line items in KES
  double get totalSubtotal => items.fold(0.0, (sum, item) => sum + item.subtotal);

  /// Computes collective KRA VAT obligation in KES
  double get totalVat => items.fold(0.0, (sum, item) => sum + item.vatAmount);

  /// Grand Total payable by client in KES (Gross Amount)
  double get grandTotal => totalSubtotal + totalVat;

  /// Clean helper to format phone numbers into international E.164 syntax ready for M-Pesa API STK push
  String get mpesaFormattedPhone {
    String phone = client.phoneNumber.replaceAll(' ', '');
    if (phone.startsWith('0')) {
      return '254${phone.substring(1)}';
    } else if (phone.startsWith('+254')) {
      return phone.substring(1);
    }
    return phone;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client': client.toJson(),
      'items': items.map((e) => e.toJson()).toList(),
      'issueDate': issueDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'paymentDetails': paymentDetails.toJson(),
      'etimsInvoiceNumber': etimsInvoiceNumber,
      'isEtimsValidated': isEtimsValidated,
      'isPaid': isPaid,
    };
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] as String,
      client: Client.fromJson(json['client'] as Map<String, dynamic>),
      items: (json['items'] as List<dynamic>)
          .map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      issueDate: DateTime.parse(json['issueDate'] as String),
      dueDate: DateTime.parse(json['dueDate'] as String),
      paymentDetails: PaymentDetails.fromJson(json['paymentDetails'] as Map<String, dynamic>),
      etimsInvoiceNumber: json['etimsInvoiceNumber'] as String?,
      isEtimsValidated: json['isEtimsValidated'] as bool? ?? false,
      isPaid: json['isPaid'] as bool? ?? false,
    );
  }
}

// ==========================================
// 5. PRODUCT MODEL (Feature 001 — Products & Inventory)
// ==========================================
class Product {
  final String id;
  final String name;
  final String? sku; // optional, unique across the catalog when present (FR-003)
  final String unit; // free text, e.g. "pcs", "kg", "litre"
  final double costPrice;
  final double sellingPrice;
  final VatCategory vatCategory;
  final String category; // free text tag, used for filtering (FR-005)
  final int? reorderThreshold; // optional; null = never flagged low-stock (FR-012)

  /// Derived/cached on-hand quantity — always equal to the `resultingOnHand`
  /// of this product's most recent [StockMovement], or 0 if none exist yet.
  /// Not directly editable from the product form; only [StorageService]'s
  /// stock-movement recording path is allowed to change it (see data-model.md
  /// invariants).
  final int onHandQuantity;

  Product({
    required this.id,
    required this.name,
    this.sku,
    required this.unit,
    required this.costPrice,
    required this.sellingPrice,
    this.vatCategory = VatCategory.exempt,
    this.category = '',
    this.reorderThreshold,
    this.onHandQuantity = 0,
  }) {
    _validate();
  }

  void _validate() {
    if (name.trim().isEmpty) {
      throw ArgumentError('Product name is required.');
    }
    if (unit.trim().isEmpty) {
      throw ArgumentError('Product unit is required (e.g. "pcs", "kg", "litre").');
    }
    if (costPrice < 0) {
      throw ArgumentError('Cost price cannot be negative.');
    }
    if (sellingPrice < 0) {
      throw ArgumentError('Selling price cannot be negative.');
    }
    if (reorderThreshold != null && reorderThreshold! < 0) {
      throw ArgumentError('Reorder threshold cannot be negative.');
    }
  }

  /// Whether this product is flagged low-stock per FR-012. Always false when
  /// no reorder threshold has been configured.
  bool get isLowStock => reorderThreshold != null && onHandQuantity <= reorderThreshold!;

  /// This product's contribution to total inventory valuation (FR-013).
  double get stockValue => onHandQuantity * costPrice;

  Product copyWith({
    String? id,
    String? name,
    String? sku,
    bool clearSku = false,
    String? unit,
    double? costPrice,
    double? sellingPrice,
    VatCategory? vatCategory,
    String? category,
    int? reorderThreshold,
    bool clearReorderThreshold = false,
    int? onHandQuantity,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: clearSku ? null : (sku ?? this.sku),
      unit: unit ?? this.unit,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      vatCategory: vatCategory ?? this.vatCategory,
      category: category ?? this.category,
      reorderThreshold: clearReorderThreshold ? null : (reorderThreshold ?? this.reorderThreshold),
      onHandQuantity: onHandQuantity ?? this.onHandQuantity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'unit': unit,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'vatCategory': vatCategory.name,
      'category': category,
      'reorderThreshold': reorderThreshold,
      'onHandQuantity': onHandQuantity,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      sku: json['sku'] as String?,
      unit: json['unit'] as String,
      costPrice: (json['costPrice'] as num).toDouble(),
      sellingPrice: (json['sellingPrice'] as num).toDouble(),
      vatCategory: VatCategory.values.byName(json['vatCategory'] as String),
      category: json['category'] as String? ?? '',
      reorderThreshold: json['reorderThreshold'] as int?,
      onHandQuantity: json['onHandQuantity'] as int? ?? 0,
    );
  }
}

/// FR-003: Returns the existing product that conflicts on SKU with
/// [candidate], or null if there is no conflict. A product is never
/// considered to conflict with itself (matched by [Product.id]), which is
/// what makes editing a product's own SKU possible. Blank/null SKUs never
/// conflict — SKU is optional and only enforced unique when present.
///
/// Kept as a standalone pure function (rather than inline in the storage
/// layer) so the conflict rule itself is unit-testable without touching Isar.
Product? findProductSkuConflict(List<Product> existingProducts, Product candidate) {
  final candidateSku = candidate.sku?.trim();
  if (candidateSku == null || candidateSku.isEmpty) return null;

  for (final existing in existingProducts) {
    if (existing.id == candidate.id) continue;
    final existingSku = existing.sku?.trim();
    if (existingSku != null && existingSku.isNotEmpty && existingSku.toLowerCase() == candidateSku.toLowerCase()) {
      return existing;
    }
  }
  return null;
}

// ==========================================
// 6. STOCK MOVEMENT MODEL (Feature 001 — Products & Inventory)
// ==========================================
class StockMovement {
  final String id;
  final String productId;
  final StockMovementType type;
  final int quantityDelta; // signed for restock/reduction; for adjustment, the delta implied by the new total
  final int resultingOnHand; // on-hand immediately after this movement — makes history self-verifying (SC-003)
  final String? note;
  final DateTime timestamp;

  StockMovement({
    required this.id,
    required this.productId,
    required this.type,
    required this.quantityDelta,
    required this.resultingOnHand,
    this.note,
    required this.timestamp,
  }) {
    if (resultingOnHand < 0) {
      throw ArgumentError('Resulting on-hand quantity cannot be negative once confirmed.');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'type': type.name,
      'quantityDelta': quantityDelta,
      'resultingOnHand': resultingOnHand,
      'note': note,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory StockMovement.fromJson(Map<String, dynamic> json) {
    return StockMovement(
      id: json['id'] as String,
      productId: json['productId'] as String,
      type: StockMovementType.values.byName(json['type'] as String),
      quantityDelta: json['quantityDelta'] as int,
      resultingOnHand: json['resultingOnHand'] as int,
      note: json['note'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
