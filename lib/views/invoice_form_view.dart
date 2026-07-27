import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../models/models.dart';
import '../providers/invoice_provider.dart';
import '../providers/invoices_list_provider.dart';
import '../services/pdf_service.dart';
import '../services/storage_service.dart';

class InvoiceFormView extends ConsumerStatefulWidget {
  const InvoiceFormView({super.key});

  @override
  ConsumerState<InvoiceFormView> createState() => _InvoiceFormViewState();
}

class _InvoiceFormViewState extends ConsumerState<InvoiceFormView> {
  final _formKey = GlobalKey<FormState>();
  final _clientNameController = TextEditingController();
  final _clientPhoneController = TextEditingController();
  final _clientPinController = TextEditingController();
  final _clientEmailController = TextEditingController();

  final _mpesaNumberController = TextEditingController();
  final _mpesaAccountController = TextEditingController();
  MpesaType _mpesaType = MpesaType.tillNumber;

  final currencyFormatter = NumberFormat.currency(locale: 'en_KE', symbol: 'KES ');

  @override
  void dispose() {
    _clientNameController.dispose();
    _clientPhoneController.dispose();
    _clientPinController.dispose();
    _clientEmailController.dispose();
    _mpesaNumberController.dispose();
    _mpesaAccountController.dispose();
    super.dispose();
  }

  void _clearFormFields() {
    _clientNameController.clear();
    _clientPhoneController.clear();
    _clientPinController.clear();
    _clientEmailController.clear();
    _mpesaNumberController.clear();
    _mpesaAccountController.clear();
  }

  Future<void> _saveInvoice(InvoiceState state) async {
    try {
      if (!StorageService.isInitialized) {
        await StorageService.init();
      }
      await StorageService.saveInvoice(state.toInvoice());
      // Keep the Dashboard/Invoices/Clients tabs in sync immediately.
      ref.read(invoicesListProvider.notifier).refresh();
      ref.read(invoiceProvider.notifier).reset();
      _clearFormFields();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invoice saved. Find it under the Invoices tab.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save invoice: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return const AddItemDialog();
      },
    );
  }

  void _simulateMpesaStkPush(InvoiceState invoiceState) async {
    if (invoiceState.client == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add client details first to trigger STK Push.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final formattedPhone = invoiceState.toInvoice().mpesaFormattedPhone;
    final grandTotal = invoiceState.grandTotal;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return MpesaSimulationSheet(
          phoneNumber: formattedPhone,
          amount: grandTotal,
          onComplete: () {
            ref.read(invoiceProvider.notifier).updateEtims(
              invoiceNumber: 'ETIMS-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
              isValidated: true,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final invoiceState = ref.watch(invoiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'JULES KENYA INVOICER',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF005A36), // Trusted Deep Safaricom Green
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              ref.read(invoiceProvider.notifier).reset();
              _clientNameController.clear();
              _clientPhoneController.clear();
              _clientPinController.clear();
              _clientEmailController.clear();
              _mpesaNumberController.clear();
              _mpesaAccountController.clear();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invoice draft reset successfully.')),
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. CLIENT PROFILE CARD
              _buildSectionHeader('1. CLIENT PROFILE (Local Validations)'),
              _buildClientCard(invoiceState),
              const SizedBox(height: 20),

              // 2. PAYMENT DETAILS CARD
              _buildSectionHeader('2. M-PESA DISBURSEMENT GATEWAY'),
              _buildPaymentCard(invoiceState),
              const SizedBox(height: 20),

              // 3. LINE ITEMS SECTION
              _buildSectionHeader('3. BILLING LINE ITEMS (Labor vs Materials)'),
              _buildItemsSection(invoiceState),
              const SizedBox(height: 20),

              // 4. SUMMARY & ACTION PANEL
              _buildSummaryCard(invoiceState),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildClientCard(InvoiceState state) {
    final client = state.client;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (client == null) ...[
              const Icon(Icons.person_add_alt_1, size: 40, color: Color(0xFF005A36)),
              const SizedBox(height: 8),
              const Text(
                'No Client Info Added',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _showClientFormDialog(null),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005A36),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.add),
                label: const Text('Add Client Profile'),
              )
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.fullName.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Phone: ${client.phoneNumber}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        if (client.kraPin != null && client.kraPin!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'KRA PIN: ${client.kraPin!.toUpperCase()}',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                        if (client.email != null && client.email!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('Email: ${client.email}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        ]
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showClientFormDialog(client),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => ref.read(invoiceProvider.notifier).clearClient(),
                      ),
                    ],
                  )
                ],
              )
            ]
          ],
        ),
      ),
    );
  }

  void _showClientFormDialog(Client? existingClient) {
    if (existingClient != null) {
      _clientNameController.text = existingClient.fullName;
      _clientPhoneController.text = existingClient.phoneNumber;
      _clientPinController.text = existingClient.kraPin ?? '';
      _clientEmailController.text = existingClient.email ?? '';
    } else {
      _clientNameController.clear();
      _clientPhoneController.clear();
      _clientPinController.clear();
      _clientEmailController.clear();
    }

    final dialogFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(existingClient == null ? 'Add Client Profile' : 'Edit Client Profile'),
          content: SingleChildScrollView(
            child: Form(
              key: dialogFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _clientNameController,
                    decoration: const InputDecoration(labelText: 'Client Full Name *', prefixIcon: Icon(Icons.person)),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _clientPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'Kenyan Phone (07... / 01... / +254...) *',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Phone number is required';
                      final kePhoneRegExp = RegExp(r'^(?:\+254|0)[71]\d{8}$');
                      if (!kePhoneRegExp.hasMatch(value.replaceAll(' ', ''))) {
                        return 'Invalid Kenyan number. Use 07..., 01... or +254...';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _clientPinController,
                    decoration: const InputDecoration(
                      labelText: 'Optional KRA PIN (e.g. A123456789B)',
                      prefixIcon: Icon(Icons.assignment),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      final kraRegExp = RegExp(r'^[A-Za-z]\d{9}[A-Za-z]$');
                      if (!kraRegExp.hasMatch(value.trim())) {
                        return 'Invalid KRA PIN format (e.g., A123456789B)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _clientEmailController,
                    decoration: const InputDecoration(labelText: 'Optional Email', prefixIcon: Icon(Icons.email)),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (dialogFormKey.currentState!.validate()) {
                  final client = Client(
                    id: existingClient?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                    fullName: _clientNameController.text.trim(),
                    phoneNumber: _clientPhoneController.text.trim(),
                    kraPin: _clientPinController.text.trim().isEmpty ? null : _clientPinController.text.toUpperCase().trim(),
                    email: _clientEmailController.text.trim().isEmpty ? null : _clientEmailController.text.trim(),
                  );
                  ref.read(invoiceProvider.notifier).updateClient(client);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF005A36)),
              child: const Text('Save Profile', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPaymentCard(InvoiceState state) {
    final payment = state.paymentDetails;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (payment == null) ...[
              const Icon(Icons.account_balance_wallet_outlined, size: 40, color: Color(0xFF005A36)),
              const SizedBox(height: 8),
              const Text(
                'No Payment Channels Saved',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _showPaymentFormDialog(null),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005A36),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.add),
                label: const Text('Configure Lipa Na M-Pesa'),
              )
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payment.mpesaType == MpesaType.paybill ? 'M-PESA PAYBILL' : 'M-PESA TILL NUMBER (LIPA NA M-PESA)',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF005A36)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Number: ${payment.mpesaNumber}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        if (payment.mpesaType == MpesaType.paybill && payment.accountName != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Account: ${payment.accountName}',
                            style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold),
                          ),
                        ]
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showPaymentFormDialog(payment),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => ref.read(invoiceProvider.notifier).clearPaymentDetails(),
                      ),
                    ],
                  )
                ],
              )
            ]
          ],
        ),
      ),
    );
  }

  void _showPaymentFormDialog(PaymentDetails? existingPayment) {
    if (existingPayment != null) {
      _mpesaNumberController.text = existingPayment.mpesaNumber;
      _mpesaAccountController.text = existingPayment.accountName ?? '';
      _mpesaType = existingPayment.mpesaType;
    } else {
      _mpesaNumberController.clear();
      _mpesaAccountController.clear();
      _mpesaType = MpesaType.tillNumber;
    }

    final dialogFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Configure Lipa Na M-Pesa'),
              content: Form(
                key: dialogFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<MpesaType>(
                            title: const Text('Till', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            value: MpesaType.tillNumber,
                            groupValue: _mpesaType,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) => setState(() => _mpesaType = val!),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<MpesaType>(
                            title: const Text('Paybill', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            value: MpesaType.paybill,
                            groupValue: _mpesaType,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) => setState(() => _mpesaType = val!),
                          ),
                        ),
                      ],
                    ),
                    TextFormField(
                      controller: _mpesaNumberController,
                      decoration: InputDecoration(
                        labelText: _mpesaType == MpesaType.paybill ? 'Paybill Number (5-6 digits) *' : 'Till Number (5-6 digits) *',
                        prefixIcon: const Icon(Icons.phone_android),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Required';
                        if (!RegExp(r'^\d{5,6}$').hasMatch(value)) {
                          return 'Must be exactly 5 or 6 digits';
                        }
                        return null;
                      },
                    ),
                    if (_mpesaType == MpesaType.paybill) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _mpesaAccountController,
                        decoration: const InputDecoration(
                          labelText: 'Account Name/Number (e.g. Project Name) *',
                          prefixIcon: Icon(Icons.business_center),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Account is required for Paybills' : null,
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (dialogFormKey.currentState!.validate()) {
                      final payment = PaymentDetails(
                        mpesaType: _mpesaType,
                        mpesaNumber: _mpesaNumberController.text.trim(),
                        accountName: _mpesaType == MpesaType.paybill ? _mpesaAccountController.text.trim() : null,
                      );
                      ref.read(invoiceProvider.notifier).updatePaymentDetails(payment);
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF005A36)),
                  child: const Text('Save Gateway', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildItemsSection(InvoiceState state) {
    return Column(
      children: [
        if (state.items.isEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.format_list_bulleted, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'No services, labor hours, or materials added.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          )
        ] else ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = state.items[index];
              final isLabor = item.type == ItemType.labor;

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isLabor ? Colors.orange[100] : Colors.blue[100],
                    foregroundColor: isLabor ? Colors.orange[800] : Colors.blue[800],
                    child: Icon(isLabor ? Icons.engineering : Icons.plumbing),
                  ),
                  title: Text(
                    item.description,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    '${item.quantity} ${isLabor ? "Hrs" : "Units"} @ ${currencyFormatter.format(item.unitPrice)}\n'
                    'Sub: ${currencyFormatter.format(item.subtotal)} | VAT (${item.vatCategory == VatCategory.standard16 ? "16%" : item.vatCategory == VatCategory.zeroRated ? "0%" : "Exempt"}): ${currencyFormatter.format(item.vatAmount)}',
                    style: TextStyle(fontSize: 12, height: 1.4, color: Colors.grey[700]),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currencyFormatter.format(item.totalWithVat),
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => ref.read(invoiceProvider.notifier).removeItem(index),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        ],
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _showAddItemDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF005A36),
            side: const BorderSide(color: Color(0xFF005A36), width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Add Line Item (Labor / Material)', style: TextStyle(fontWeight: FontWeight.bold)),
        )
      ],
    );
  }

  Widget _buildSummaryCard(InvoiceState state) {
    return Card(
      elevation: 6,
      color: const Color(0xFF1E293B), // High glare friendly slate dark color
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('INVOICE REF:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                Text(
                  state.id,
                  style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 24),
            _buildSummaryRow('Line Subtotal:', currencyFormatter.format(state.totalSubtotal)),
            const SizedBox(height: 8),
            _buildSummaryRow('KRA VAT Total (16%):', currencyFormatter.format(state.totalVat)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'GRAND TOTAL (KES):',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                ),
                Text(
                  currencyFormatter.format(state.grandTotal),
                  style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w900, fontSize: 20),
                ),
              ],
            ),
            if (state.etimsInvoiceNumber != null) ...[
              const Divider(color: Colors.white24, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.verified, color: Colors.greenAccent, size: 18),
                      SizedBox(width: 4),
                      Text('eTIMS COMPLIANT', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w900, fontSize: 12)),
                    ],
                  ),
                  Text(
                    state.etimsInvoiceNumber!,
                    style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: state.isValid ? () => _simulateMpesaStkPush(state) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981), // Safaricom active green
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                disabledBackgroundColor: Colors.grey[700],
              ),
              icon: const Icon(Icons.bolt, size: 24),
              label: const Text(
                'TRIGGER M-PESA STK PUSH',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.0),
              ),
            ),
            if (state.isValid) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _saveInvoice(state),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF005A36),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.save_outlined, size: 20),
                label: const Text(
                  'SAVE INVOICE',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.0),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final pdfBytes = await PdfService.generateInvoicePdf(state.toInvoice());
                        await Printing.layoutPdf(
                          onLayout: (format) async => pdfBytes,
                          name: 'Invoice-${state.id}',
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.picture_as_pdf, size: 18),
                      label: const Text('PRINT PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await PdfService.shareInvoiceToWhatsapp(state.toInvoice());
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF10B981),
                        side: const BorderSide(color: Color(0xFF10B981)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text('WHATSAPP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}

// ==========================================
// QUICK-ADD LINE ITEM DIALOG
// ==========================================
class AddItemDialog extends ConsumerStatefulWidget {
  const AddItemDialog({super.key});

  @override
  ConsumerState<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends ConsumerState<AddItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _qtyController = TextEditingController();
  final _priceController = TextEditingController();

  ItemType _itemType = ItemType.labor;
  VatCategory _vatCategory = VatCategory.exempt;

  @override
  void dispose() {
    _descController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Add Invoice Line Item'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Segmented type selector
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('LABOR COSTS (Hrs)', style: TextStyle(fontWeight: FontWeight.bold)),
                      selected: _itemType == ItemType.labor,
                      onSelected: (val) {
                        if (val) setState(() => _itemType = ItemType.labor);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('MATERIALS (Qty)', style: TextStyle(fontWeight: FontWeight.bold)),
                      selected: _itemType == ItemType.material,
                      onSelected: (val) {
                        if (val) setState(() => _itemType = ItemType.material);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Item Description *',
                  hintText: 'e.g. Electric wiring per hr / PVC Pipes',
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _qtyController,
                      decoration: InputDecoration(
                        labelText: _itemType == ItemType.labor ? 'Hours (dec ok) *' : 'Quantity *',
                        prefixIcon: const Icon(Icons.pin),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Required';
                        final doubleVal = double.tryParse(value);
                        if (doubleVal == null || doubleVal <= 0) return 'Must be > 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Unit Price (KES) *',
                        prefixText: 'KES ',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Required';
                        final doubleVal = double.tryParse(value);
                        if (doubleVal == null || doubleVal <= 0) return 'Must be > 0';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Tax Toggle Title
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('KRA VAT Tax Code:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              DropdownButtonFormField<VatCategory>(
                initialValue: _vatCategory,
                items: const [
                  DropdownMenuItem(value: VatCategory.exempt, child: Text('Exempt (0% VAT - Informal)')),
                  DropdownMenuItem(value: VatCategory.standard16, child: Text('Standard VAT (16% KRA)')),
                  DropdownMenuItem(value: VatCategory.zeroRated, child: Text('Zero-Rated (0% KRA)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _vatCategory = val);
                },
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
              )
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final item = InvoiceItem(
                description: _descController.text.trim(),
                type: _itemType,
                quantity: double.parse(_qtyController.text),
                unitPrice: double.parse(_priceController.text),
                vatCategory: _vatCategory,
              );
              ref.read(invoiceProvider.notifier).addItem(item);
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF005A36)),
          child: const Text('Add Line', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

// ==========================================
// MPESA STK PUSH INTERACTIVE SIMULATION SHEET
// ==========================================
class MpesaSimulationSheet extends StatefulWidget {
  final String phoneNumber;
  final double amount;
  final VoidCallback onComplete;

  const MpesaSimulationSheet({
    super.key,
    required this.phoneNumber,
    required this.amount,
    required this.onComplete,
  });

  @override
  State<MpesaSimulationSheet> createState() => _MpesaSimulationSheetState();
}

class _MpesaSimulationSheetState extends State<MpesaSimulationSheet> {
  int _step = 0;
  String _statusMessage = 'Initializing STK Push pipeline...';

  final currencyFormatter = NumberFormat.currency(locale: 'en_KE', symbol: 'KES ');

  @override
  void initState() {
    super.initState();
    _startMpesaPipeline();
  }

  void _startMpesaPipeline() async {
    // Step 0: Initializing
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() {
      _step = 1;
      _statusMessage = 'Request dispatched to Safaricom Daraja API gateway...';
    });

    // Step 1: Broadcasting STK Push to Client Handset
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    setState(() {
      _step = 2;
      _statusMessage = 'STK Push pop-up sent to client handset ${widget.phoneNumber}.\nAwaiting client PIN entry...';
    });

    // Step 2: Customer Inputs Pin on phone
    await Future.delayed(const Duration(milliseconds: 3000));
    if (!mounted) return;
    setState(() {
      _step = 3;
      _statusMessage = 'PIN validated. Transferring KES ${currencyFormatter.format(widget.amount)}...';
    });

    // Step 3: Success Confirmation Callback from Safaricom callback URL
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() {
      _step = 4;
      _statusMessage = 'CONFIRMED! Received KES ${currencyFormatter.format(widget.amount)} from ${widget.phoneNumber}.\nReceipt ref: MP${DateTime.now().millisecondsSinceEpoch.toString().substring(4)}K';
    });

    // Notify parent to apply eTIMS validating values
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E293B), // High contrast slate dark
      padding: const EdgeInsets.all(24.0),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'LIPA NA M-PESA GATEWAY',
                  style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 16),
                ),
                if (_step < 4)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)),
                  )
                else
                  const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 24),
              ],
            ),
            const SizedBox(height: 24),
            _buildPipelineProgress(),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(13),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 24),
            if (_step == 4)
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('DISMISS & PRINT INVOICE', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPipelineProgress() {
    return Row(
      children: List.generate(4, (index) {
        final isActive = index <= _step;
        final isCompleted = index < _step;

        return Expanded(
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFF10B981)
                      : isActive
                          ? Colors.amber
                          : Colors.grey[700],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isActive ? Colors.black : Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                ),
              ),
              if (index < 3)
                Expanded(
                  child: Container(
                    height: 3,
                    color: isCompleted ? const Color(0xFF10B981) : Colors.grey[700],
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}
