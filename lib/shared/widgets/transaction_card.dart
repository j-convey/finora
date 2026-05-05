import 'package:flutter/material.dart';

import '../../features/transactions/data/models/transaction_model.dart';

class TransactionCard extends StatelessWidget {
  const TransactionCard({
    super.key,
    required this.transaction,
    this.onDismissed,
  });

  final TransactionModel transaction;
  final VoidCallback? onDismissed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isIncome = transaction.isIncome;
    final isPending = transaction.pending;

    // Pending transactions are muted — they haven't settled yet.
    final amountColor = isPending
        ? cs.onSurfaceVariant
        : isIncome
            ? const Color(0xFF4CAF50)
            : cs.onSurface;
    final amountPrefix = isIncome ? '+' : '-';

    final tile = Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isIncome
              ? const Color(0xFF4CAF50).withAlpha(isPending ? 15 : 30)
              : cs.surfaceContainerHighest,
          child: Icon(
            TransactionModel.iconForCategory(transaction.category),
            size: 20,
            color: isPending
                ? cs.onSurfaceVariant
                : isIncome
                    ? const Color(0xFF4CAF50)
                    : cs.onSurfaceVariant,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                transaction.title,
                style: tt.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isPending ? cs.onSurfaceVariant : null,
                ),
              ),
            ),
            if (isPending) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Text(
                  'Pending',
                  style: tt.labelSmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          '${transaction.category} · ${TransactionCard.relativeDate(transaction.date)}',
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        trailing: Text(
          '$amountPrefix\$${transaction.amount.toStringAsFixed(2)}',
          style: tt.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: amountColor,
          ),
        ),
      ),
    );

    if (onDismissed == null) return tile;

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: cs.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete_outlined, color: cs.onError),
      ),
      onDismissed: (_) => onDismissed!(),
      child: tile,
    );
  }

  static String relativeDate(DateTime date) {
    final diff = DateTime.now().difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    return '${date.month}/${date.day}/${date.year}';
  }
}
