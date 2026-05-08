import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/hide_amounts_provider.dart';
import '../../core/utils/currency_formatter.dart';

/// Displays [amount] as formatted currency, or "••••••" when amounts are hidden.
///
/// Wrap any sensitive monetary value with this widget instead of [Text].
class MaskedAmount extends ConsumerWidget {
  const MaskedAmount(
    this.amount, {
    this.style,
    this.textAlign,
    this.overflow,
    super.key,
  });

  final double amount;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(hideAmountsProvider);
    return Text(
      hidden ? '••••••' : formatCurrency(amount),
      style: style,
      textAlign: textAlign,
      overflow: overflow,
    );
  }
}
