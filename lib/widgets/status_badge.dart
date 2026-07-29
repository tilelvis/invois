import 'package:flutter/material.dart';
import '../models/models.dart';
import 'app_design_system.dart';

class StatusBadge extends StatelessWidget {
  final InvoiceStatus status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    late Color color;
    late String label;
    switch (status) {
      case InvoiceStatus.paid:
        color = AppColors.success(brightness);
        label = 'PAID';
        break;
      case InvoiceStatus.unpaid:
        color = AppColors.warning(brightness);
        label = 'UNPAID';
        break;
      case InvoiceStatus.overdue:
        color = AppColors.danger(brightness);
        label = 'OVERDUE';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
