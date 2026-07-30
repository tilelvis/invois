import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/invoices_list_provider.dart';
import '../widgets/update_banner.dart';
import 'clients_view.dart';
import 'dashboard_view.dart';
import 'invoice_form_view.dart';
import 'invoices_list_view.dart';
import 'products_view.dart';
import 'settings_view.dart';

class MainTabView extends ConsumerStatefulWidget {
  const MainTabView({super.key});

  @override
  ConsumerState<MainTabView> createState() => _MainTabViewState();
}

class _MainTabViewState extends ConsumerState<MainTabView> {
  int _currentIndex = 0;

  List<Widget> get _tabs => [
        DashboardView(
          onGoToNewInvoice: () => _onTabTapped(2),
          onGoToInvoices: () => _onTabTapped(1),
          onGoToClients: () => _onTabTapped(3),
        ),
        const InvoicesListView(),
        const InvoiceFormView(),
        const ClientsView(),
        const ProductsView(),
        const SettingsView(),
      ];

  void _onTabTapped(int index) {
    // Refresh persisted data whenever the user leaves the "New" invoice tab,
    // so a just-saved invoice shows up immediately on Dashboard/Invoices/Clients.
    if (_currentIndex == 2 && index != 2) {
      ref.read(invoicesListProvider.notifier).refresh();
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SafeArea(bottom: false, child: UpdateBanner()),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _tabs,
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabTapped,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Invoices'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle), label: 'New'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Clients'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
