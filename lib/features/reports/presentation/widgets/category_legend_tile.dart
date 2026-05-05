import 'package:flutter/material.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../data/models/report_summary.dart';

/// A single row in the category breakdown list.
///
/// Shows a coloured dot, the category name, a percentage progress bar,
/// the percentage value, and the formatted currency amount — matching the
/// style shown in the Monarch-style spending breakdown.
class CategoryLegendTile extends StatelessWidget {
  const CategoryLegendTile({super.key, required this.category});

  final ReportCategory category;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: category.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  category.name,
                  style: tt.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${category.percentage.toStringAsFixed(1)}%',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 80,
                child: Text(
                  formatCurrency(category.amount),
                  textAlign: TextAlign.right,
                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          LinearProgressIndicator(
            value: (category.percentage / 100).clamp(0.0, 1.0),
            minHeight: 4,
            backgroundColor: cs.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(category.color),
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      ),
    );
  }
}
