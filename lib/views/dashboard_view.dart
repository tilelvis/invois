import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/invoices_list_provider.dart';
import '../widgets/animated_counter.dart';
import '../widgets/empty_state.dart';
import '../widgets/expandable_fab.dart';
import '../widgets/shimmer_loading.dart';

class DashboardView extends ConsumerWidget {
  final VoidCallback? onGoToNewInvoice;
  final VoidCallback? onGoToInvoices;
  final VoidCallback? onGoToClients;

  const DashboardView({
    super.key,
    this.onGoToNewInvoice,
    this.onGoToInvoices,
    this.onGoToClients,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(invoicesListProvider);
    final currency = NumberFormat.currency(locale: 'en_KE', symbol: 'KES ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      floatingActionButton: ExpandableFab(
        actions: [
          ExpandableFabAction(icon: Icons.receipt_long, label: 'New Invoice', onTap: () => onGoToNewInvoice?.call()),
          ExpandableFabAction(icon: Icons.list_alt, label: 'View Invoices', onTap: () => onGoToInvoices?.call()),
          ExpandableFabAction(icon: Icons.people, label: 'Clients', onTap: () => onGoToClients?.call()),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(invoicesListProvider.notifier).refresh(),
        child: invoicesAsync.when(
          loading: () => const DashboardSkeleton(),
          error: (err, _) => ListView(
            children: [
              const SizedBox(height: 120),
              Center(child: Text('Could not load invoices: $err')),
            ],
          ),
          data: (invoices) {
            if (invoices.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 80),
                  EmptyStateView(
                    icon: Icons.insert_chart_outlined,
                    title: 'Nothing to show yet',
                    message: 'Create your first invoice to see earnings stats and trends here.',
                    actionLabel: 'New Invoice',
                    onAction: onGoToNewInvoice,
                  ),
                ],
              );
            }

            final totalRevenue = invoices
                .where((i) => i.status == InvoiceStatus.paid)
                .fold<double>(0, (sum, i) => sum + i.grandTotal);
            final outstanding = invoices
                .where((i) => i.status != InvoiceStatus.paid)
                .fold<double>(0, (sum, i) => sum + i.grandTotal);
            final paidCount = invoices.where((i) => i.status == InvoiceStatus.paid).length;
            final unpaidCount = invoices.where((i) => i.status == InvoiceStatus.unpaid).length;
            final overdueCount = invoices.where((i) => i.status == InvoiceStatus.overdue).length;

            final monthlyTotals = _monthlyRevenue(invoices);

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Collected',
                        value: totalRevenue,
                        formatter: currency.format,
                        color: const Color(0xFF10B981),
                        icon: Icons.check_circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Outstanding',
                        value: outstanding,
                        formatter: currency.format,
                        color: const Color(0xFFF59E0B),
                        icon: Icons.hourglass_bottom,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _CountPill(label: 'Paid', count: paidCount, color: const Color(0xFF10B981))),
                    const SizedBox(width: 8),
                    Expanded(child: _CountPill(label: 'Unpaid', count: unpaidCount, color: const Color(0xFFF59E0B))),
                    const SizedBox(width: 8),
                    Expanded(child: _CountPill(label: 'Overdue', count: overdueCount, color: Colors.red[700]!)),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Revenue — last 6 months', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 220,
                  child: _RevenueBarChart(monthlyTotals: monthlyTotals),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Buckets paid invoice totals into the last 6 calendar months.
  static List<_MonthTotal> _monthlyRevenue(List<Invoice> invoices) {
    final now = DateTime.now();
    final months = List.generate(6, (i) {
      final d = DateTime(now.year, now.month - (5 - i), 1);
      return d;
    });

    return months.map((month) {
      final total = invoices
          .where((inv) =>
              inv.status == InvoiceStatus.paid &&
              inv.issueDate.year == month.year &&
              inv.issueDate.month == month.month)
          .fold<double>(0, (sum, inv) => sum + inv.grandTotal);
      return _MonthTotal(label: DateFormat('MMM').format(month), total: total);
    }).toList();
  }
}

class _MonthTotal {
  final String label;
  final double total;
  _MonthTotal({required this.label, required this.total});
}

class _RevenueBarChart extends StatelessWidget {
  final List<_MonthTotal> monthlyTotals;
  const _RevenueBarChart({required this.monthlyTotals});

  @override
  Widget build(BuildContext context) {
    final maxTotal = monthlyTotals.fold<double>(0, (m, e) => e.total > m ? e.total : m);
    final maxY = maxTotal <= 0 ? 100.0 : maxTotal * 1.2;

    return BarChart(
      BarChartData(
        maxY: maxY,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= monthlyTotals.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(monthlyTotals[idx].label, style: const TextStyle(fontSize: 11)),
                );
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          for (int i = 0; i < monthlyTotals.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: monthlyTotals[i].total,
                  color: const Color(0xFF005A36),
                  width: 22,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final double value;
  final String Function(double) formatter;
  final Color color;
  final IconData icon;
  const _StatCard({
    required this.label,
    required this.value,
    required this.formatter,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 4),
          AnimatedCounterText(
            value: value,
            formatter: formatter,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _CountPill({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          AnimatedCounterInt(
            value: count,
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: color),
          ),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }
}
