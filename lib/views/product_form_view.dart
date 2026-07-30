import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/products_list_provider.dart';
import '../services/storage_service.dart';
import '../widgets/app_design_system.dart';

/// Add/edit form for a catalog [Product] (US1, T012).
/// Pass an existing [product] to edit it in place; omit it to create a new
/// product. On-hand quantity is intentionally not editable here — per
/// data-model.md it's derived from stock movements (US2) and defaults to 0
/// for a brand-new product.
class ProductFormView extends ConsumerStatefulWidget {
  final Product? product;
  const ProductFormView({super.key, this.product});

  @override
  ConsumerState<ProductFormView> createState() => _ProductFormViewState();
}

class _ProductFormViewState extends ConsumerState<ProductFormView> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _skuController;
  late final TextEditingController _unitController;
  late final TextEditingController _costPriceController;
  late final TextEditingController _sellingPriceController;
  late final TextEditingController _categoryController;
  late final TextEditingController _reorderThresholdController;

  VatCategory _vatCategory = VatCategory.exempt;
  bool _isSaving = false;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _skuController = TextEditingController(text: p?.sku ?? '');
    _unitController = TextEditingController(text: p?.unit ?? '');
    _costPriceController = TextEditingController(text: p != null ? p.costPrice.toString() : '');
    _sellingPriceController = TextEditingController(text: p != null ? p.sellingPrice.toString() : '');
    _categoryController = TextEditingController(text: p?.category ?? '');
    _reorderThresholdController =
        TextEditingController(text: p?.reorderThreshold != null ? p!.reorderThreshold.toString() : '');
    _vatCategory = p?.vatCategory ?? VatCategory.exempt;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _unitController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _categoryController.dispose();
    _reorderThresholdController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final skuText = _skuController.text.trim();
    final categoryText = _categoryController.text.trim();
    final reorderText = _reorderThresholdController.text.trim();

    final product = Product(
      id: widget.product?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      sku: skuText.isEmpty ? null : skuText,
      unit: _unitController.text.trim(),
      costPrice: double.parse(_costPriceController.text.trim()),
      sellingPrice: double.parse(_sellingPriceController.text.trim()),
      vatCategory: _vatCategory,
      category: categoryText,
      reorderThreshold: reorderText.isEmpty ? null : int.parse(reorderText),
      // Not editable from this form — carry the existing value forward on
      // edit, default to 0 for a brand-new product.
      onHandQuantity: widget.product?.onHandQuantity ?? 0,
    );

    try {
      await ref.read(productsListProvider.notifier).save(product);
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ProductSkuConflictException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save product: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Product' : 'Add Product')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Product name *',
                    hintText: 'e.g. Bag of Cement 50kg',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _skuController,
                  decoration: const InputDecoration(
                    labelText: 'SKU / barcode (optional)',
                    hintText: 'Must be unique if provided',
                    prefixIcon: Icon(Icons.qr_code_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _unitController,
                        decoration: const InputDecoration(
                          labelText: 'Unit *',
                          hintText: 'pcs, kg, litre...',
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextFormField(
                        controller: _categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          hintText: 'e.g. Building materials',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _costPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Cost price *',
                          prefixText: 'KES ',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Required';
                          final v = double.tryParse(value.trim());
                          if (v == null || v < 0) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextFormField(
                        controller: _sellingPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Selling price *',
                          prefixText: 'KES ',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Required';
                          final v = double.tryParse(value.trim());
                          if (v == null || v < 0) return 'Invalid';
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
                    if (val != null) setState(() => _vatCategory = val);
                  },
                  decoration: const InputDecoration(
                    labelText: 'KRA VAT Category',
                    prefixIcon: Icon(Icons.percent),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _reorderThresholdController,
                  decoration: const InputDecoration(
                    labelText: 'Low-stock alert threshold (optional)',
                    hintText: 'Flag as low-stock at or below this quantity',
                    prefixIcon: Icon(Icons.warning_amber_outlined),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    final v = int.tryParse(value.trim());
                    if (v == null || v < 0) return 'Invalid';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: _isSaving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_isEditing ? 'Save Changes' : 'Add Product', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
