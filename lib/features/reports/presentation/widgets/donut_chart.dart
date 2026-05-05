import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/models/report_summary.dart';

/// Donut/pie chart rendered with [CustomPainter] — no package dependency.
///
/// Shows a thick ring segmented by [categories], with the [total] and
/// [centerLabel] printed in the centre hole. A compact legend sits to the
/// right, listing the top 7 categories with colour, name, amount, and %.
class DonutChart extends StatelessWidget {
  const DonutChart({
    super.key,
    required this.categories,
    required this.total,
    required this.centerLabel,
  });

  final List<ReportCategory> categories;
  final double total;

  /// Label shown below the total in the centre hole, e.g. "Total".
  final String centerLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (categories.isEmpty) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.donut_large_outlined,
                  size: 48, color: cs.onSurfaceVariant),
              const SizedBox(height: 8),
              Text(
                'No data for this period',
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Donut ─────────────────────────────────────────────────────
          Expanded(
            flex: 4,
            child: CustomPaint(
              painter: _DonutPainter(categories: categories),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _compact(total),
                      style: tt.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      centerLabel,
                      style: tt.labelSmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Legend ────────────────────────────────────────────────────
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: categories
                    .take(7)
                    .map(
                      (c) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3.5),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: c.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                c.name,
                                style: tt.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_compact(c.amount)} (${c.percentage.toStringAsFixed(1)}%)',
                              style: tt.labelSmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _compact(double v) {
    if (v >= 1000000) return '\$${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '\$${(v / 1000).toStringAsFixed(1)}K';
    return '\$${v.toStringAsFixed(2)}';
  }
}

// ── Painter ───────────────────────────────────────────────────────────────────

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.categories});

  final List<ReportCategory> categories;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = math.min(cx, cy) - 6;
    final innerR = outerR * 0.58;
    final strokeW = outerR - innerR;
    final drawR = (outerR + innerR) / 2;

    final total = categories.fold(0.0, (s, c) => s + c.amount);
    if (total <= 0) return;

    // Small angular gap between slices for a cleaner look.
    const gap = 0.014;
    var startAngle = -math.pi / 2;

    for (final cat in categories) {
      final sweep = (cat.amount / total) * 2 * math.pi;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: drawR),
        startAngle + gap / 2,
        math.max(0.0, sweep - gap),
        false,
        Paint()
          ..color = cat.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.butt,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.categories != categories;
}
