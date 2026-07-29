import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/pdf_service.dart';
import 'app_design_system.dart';

/// Vertical timeline showing Issued -> Due -> Paid/Overdue progression
/// for a single invoice.
class InvoiceTimeline extends StatelessWidget {
  final Invoice invoice;
  const InvoiceTimeline({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isPaid = invoice.status == InvoiceStatus.paid;
    final isOverdue = invoice.status == InvoiceStatus.overdue;
    final dateFmt = PdfService.dateFormatter;

    final steps = [
      _TimelineStep(
        label: 'Issued',
        date: dateFmt.format(invoice.issueDate),
        isComplete: true,
        color: AppColors.primary,
      ),
      _TimelineStep(
        label: isOverdue ? 'Due (overdue)' : 'Due',
        date: dateFmt.format(invoice.dueDate),
        isComplete: isPaid || isOverdue,
        color: isOverdue ? AppColors.danger(brightness) : AppColors.primary,
      ),
      _TimelineStep(
        label: isPaid ? 'Paid' : 'Awaiting payment',
        date: isPaid ? 'Settled' : '—',
        isComplete: isPaid,
        color: AppColors.success(brightness),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < steps.length; i++)
          _buildRow(context, steps[i], isLast: i == steps.length - 1),
      ],
    );
  }

  Widget _buildRow(BuildContext context, _TimelineStep step, {required bool isLast}) {
    final brightness = Theme.of(context).brightness;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: step.isComplete ? step.color : Colors.transparent,
                  border: Border.all(color: step.color, width: 2),
                ),
                child: step.isComplete
                    ? const Icon(Icons.check, size: 10, color: Colors.white)
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: step.isComplete ? step.color : AppColors.border(brightness),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  step.date,
                  style: TextStyle(color: AppColors.textSecondary(brightness), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineStep {
  final String label;
  final String date;
  final bool isComplete;
  final Color color;
  _TimelineStep({required this.label, required this.date, required this.isComplete, required this.color});
}
