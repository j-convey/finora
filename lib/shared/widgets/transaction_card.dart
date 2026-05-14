import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:finora/features/accounts/domain/entities/account.dart';
import 'package:finora/features/transactions/domain/entities/transaction.dart';
import 'package:finora/features/transactions/presentation/extensions/transaction_ui_extension.dart';

class TransactionCard extends StatelessWidget {
  const TransactionCard({
    super.key,
    required this.transaction,
    this.onDismissed,
    this.account,
    this.onTap,
    this.onCategoryTap,
  });

  final Transaction transaction;
  final VoidCallback? onDismissed;
  final Account? account;
  final VoidCallback? onTap;
  final VoidCallback? onCategoryTap;

  static String _accountLabel(Account a) {
    final institution = a.institutionName?.isNotEmpty == true ? a.institutionName! : null;
    final parts = [if (institution != null) institution, a.name];
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isIncome = transaction.isIncome;
    final isTransfer = transaction.type == TransactionType.transfer;
    final isPending = transaction.pending;
    final isSplitParent = transaction.isSplitParent;
    final isSplitChild = transaction.isSplitChild;
    final needsReview = transaction.requiresUserReview;

    // Split parents are muted (ghost rows); pending transactions are muted too.
    final isMuted = isPending || isSplitParent;

    // Pending transactions are muted — they haven't settled yet.
    final amountColor = isMuted
        ? cs.onSurfaceVariant
        : isTransfer
            ? cs.primary
            : isIncome
                ? const Color(0xFF4CAF50)
                : cs.onSurface;
    final amountPrefix = isTransfer ? '↔ ' : (isIncome ? '+' : '-');

    final tile = Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: isTransfer
              ? cs.primary.withAlpha(isMuted ? 15 : 30)
              : isIncome
                  ? const Color(0xFF4CAF50).withAlpha(isMuted ? 15 : 30)
                  : cs.surfaceContainerHighest,
          child: Icon(
            transaction.icon,
            size: 20,
            color: isMuted
                ? cs.onSurfaceVariant
                : isTransfer
                    ? cs.primary
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
                  color: isMuted ? cs.onSurfaceVariant : null,
                ),
              ),
            ),
            if (needsReview) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onErrorContainer),
                    const SizedBox(width: 3),
                    Text(
                      'Review',
                      style: tt.labelSmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onErrorContainer),
                    ),
                  ],
                ),
              ),
            ] else if (isTransfer) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: cs.primary.withAlpha(100)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.swap_horiz_outlined,
                        size: 12,
                        color: cs.primary),
                    const SizedBox(width: 3),
                    Text(
                      transaction.category,
                      style: tt.labelSmall
                          ?.copyWith(color: cs.primary),
                    ),
                  ],
                ),
              ),
            ] else if (isSplitParent) ...[
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
                  'Split',
                  style: tt.labelSmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            ] else if (isPending) ...[
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
        subtitle: account != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CategoryLine(
                    transaction: transaction,
                    isSplitChild: isSplitChild,
                    onCategoryTap: onCategoryTap,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    primaryColor: cs.primary,
                  ),
                  Text(
                    _accountLabel(account!),
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant.withAlpha(178),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              )
            : _CategoryLine(
                transaction: transaction,
                isSplitChild: isSplitChild,
                onCategoryTap: onCategoryTap,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                primaryColor: cs.primary,
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

class _CategoryLine extends StatelessWidget {
  const _CategoryLine({
    required this.transaction,
    required this.isSplitChild,
    required this.onCategoryTap,
    required this.style,
    required this.primaryColor,
  });

  final Transaction transaction;
  final bool isSplitChild;
  final VoidCallback? onCategoryTap;
  final TextStyle? style;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final datePart = ' · ${TransactionCard.relativeDate(transaction.date)}';
    final splitPart = isSplitChild ? ' · Split' : '';
    final dateText = '$datePart$splitPart';

    if (onCategoryTap == null) {
      return Text('${transaction.category}$dateText', style: style);
    }

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: transaction.category,
            style: style?.copyWith(
              color: primaryColor,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor: primaryColor.withAlpha(120),
            ),
            recognizer: _tapRecognizer(onCategoryTap!),
          ),
          TextSpan(text: dateText, style: style),
        ],
      ),
    );
  }

  // Lazy-import gesture recognizer only when needed
  static _CategoryTapRecognizer _tapRecognizer(VoidCallback cb) =>
      _CategoryTapRecognizer(cb);
}

class _CategoryTapRecognizer extends TapGestureRecognizer {
  _CategoryTapRecognizer(VoidCallback cb) {
    onTap = cb;
  }
}
