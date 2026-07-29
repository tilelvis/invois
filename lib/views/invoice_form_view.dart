import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../models/models.dart';
import '../providers/invoice_provider.dart';
import '../providers/invoices_list_provider.dart';
import '../services/pdf_service.dart';
import '../services/storage_service.dart';
import '../widgets/app_design_system.dart';
import '../widgets/app_stepper.dart';

// Ensure the class name is precisely InvoiceFormView to preserve routing from MainTabView.
class InvoiceFormView extends ConsumerStatefulWidget {
  const InvoiceFormView({super.key});

  @override
  ConsumerState<InvoiceFormView> createState() => _InvoiceFormViewState();
}

class _InvoiceFormViewState extends ConsumerState<InvoiceFormView> {
  int _currentStep = 0;
  bool _invoiceSavedSuccessfully = false;

  // Step 1 Controllers
  final _customerFormKey = GlobalKey<FormState>();
  final _clientNameController = TextEditingController();
  final _clientPhoneController = TextEditingController();
  final _clientPinController = TextEditingController();
  final _clientEmailController = TextEditingController();
  final _clientNotesController = TextEditingController();

  // Step 1 Payment controllers
  final _paymentFormKey = GlobalKey<FormState>();
  MpesaType _paymentMethod = MpesaType.tillNumber;
  final _businessShortCodeController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _paymentInstructionsController = TextEditingController();

  final currencyFormatter = NumberFormat.currency(locale: 'en_KE', symbol: 'KES ');

  @override
  void dispose() {
    _clientNameController.dispose();
    _clientPhoneController.dispose();
    _clientPinController.dispose();
    _clientEmailController.dispose();
    _clientNotesController.dispose();

    _businessShortCodeController.dispose();
    _businessNameController.dispose();
    _paymentInstructionsController.dispose();
    super.dispose();
  }

  void _clearFormFields() {
    _clientNameController.clear();
    _clientPhoneController.clear();
    _clientPinController.clear();
    _clientEmailController.clear();
    _clientNotesController.clear();

    _businessShortCodeController.clear();
    _businessNameController.clear();
    _paymentInstructionsController.clear();
  }

  String _normalizePhoneNumber(String phone) {
    String clean = phone.replaceAll(RegExp(r'[\s\-\+\(\)]'), '');
    if (clean.startsWith('07')) {
      return '+2547${clean.substring(2)}';
    } else if (clean.startsWith('01')) {
      return '+2541${clean.substring(2)}';
    } else if (clean.startsWith('254')) {
      return '+$clean';
    } else if (!clean.startsWith('+') && (clean.startsWith('7') || clean.startsWith('1'))) {
      return '+254$clean';
    }
    return phone.startsWith('+') ? phone : '+$phone';
  }

  bool _isStep1Valid() {
    // Validate live
    final phone = _clientPhoneController.text.trim();
    final name = _clientNameController.text.trim();
    final isNameValid = name.isNotEmpty;

    // Validate phone: 07..., 01..., 254..., +254...
    final phoneClean = phone.replaceAll(' ', '');
    final kePhoneRegExp = RegExp(r'^(?:\+254|254|0)[71]\d{8}$');
    final isPhoneValid = kePhoneRegExp.hasMatch(phoneClean);

    // Validate KRA PIN optionally
    final pin = _clientPinController.text.trim();
    bool isPinValid = true;
    if (pin.isNotEmpty) {
      final kraRegExp = RegExp(r'^[A-Za-z]\d{9}[A-Za-z]$');
      isPinValid = kraRegExp.hasMatch(pin);
    }

    // Payment method required fields
    final shortCode = _businessShortCodeController.text.trim();
    final isShortCodeValid = RegExp(r'^\d{5,6}$').hasMatch(shortCode);

    // Business Name / Account Name required for Paybill
    bool isPaymentConfigValid = isShortCodeValid;
    if (_paymentMethod == MpesaType.paybill) {
      isPaymentConfigValid = isShortCodeValid && _businessNameController.text.trim().isNotEmpty;
    }

    return isNameValid && isPhoneValid && isPinValid && isPaymentConfigValid;
  }

  void _onNextStep() {
    if (_currentStep == 0) {
      if (!_isStep1Valid()) {
        // Trigger validation UI
        _customerFormKey.currentState?.validate();
        _paymentFormKey.currentState?.validate();
        return;
      }
      // Save Step 1 models to Riverpod state
      final client = Client(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fullName: _clientNameController.text.trim(),
        phoneNumber: _normalizePhoneNumber(_clientPhoneController.text.trim()),
        kraPin: _clientPinController.text.trim().isEmpty ? null : _clientPinController.text.toUpperCase().trim(),
        email: _clientEmailController.text.trim().isEmpty ? null : _clientEmailController.text.trim(),
      );

      final payment = PaymentDetails(
        mpesaType: _paymentMethod,
        mpesaNumber: _businessShortCodeController.text.trim(),
        accountName: _paymentMethod == MpesaType.paybill
            ? (_businessNameController.text.trim().isEmpty ? 'INVOICE' : _businessNameController.text.trim())
            : null,
      );

      ref.read(invoiceProvider.notifier).updateClient(client);
      ref.read(invoiceProvider.notifier).updatePaymentDetails(payment);
    }

    setState(() {
      _currentStep++;
    });
  }

  void _onPreviousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _saveInvoice(InvoiceState state) async {
    try {
      if (!StorageService.isInitialized) {
        await StorageService.init();
      }
      await StorageService.saveInvoice(state.toInvoice());
      ref.read(invoicesListProvider.notifier).refresh();
      _clearFormFields();
      if (!mounted) return;
      setState(() {
        _invoiceSavedSuccessfully = true;
      });
      // Standard haptic feedback
      HapticFeedback.mediumImpact();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save invoice: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  void _showAddItemBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: const AddItemBottomSheet(),
        );
      },
    );
  }

  void _simulateMpesaStkPush(InvoiceState invoiceState) async {
    if (invoiceState.client == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add client details first to trigger STK Push.'),
          backgroundColor: AppColors.error,
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_invoiceSavedSuccessfully) {
      return SuccessScreen(
        onReset: () {
          ref.read(invoiceProvider.notifier).reset();
          setState(() {
            _currentStep = 0;
            _invoiceSavedSuccessfully = false;
          });
        },
        onPrint: () async {
          final pdfBytes = await PdfService.generateInvoicePdf(invoiceState.toInvoice());
          await Printing.layoutPdf(
            onLayout: (format) async => pdfBytes,
            name: 'Invoice-${invoiceState.id}',
          );
        },
        onShare: () async {
          await PdfService.shareInvoiceToWhatsapp(invoiceState.toInvoice());
        },
        onDashboard: () {
          ref.read(invoiceProvider.notifier).reset();
          setState(() {
            _currentStep = 0;
            _invoiceSavedSuccessfully = false;
          });
          // Go back or switch tab handled by parent navigator / tab view.
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'INVOIS KENYA',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Reset Wizard',
            onPressed: () {
              ref.read(invoiceProvider.notifier).reset();
              _clearFormFields();
              setState(() {
                _currentStep = 0;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invoice draft reset successfully.')),
              );
            },
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Custom high-fidelity Stepper indicator
            AppStepper(
              currentStep: _currentStep,
              stepTitles: const ['Customer', 'Items', 'Review'],
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: AppAnimation.normal,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.1, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<int>(_currentStep),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    child: _buildCurrentStepView(invoiceState, isDark),
                  ),
                ),
              ),
            ),
            // Persistent Bottom Navigation Controls
            _buildBottomNavControls(invoiceState),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStepView(InvoiceState state, bool isDark) {
    switch (_currentStep) {
      case 0:
        return _buildStep1CustomerAndPayment(isDark);
      case 1:
        return _buildStep2LineItems(state, isDark);
      case 2:
        return _buildStep3Review(state, isDark);
      default:
        return Container();
    }
  }

  Widget _buildStep1CustomerAndPayment(bool isDark) {
    final brightness = isDark ? Brightness.dark : Brightness.light;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title block
        Text(
          'Customer & Payment Configuration',
          style: AppTypography.titleStyle.copyWith(fontSize: 18),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Enter recipient details and choose how you would like to be paid.',
          style: AppTypography.captionStyle,
        ),
        const SizedBox(height: AppSpacing.md),

        // Customer Card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            side: BorderSide(color: AppColors.border(brightness)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Form(
              key: _customerFormKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_pin_rounded, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Text('Customer Profile', style: AppTypography.titleStyle),
                    ],
                  ),
                  const Divider(height: 24),
                  TextFormField(
                    controller: _clientNameController,
                    onChanged: (val) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Customer Full Name *',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Full Name is required' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _clientPhoneController,
                    onChanged: (val) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Kenyan Phone (07... / 01... / +254...) *',
                      prefixIcon: Icon(Icons.phone_iphone_outlined),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Phone number is required';
                      final phoneClean = value.replaceAll(' ', '');
                      final kePhoneRegExp = RegExp(r'^(?:\+254|254|0)[71]\d{8}$');
                      if (!kePhoneRegExp.hasMatch(phoneClean)) {
                        return 'Invalid format. Use 07..., 01... or +254...';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _clientEmailController,
                    decoration: const InputDecoration(
                      labelText: 'Optional Email Address',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _clientPinController,
                    onChanged: (val) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Optional KRA PIN (e.g. A123456789B)',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      final kraRegExp = RegExp(r'^[A-Za-z]\d{9}[A-Za-z]$');
                      if (!kraRegExp.hasMatch(value.trim())) {
                        return 'Invalid KRA PIN format (e.g. A123456789B)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _clientNotesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Optional Customer Notes',
                      prefixIcon: Icon(Icons.edit_note),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Payment Configuration Card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            side: BorderSide(color: AppColors.border(brightness)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Form(
              key: _paymentFormKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.payment_rounded, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Text('Lipa Na M-Pesa Gateway', style: AppTypography.titleStyle),
                    ],
                  ),
                  const Divider(height: 24),
                  // Custom Material 3 Segmented Payment Choice
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          avatar: const Icon(Icons.storefront, size: 16),
                          label: const Text('Till Number'),
                          selected: _paymentMethod == MpesaType.tillNumber,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _paymentMethod = MpesaType.tillNumber);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: ChoiceChip(
                          avatar: const Icon(Icons.account_balance, size: 16),
                          label: const Text('Paybill'),
                          selected: _paymentMethod == MpesaType.paybill,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _paymentMethod = MpesaType.paybill);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _businessShortCodeController,
                    onChanged: (val) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: _paymentMethod == MpesaType.tillNumber
                          ? 'Business Till Number (5-6 digits) *'
                          : 'Business Paybill Number (5-6 digits) *',
                      prefixIcon: const Icon(Icons.dialpad),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Business Short Code is required';
                      if (!RegExp(r'^\d{5,6}$').hasMatch(value)) {
                        return 'Must be exactly 5 or 6 digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _businessNameController,
                    decoration: InputDecoration(
                      labelText: _paymentMethod == MpesaType.tillNumber
                          ? 'Optional Business Name'
                          : 'Account Name/Number (e.g. Project Name) *',
                      prefixIcon: const Icon(Icons.business),
                    ),
                    validator: (value) {
                      if (_paymentMethod == MpesaType.paybill && (value == null || value.trim().isEmpty)) {
                        return 'Account name is required for M-Pesa Paybill';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _paymentInstructionsController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Optional Payment Instructions',
                      prefixIcon: Icon(Icons.info_outline),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2LineItems(InvoiceState state, bool isDark) {
    final brightness = isDark ? Brightness.dark : Brightness.light;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title block
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invoice Items',
                  style: AppTypography.titleStyle.copyWith(fontSize: 18),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Add products, labor costs, or services to this invoice.',
                  style: AppTypography.captionStyle,
                ),
              ],
            ),
            if (state.items.isNotEmpty)
              ElevatedButton.icon(
                onPressed: _showAddItemBottomSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Item'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // List or Empty state
        if (state.items.isEmpty)
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              side: BorderSide(color: AppColors.border(brightness)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'No invoice items yet',
                    style: AppTypography.titleStyle.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Add products or services to begin building this invoice.',
                    textAlign: TextAlign.center,
                    style: AppTypography.captionStyle.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton.icon(
                    onPressed: _showAddItemBottomSheet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text(
                      'Add First Item',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.items.length,
            separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final item = state.items[index];
              final isLabor = item.type == ItemType.labor;

              return Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  side: BorderSide(color: AppColors.border(brightness)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  leading: CircleAvatar(
                    backgroundColor: (isLabor
                            ? AppColors.laborAccent(brightness)
                            : AppColors.materialAccent(brightness))
                        .withValues(alpha: 0.12),
                    foregroundColor: isLabor
                        ? AppColors.laborAccent(brightness)
                        : AppColors.materialAccent(brightness),
                    child: Icon(isLabor ? Icons.engineering_outlined : Icons.construction_outlined),
                  ),
                  title: Text(
                    item.description,
                    style: AppTypography.titleStyle.copyWith(fontSize: 14),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      '${item.quantity} ${isLabor ? "Hrs" : "Units"} @ ${currencyFormatter.format(item.unitPrice)}\n'
                      'Subtotal: ${currencyFormatter.format(item.subtotal)} | VAT (${item.vatCategory == VatCategory.standard16 ? "16%" : item.vatCategory == VatCategory.zeroRated ? "0%" : "Exempt"}): ${currencyFormatter.format(item.vatAmount)}',
                      style: AppTypography.captionStyle.copyWith(fontSize: 11, height: 1.4),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currencyFormatter.format(item.totalWithVat),
                        style: AppTypography.titleStyle.copyWith(fontSize: 14, color: AppColors.primary),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.error),
                        onPressed: () {
                          ref.read(invoiceProvider.notifier).removeItem(index);
                          HapticFeedback.lightImpact();
                        },
                      )
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildStep3Review(InvoiceState state, bool isDark) {
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final client = state.client;
    final payment = state.paymentDetails;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title Block
        Text(
          'Review & Confirm',
          style: AppTypography.titleStyle.copyWith(fontSize: 18),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Please verify all invoice parameters before executing saving.',
          style: AppTypography.captionStyle,
        ),
        const SizedBox(height: AppSpacing.md),

        // 1. Customer card review
        if (client != null)
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              side: BorderSide(color: AppColors.border(brightness)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_outline, color: AppColors.primary, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Text('Customer Details', style: AppTypography.titleStyle),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildReviewRow('Full Name', client.fullName),
                  const SizedBox(height: AppSpacing.sm),
                  _buildReviewRow('Phone Number', client.phoneNumber),
                  if (client.email != null && client.email!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _buildReviewRow('Email', client.email!),
                  ],
                  if (client.kraPin != null && client.kraPin!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _buildReviewRow('KRA PIN', client.kraPin!.toUpperCase()),
                  ],
                ],
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.md),

        // 2. Payment Gateway summary
        if (payment != null)
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              side: BorderSide(color: AppColors.border(brightness)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Text('Payment Summary', style: AppTypography.titleStyle),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildReviewRow('Payment Method', payment.mpesaType == MpesaType.paybill ? 'Paybill' : 'Till Number'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildReviewRow('Business Code', payment.mpesaNumber),
                  if (payment.mpesaType == MpesaType.paybill && payment.accountName != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _buildReviewRow('Account Name', payment.accountName!),
                  ],
                ],
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.md),

        // 3. Billing items review summary
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            side: BorderSide(color: AppColors.border(brightness)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.list_alt_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Billing Line Items (${state.items.length})', style: AppTypography.titleStyle),
                  ],
                ),
                const Divider(height: 24),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.items.length,
                  itemBuilder: (context, idx) {
                    final item = state.items[idx];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.description, style: AppTypography.bodyStyle.copyWith(fontWeight: FontWeight.bold)),
                                Text('${item.quantity} x ${currencyFormatter.format(item.unitPrice)}', style: AppTypography.captionStyle),
                              ],
                            ),
                          ),
                          Text(currencyFormatter.format(item.totalWithVat), style: AppTypography.bodyStyle.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // 4. Totals Card Review
        Card(
          elevation: 4,
          color: AppColors.slateCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('INVOICE REF:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                    Text(
                      state.id,
                      style: TextStyle(color: AppColors.warning(Brightness.dark), fontWeight: FontWeight.w900, letterSpacing: 1.0),
                    ),
                  ],
                ),
                const Divider(color: Colors.white24, height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal:', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    Text(currencyFormatter.format(state.totalSubtotal), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('KRA VAT Total (16%):', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    Text(currencyFormatter.format(state.totalVat), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'GRAND TOTAL:',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                    Text(
                      currencyFormatter.format(state.grandTotal),
                      style: const TextStyle(color: AppColors.brandAccent, fontWeight: FontWeight.w900, fontSize: 20),
                    ),
                  ],
                ),
                if (state.etimsInvoiceNumber != null) ...[
                  const Divider(color: Colors.white24, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.verified, color: AppColors.success(Brightness.dark), size: 18),
                          const SizedBox(width: 4),
                          Text('eTIMS COMPLIANT', style: TextStyle(color: AppColors.success(Brightness.dark), fontWeight: FontWeight.w900, fontSize: 12)),
                        ],
                      ),
                      Text(
                        state.etimsInvoiceNumber!,
                        style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // M-PESA STK Action
        ElevatedButton.icon(
          onPressed: () => _simulateMpesaStkPush(state),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          ),
          icon: const Icon(Icons.bolt, size: 24),
          label: const Text(
            'TRIGGER M-PESA STK PUSH',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.0),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.captionStyle),
        Text(value, style: AppTypography.bodyStyle.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildBottomNavControls(InvoiceState state) {
    final isFirstStep = _currentStep == 0;
    final isLastStep = _currentStep == 2;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brightness = Theme.of(context).brightness;

    // Navigation controller enabled/disabled flags
    final bool isNextEnabled = _currentStep == 0
        ? _isStep1Valid()
        : _currentStep == 1
            ? state.items.isNotEmpty
            : true;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.border(brightness),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!isFirstStep)
            TextButton.icon(
              onPressed: _onPreviousStep,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            )
          else
            const SizedBox.shrink(),
          ElevatedButton.icon(
            onPressed: isNextEnabled
                ? (isLastStep ? () => _saveInvoice(state) : _onNextStep)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              disabledBackgroundColor: AppColors.slate400,
            ),
            icon: Icon(isLastStep ? Icons.check_circle_outline : Icons.arrow_forward),
            label: Text(
              isLastStep ? 'Generate Invoice' : 'Next Step',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// MATERIAL 3 MODERN BOTTOM SHEET ADD ITEM
// ==========================================
class AddItemBottomSheet extends ConsumerStatefulWidget {
  const AddItemBottomSheet({super.key});

  @override
  ConsumerState<AddItemBottomSheet> createState() => _AddItemBottomSheetState();
}

class _AddItemBottomSheetState extends ConsumerState<AddItemBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _qtyController = TextEditingController();
  final _priceController = TextEditingController();

  ItemType _itemType = ItemType.material;
  VatCategory _vatCategory = VatCategory.exempt;

  double _subtotal = 0.0;
  double _vatPreview = 0.0;
  double _lineTotal = 0.0;

  final currencyFormatter = NumberFormat.currency(locale: 'en_KE', symbol: 'KES ');

  @override
  void dispose() {
    _descController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _calculateRealtimeTotals() {
    final qty = double.tryParse(_qtyController.text) ?? 0.0;
    final price = double.tryParse(_priceController.text) ?? 0.0;
    final sub = qty * price;

    double vat = 0.0;
    if (_vatCategory == VatCategory.standard16) {
      vat = sub * 0.16;
    }

    setState(() {
      _subtotal = sub;
      _vatPreview = vat;
      _lineTotal = sub + vat;
    });
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.slate400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Add Invoice Line Item',
                style: AppTypography.titleStyle.copyWith(fontSize: 18),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Subtotals and Kenyan VAT will compute automatically.',
                style: AppTypography.captionStyle,
              ),
              const Divider(height: 24),

              // Modern Choice Segment Chips
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      avatar: const Icon(Icons.handyman_outlined, size: 16),
                      label: const Text('Labour'),
                      selected: _itemType == ItemType.labor,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _itemType = ItemType.labor;
                            _calculateRealtimeTotals();
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ChoiceChip(
                      avatar: const Icon(Icons.shopping_bag_outlined, size: 16),
                      label: const Text('Material'),
                      selected: _itemType == ItemType.material,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _itemType = ItemType.material;
                            _calculateRealtimeTotals();
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Item Description *',
                  hintText: 'e.g. Electrical wiring service / Copper cables',
                  prefixIcon: Icon(Icons.notes),
                ),
                validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.md),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _qtyController,
                      onChanged: (val) => _calculateRealtimeTotals(),
                      decoration: InputDecoration(
                        labelText: _itemType == ItemType.labor ? 'Hours (decimal ok) *' : 'Quantity *',
                        prefixIcon: const Icon(Icons.numbers_outlined),
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
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      onChanged: (val) => _calculateRealtimeTotals(),
                      decoration: const InputDecoration(
                        labelText: 'Unit Price *',
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
              const SizedBox(height: AppSpacing.md),

              DropdownButtonFormField<VatCategory>(
                initialValue: _vatCategory,
                items: const [
                  DropdownMenuItem(value: VatCategory.exempt, child: Text('Exempt (0% VAT)')),
                  DropdownMenuItem(value: VatCategory.standard16, child: Text('Standard VAT (16%)')),
                  DropdownMenuItem(value: VatCategory.zeroRated, child: Text('Zero-Rated (0%)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _vatCategory = val;
                      _calculateRealtimeTotals();
                    });
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'KRA VAT Category',
                  prefixIcon: Icon(Icons.percent),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Live Real-Time Calculation Preview Card
              Card(
                color: AppColors.surfaceVariant(brightness),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  side: BorderSide(color: AppColors.border(brightness)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Subtotal:', style: TextStyle(color: AppColors.textSecondary(brightness))),
                          Text(currencyFormatter.format(_subtotal), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('KRA VAT Preview:', style: TextStyle(color: AppColors.textSecondary(brightness))),
                          Text(currencyFormatter.format(_vatPreview), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Estimated Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            currencyFormatter.format(_lineTotal),
                            style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary, fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

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
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
                child: const Text('Add Line Item', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
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
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() {
      _step = 1;
      _statusMessage = 'Request dispatched to Safaricom Daraja API gateway...';
    });

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() {
      _step = 2;
      _statusMessage = 'STK Push pop-up sent to client handset ${widget.phoneNumber}.\nAwaiting client PIN entry...';
    });

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() {
      _step = 3;
      _statusMessage = 'PIN validated. Transferring KES ${currencyFormatter.format(widget.amount)}...';
    });

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() {
      _step = 4;
      _statusMessage = 'CONFIRMED! Received KES ${currencyFormatter.format(widget.amount)} from ${widget.phoneNumber}.\nReceipt ref: MP${DateTime.now().millisecondsSinceEpoch.toString().substring(4)}K';
    });

    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.slateCard,
      padding: const EdgeInsets.all(AppSpacing.lg),
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
                  style: TextStyle(color: AppColors.brandAccent, fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 16),
                ),
                if (_step < 4)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandAccent),
                  )
                else
                  const Icon(Icons.check_circle, color: AppColors.brandAccent, size: 24),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildPipelineProgress(),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_step == 4)
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
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
                      ? AppColors.success(Brightness.dark)
                      : isActive
                          ? AppColors.warning(Brightness.dark)
                          : AppColors.slate700,
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
                    color: isCompleted ? AppColors.success(Brightness.dark) : AppColors.slate700,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

// ==========================================
// PURE FLUTTER CELEBRATORY SUCCESS SCREEN & CONFETTI
// ==========================================
class SuccessScreen extends StatefulWidget {
  final VoidCallback onReset;
  final VoidCallback onPrint;
  final VoidCallback onShare;
  final VoidCallback onDashboard;

  const SuccessScreen({
    super.key,
    required this.onReset,
    required this.onPrint,
    required this.onShare,
    required this.onDashboard,
  });

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  final List<ConfettiParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.bounceOut),
    );

    _animController.forward();

    // Spawn programmatic confetti particles
    final random = Random();
    for (int i = 0; i < 80; i++) {
      _particles.add(ConfettiParticle(
        color: [
          AppColors.primary,
          AppColors.brandAccent,
          AppColors.warning(Brightness.light),
          AppColors.success(Brightness.dark),
        ][random.nextInt(4)],
        x: 0.5,
        y: 0.4,
        vx: (random.nextDouble() - 0.5) * 12,
        vy: -random.nextDouble() * 15 - 5,
        radius: random.nextDouble() * 4 + 4,
        rotation: random.nextDouble() * 2 * pi,
        rotationSpeed: (random.nextDouble() - 0.5) * 0.2,
      ));
    }

    _animController.addListener(() {
      for (var p in _particles) {
        p.update();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Custom confetti painter
          Positioned.fill(
            child: CustomPaint(
              painter: ConfettiPainter(particles: _particles),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        color: AppColors.brandAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 64,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Invoice Created Successfully',
                    textAlign: TextAlign.center,
                    style: AppTypography.headerStyle.copyWith(color: AppColors.primary, fontSize: 24),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Your invoice has been saved and is ready to share.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary(Theme.of(context).brightness)),
                  ),
                  const Spacer(),

                  // CTA Operations
                  ElevatedButton.icon(
                    onPressed: widget.onPrint,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Print PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  ElevatedButton.icon(
                    onPressed: widget.onShare,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Share to WhatsApp', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: widget.onReset,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                          ),
                          child: const Text('New Invoice', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: widget.onDashboard,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.surfaceVariant(Theme.of(context).brightness),
                            foregroundColor: AppColors.textPrimary(Theme.of(context).brightness),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                          ),
                          child: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ConfettiParticle {
  Color color;
  double x; // Percentage 0.0 - 1.0
  double y; // Percentage 0.0 - 1.0
  double vx;
  double vy;
  double radius;
  double rotation;
  double rotationSpeed;

  ConfettiParticle({
    required this.color,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.rotation,
    required this.rotationSpeed,
  });

  void update() {
    // Add gravity
    vy += 0.4;
    // Update velocities to absolute offsets
    x += vx / 400.0;
    y += vy / 400.0;
    rotation += rotationSpeed;
  }
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;

  ConfettiPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      if (p.x < 0 || p.x > 1.0 || p.y < 0 || p.y > 1.0) continue;

      final paint = Paint()..color = p.color;
      final px = p.x * size.width;
      final py = p.y * size.height;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(p.rotation);

      // Draw particle as rectangle or circle
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.radius * 2, height: p.radius),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
