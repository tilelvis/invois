import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/products_list_provider.dart';
import '../services/pdf_service.dart';
import '../widgets/app_design_system.dart';
import '../widgets/empty_state.dart';
import '../widgets/shimmer_loading.dart';
import 'product_form_view.dart';

enum _ProductSort { nameAsc, nameDesc, category }

/// Products catalog screen (US1, T013): search by name/SKU, filter by
/// category, sort, add/edit/delete. Independent of stock/invoicing per the
/// feature's Independent Test.
class ProductsView extends ConsumerStatefulWidget {
  const ProductsView({super.key});

  @override
  ConsumerState<ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends ConsumerState<ProductsView> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _categoryFilter; // null = "All"
  _ProductSort _sort = _ProductSort.nameAsc;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          PopupMenuButton<_ProductSort>(
            icon: const Icon(Icons.sort),
            initialValue: _sort,
            onSelected: (value) => setState(() => _sort = value),
            itemBuilder: (context) => const [
              PopupMenuItem(value: _ProductSort.nameAsc, child: Text('Name (A-Z)')),
              PopupMenuItem(value: _ProductSort.nameDesc, child: Text('Name (Z-A)')),
              PopupMenuItem(value: _ProductSort.category, child: Text('Category')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProductFormView()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(28),
              shadowColor: Colors.black26,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name or SKU',
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
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(productsListProvider.notifier).refresh(),
              child: productsAsync.when(
                loading: () => const InvoiceListSkeleton(),
                error: (err, _) => Center(child: Text('Could not load products: $err')),
                data: (products) {
                  if (products.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 40),
                        EmptyStateView(
                          icon: Icons.inventory_2_outlined,
                          title: 'No products yet',
                          message: 'Add the goods or services you sell to build a reusable, searchable price list.',
                        ),
                      ],
                    );
                  }

                  final categories = products.map((p) => p.category).where((c) => c.trim().isNotEmpty).toSet().toList()
                    ..sort();

                  final filtered = _applyQueryAndFilter(products);
                  final sorted = _applySort(filtered);

                  return Column(
                    children: [
                      if (categories.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _categoryChip('All', null),
                                for (final c in categories) _categoryChip(c, c),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: sorted.isEmpty
                            ? ListView(
                                children: const [
                                  SizedBox(height: 40),
                                  EmptyStateView(
                                    icon: Icons.search_off,
                                    title: 'No matches',
                                    message: 'Try a different search term or filter.',
                                  ),
                                ],
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                itemCount: sorted.length,
                                separatorBuilder: (_, _) => const Divider(height: 1),
                                itemBuilder: (context, index) => _ProductTile(product: sorted[index]),
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Product> _applyQueryAndFilter(List<Product> products) {
    final q = _query.trim().toLowerCase();
    return products.where((p) {
      final matchesCategory = _categoryFilter == null || p.category == _categoryFilter;
      final matchesQuery = q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          (p.sku?.toLowerCase().contains(q) ?? false);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  List<Product> _applySort(List<Product> products) {
    final sorted = [...products];
    switch (_sort) {
      case _ProductSort.nameAsc:
        sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case _ProductSort.nameDesc:
        sorted.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
      case _ProductSort.category:
        sorted.sort((a, b) {
          final c = a.category.toLowerCase().compareTo(b.category.toLowerCase());
          return c != 0 ? c : a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
    }
    return sorted;
  }

  Widget _categoryChip(String label, String? category) {
    final selected = _categoryFilter == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _categoryFilter = category),
      ),
    );
  }
}

class _ProductTile extends ConsumerWidget {
  final Product product;
  const _ProductTile({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;

    return Dismissible(
      key: ValueKey(product.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.danger(brightness),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => _deleteWithUndo(context, ref, product),
      child: ListTile(
        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text([
          if (product.sku != null && product.sku!.isNotEmpty) 'SKU: ${product.sku}',
          product.unit,
          if (product.category.isNotEmpty) product.category,
        ].join(' · ')),
        trailing: Text(
          PdfService.currencyFormatter.format(product.sellingPrice),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductFormView(product: product)),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final danger = AppColors.danger(Theme.of(context).brightness);
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete product?'),
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

  void _deleteWithUndo(BuildContext context, WidgetRef ref, Product product) {
    ref.read(productsListProvider.notifier).delete(product.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted ${product.name}'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () => ref.read(productsListProvider.notifier).restore(product),
        ),
      ),
    );
  }
}
