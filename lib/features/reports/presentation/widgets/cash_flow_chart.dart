import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../domain/entities/report_summary.dart';

/// Side-by-side monthly bar chart for the Cash Flow tab.
///
/// Each month renders two bars: income (green) and expenses (red).
/// Y-axis labels and horizontal grid lines are painted via [CustomPainter].
class CashFlowChart extends StatelessWidget {
  const CashFlowChart({super.key, required this.months});

  final List<MonthlyFlow> months;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (months.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'No data for this period',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
      );
    }

    final maxVal = months.fold(
      0.0,
      (m, mo) => math.max(m, math.max(mo.income, mo.expenses)),
    );

    return SizedBox(
      height: 220,
      child: CustomPaint(
        painter: _CashFlowPainter(
          months: months,
          maxValue: maxVal > 0 ? maxVal : 1,
          incomeColor: const Color(0xFF4CAF50),
          expenseColor: const Color(0xFFEF5350),
          gridColor: cs.outlineVariant.withAlpha(80),
          labelColor: cs.onSurfaceVariant,
          labelFontSize: tt.labelSmall?.fontSize ?? 10,
        ),
      ),
    );
  }
}

// ── Painter ───────────────────────────────────────────────────────────────────

class _CashFlowPainter extends CustomPainter {
  _CashFlowPainter({
    required this.months,
    required this.maxValue,
    required this.incomeColor,
    required this.expenseColor,
    required this.gridColor,
    required this.labelColor,
    required this.labelFontSize,
  });

  final List<MonthlyFlow> months;
  final double maxValue;
  final Color incomeColor;
  final Color expenseColor;
  final Color gridColor;
  final Color labelColor;
  final double labelFontSize;

  static const _leftPad = 52.0;
  static const _bottomPad = 26.0;
  static const _topPad = 8.0;
  static const _gridLines = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final chartH = size.height - _bottomPad - _topPad;
    final chartW = size.width - _leftPad;

    final labelStyle = TextStyle(
      color: labelColor,
      fontSize: labelFontSize,
    );

    // ── Grid lines + Y-axis labels ─────────────────────────────────────────
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    for (int i = 0; i <= _gridLines; i++) {
      final frac = i / _gridLines;
      final y = _topPad + chartH - frac * chartH;
      canvas.drawLine(Offset(_leftPad, y), Offset(size.width, y), gridPaint);

      final label = _compactY(maxValue * frac);
      _text(canvas, label, labelStyle,
          Offset(0, y - labelFontSize / 2), _leftPad - 4, TextAlign.right);
    }

    // ── Bars ───────────────────────────────────────────────────────────────
    final groupW = chartW / months.length;
    const barGap = 2.0;
    const groupPad = 3.0;
    final barW = (groupW - barGap - groupPad * 2) / 2;

    final incomePaint = Paint()..color = incomeColor;
    final expensePaint = Paint()..color = expenseColor;
    const topRadius = Radius.circular(3);

    for (int i = 0; i < months.length; i++) {
      final m = months[i];
      final gx = _leftPad + i * groupW + groupPad;

      // Income bar
      final ih = (m.income / maxValue) * chartH;
      final iRect = Rect.fromLTWH(gx, _topPad + chartH - ih, barW, ih);
      canvas.drawRRect(
        RRect.fromRectAndCorners(iRect,
            topLeft: topRadius, topRight: topRadius),
        incomePaint,
      );

      // Expense bar
      final eh = (m.expenses / maxValue) * chartH;
      final eRect = Rect.fromLTWH(
          gx + barW + barGap, _topPad + chartH - eh, barW, eh);
      canvas.drawRRect(
        RRect.fromRectAndCorners(eRect,
            topLeft: topRadius, topRight: topRadius),
        expensePaint,
      );

      // Month label — only show every other label when crowded.
      final showLabel = months.length <= 8 || i.isEven;
      if (showLabel) {
        _text(
          canvas,
          m.label,
          labelStyle,
          Offset(gx, _topPad + chartH + 5),
          groupW - groupPad,
          TextAlign.center,
        );
      }
    }
  }

  void _text(Canvas canvas, String text, TextStyle style, Offset offset,
      double maxWidth, TextAlign align) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: ui.TextDirection.ltr,
      textAlign: align,
      maxLines: 1,
    )..layout(maxWidth: math.max(1, maxWidth));

    final dx = switch (align) {
      TextAlign.right => offset.dx + maxWidth - tp.width,
      TextAlign.center => offset.dx + (maxWidth - tp.width) / 2,
      _ => offset.dx,
    };
    tp.paint(canvas, Offset(dx, offset.dy));
  }

  @override
  bool shouldRepaint(_CashFlowPainter old) =>
      old.months != months || old.maxValue != maxValue;

  static String _compactY(double v) {
    if (v >= 1000000) return '\$${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '\$${(v / 1000).toStringAsFixed(0)}K';
    return '\$${v.toStringAsFixed(0)}';
  }
}
