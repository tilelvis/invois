import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Wraps shimmer skeletons with theme-aware base/highlight colors.
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius borderRadius;

  const ShimmerBox({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = const BorderRadius.all(Radius.circular(6)),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? Colors.white : Colors.black,
        borderRadius: borderRadius,
      ),
    );
  }
}

/// A skeleton row that mimics an invoice list tile while data loads.
class InvoiceListSkeleton extends StatelessWidget {
  const InvoiceListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: 6,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 140, height: 14),
                    SizedBox(height: 8),
                    ShimmerBox(width: 100, height: 12),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  ShimmerBox(width: 70, height: 14),
                  SizedBox(height: 8),
                  ShimmerBox(width: 50, height: 18, borderRadius: BorderRadius.all(Radius.circular(20))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A skeleton layout that mimics the Dashboard while stats load.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Expanded(child: ShimmerBox(height: 90, borderRadius: BorderRadius.all(Radius.circular(14)))),
                SizedBox(width: 12),
                Expanded(child: ShimmerBox(height: 90, borderRadius: BorderRadius.all(Radius.circular(14)))),
              ],
            ),
            const SizedBox(height: 12),
            const ShimmerBox(height: 60, borderRadius: BorderRadius.all(Radius.circular(10))),
            const SizedBox(height: 24),
            const ShimmerBox(width: 180, height: 16),
            const SizedBox(height: 12),
            const ShimmerBox(height: 220, borderRadius: BorderRadius.all(Radius.circular(12))),
          ],
        ),
      ),
    );
  }
}
