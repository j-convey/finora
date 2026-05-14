import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/report_summary.dart';

/// Donut/pie chart rendered with [CustomPainter] — no package dependency.
///
/// Shows a thick ring segmented by [categories], with the [total] and
/// [centerLabel] printed in the centre hole. A compact legend sits to the
/// right, listing the top 7 categories with colour, name, amount, and %.
///
/// Tapping a slice highlights it (dims all others) and fires [onSliceTapped]
/// with the corresponding [ReportCategory]. Tapping the same slice or the
/// hole deselects it.
class DonutChart extends StatefulWidget {
  const DonutChart({
    super.key,
    required this.categories,
    required this.total,
    required this.centerLabel,
    this.onSliceTapped,
  });

  final List<ReportCategory> categories;
  final double total;

  /// Label shown below the total in the centre hole, e.g. "Expenses".
  final String centerLabel;

  /// Called when the user taps a slice. Passes the tapped [ReportCategory].
  final void Function(ReportCategory)? onSliceTapped;

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart> {
  int? _selectedIndex;

  @override
  void didUpdateWidget(DonutChart old) {
    super.didUpdateWidget(old);
    // Clear selection when the data set changes (e.g. period switch).
    if (old.categories != widget.categories) _selectedIndex = null;
  }

  /// Returns the index of the slice at [localPosition] within an area of
  /// [constraints], or null if the tap is in the hole or outside the ring.
  int? _hitTest(Offset localPosition, BoxConstraints constraints) {
    final cx = constraints.maxWidth / 2;
    final cy = constraints.maxHeight / 2;
    final outerR = math.min(cx, cy) - 6;
    final innerR = outerR * 0.58;

    final dx = localPosition.dx - cx;
    final dy = localPosition.dy - cy;
    final dist = math.sqrt(dx * dx + dy * dy);

    if (dist < innerR || dist > outerR) return null;

    // Normalize angle so 0 = top, increasing clockwise — matches painter.
    var angle = math.atan2(dy, dx) + math.pi / 2;
    if (angle < 0) angle += 2 * math.pi;

    final total =
        widget.categories.fold(0.0, (s, c) => s + c.amount);
    if (total <= 0) return null;

    var startAngle = 0.0;
    for (int i = 0; i < widget.categories.length; i++) {
      final sweep =
          (widget.categories[i].amount / total) * 2 * math.pi;
      if (angle >= startAngle && angle < startAngle + sweep) return i;
      startAngle += sweep;
    }
    return null;
  }

  void _handleTap(Offset localPosition, BoxConstraints constraints) {
    final idx = _hitTest(localPosition, constraints);
    setState(() => _selectedIndex = idx);
    if (idx != null) {
      widget.onSliceTapped?.call(widget.categories[idx]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (widget.categories.isEmpty) {
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
                style:
                    tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
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
          // ── Interactive donut ──────────────────────────────────────────
          Expanded(
            flex: 4,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onTapDown: (details) =>
                      _handleTap(details.localPosition, constraints),
                  child: CustomPaint(
                    size: Size(
                        constraints.maxWidth, constraints.maxHeight),
                    painter: _DonutPainter(
                      categories: widget.categories,
                      selectedIndex: _selectedIndex,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _compact(widget.total),
                            style: tt.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            widget.centerLabel,
                            style: tt.labelSmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
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
                children: widget.categories
                    .take(7)
                    .map(
                      (c) => Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 3.5),
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
  _DonutPainter({required this.categories, this.selectedIndex});

  final List<ReportCategory> categories;

  /// Index of the currently selected slice, or null for no selection.
  final int? selectedIndex;

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

    for (int i = 0; i < categories.length; i++) {
      final cat = categories[i];
      final sweep = (cat.amount / total) * 2 * math.pi;
      final isSelected = selectedIndex == i;
      final isDimmed = selectedIndex != null && !isSelected;

      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: drawR),
        startAngle + gap / 2,
        math.max(0.0, sweep - gap),
        false,
        Paint()
          ..color = isDimmed ? cat.color.withAlpha(70) : cat.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.butt,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.categories != categories || old.selectedIndex != selectedIndex;
}
