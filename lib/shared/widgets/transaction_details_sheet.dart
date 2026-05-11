import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/currency_formatter.dart';
import '../../features/accounts/data/models/account_model.dart';
import '../../features/accounts/presentation/providers/accounts_provider.dart';
import '../../features/transactions/data/models/transaction_model.dart';
import '../../features/transactions/presentation/providers/categories_provider.dart';
import '../../features/transactions/presentation/providers/transactions_provider.dart';
import 'reimbursement_sheet.dart';
import 'split_transaction_sheet.dart';

/// Shows the transaction details bottom sheet. Looks up the account by id
/// from [accountsProvider] and wires up the "Change Category" button to the
/// shared category picker.
///
/// Usage from any page:
/// ```
/// onTap: () => showTransactionDetails(context, ref, transaction),
/// ```
void showTransactionDetails(
  BuildContext context,
  WidgetRef ref,
  TransactionModel transaction,
) {
  final account = transaction.accountId != null
      ? ref
          .read(accountsProvider)
          .where((a) => a.id == transaction.accountId)
          .firstOrNull
      : null;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => TransactionDetailsSheet(
      transaction: transaction,
      account: account,
      onChangeCategory: () {
        Navigator.pop(context);
        showCategoryPicker(context, ref, transaction);
      },
    ),
  );
}

/// Shows the category picker bottom sheet for the given transaction.
/// Tapping a category fires a PATCH via [TransactionsNotifier.updateCategory].
void showCategoryPicker(
  BuildContext context,
  WidgetRef ref,
  TransactionModel transaction,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => CategoryPickerSheet(
      current: transaction.category,
      onSelected: (cat) {
        ref
            .read(transactionsProvider.notifier)
            .updateCategory(transaction.id, cat);
      },
    ),
  );
}

/// Shows the type picker bottom sheet for the given transaction.
/// Tapping a type fires a PATCH via [TransactionsNotifier.updateType].
void showTypePicker(
  BuildContext context,
  WidgetRef ref,
  TransactionModel transaction,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => TypePickerSheet(
      current: transaction.type,
      onSelected: (type) {
        ref
            .read(transactionsProvider.notifier)
            .updateType(transaction.id, type);
      },
    ),
  );
}

// ── Transaction Details Sheet ────────────────────────────────────────────────

class TransactionDetailsSheet extends ConsumerStatefulWidget {
  const TransactionDetailsSheet({
    super.key,
    required this.transaction,
    required this.account,
    required this.onChangeCategory,
  });

  final TransactionModel transaction;
  final AccountModel? account;
  final VoidCallback onChangeCategory;

  @override
  ConsumerState<TransactionDetailsSheet> createState() =>
      _TransactionDetailsSheetState();
}

class _TransactionDetailsSheetState
    extends ConsumerState<TransactionDetailsSheet> {
  bool _editingNotes = false;
  bool _unsplitting = false;
  late final TextEditingController _notesController;

  static const _months = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  void initState() {
    super.initState();
    _notesController =
        TextEditingController(text: widget.transaction.notes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _formatFullDate(DateTime d) =>
      '${_months[d.month]} ${d.day}, ${d.year}';

  String? _accountLabel() {
    final account = widget.account;
    if (account == null) return null;
    final institution = account.institutionName?.isNotEmpty == true
        ? account.institutionName!
        : null;
    final parts = [?institution, account.name];
    return parts.join(' · ');
  }

  void _saveNotes() {
    final newNotes = _notesController.text.trim();
    ref
        .read(transactionsProvider.notifier)
        .updateNotes(widget.transaction.id, newNotes);
    setState(() => _editingNotes = false);
  }

  Future<void> _confirmUnsplit(BuildContext ctx) async {
    final parentId = widget.transaction.isSplitParent
        ? widget.transaction.id
        : widget.transaction.parentTransactionId!;
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Remove Splits?'),
        content: const Text(
          'This will delete all split items and restore the original transaction.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Unsplit'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _unsplitting = true);
    try {
      await ref
          .read(transactionsProvider.notifier)
          .unsplitTransaction(parentId);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      setState(() => _unsplitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final transaction = widget.transaction;
    final isIncome = transaction.isIncome;
    final amountColor = transaction.pending
        ? cs.onSurfaceVariant
        : isIncome
            ? const Color(0xFF4CAF50)
            : cs.onSurface;
    final amountPrefix = isIncome ? '+' : '-';

    // Look up parent when this is a child split
    final allTransactions = ref.watch(transactionsProvider);
    final parentTransaction = transaction.isSplitChild
        ? allTransactions
            .where((t) => t.id == transaction.parentTransactionId)
            .firstOrNull
        : null;
    final parentNeedsReview = transaction.isSplitParent
        ? transaction.requiresUserReview
        : (parentTransaction?.requiresUserReview ?? false);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          _editingNotes
              ? MediaQuery.of(context).viewInsets.bottom + 24
              : 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Review banner ────────────────────────────────────────────
            if (parentNeedsReview)
              _ReviewBanner(
                parentTransaction: transaction.isSplitParent
                    ? transaction
                    : parentTransaction!,
                onFixNow: () {
                  Navigator.pop(context);
                  final parent = transaction.isSplitParent
                      ? transaction
                      : parentTransaction!;
                  showSplitTransactionSheet(context, ref, parent);
                },
                onDismiss: () {
                  final parentId = transaction.isSplitParent
                      ? transaction.id
                      : transaction.parentTransactionId!;
                  ref
                      .read(transactionsProvider.notifier)
                      .clearReviewFlag(parentId);
                  setState(() {});
                },
              ),
            // ── Split parent banner ──────────────────────────────────────
            if (transaction.isSplitParent && !parentNeedsReview)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.call_split,
                        size: 16, color: cs.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text(
                      'This transaction has been split',
                      style: tt.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            // ── Part-of indicator ────────────────────────────────────────
            if (transaction.isSplitChild && parentTransaction != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.account_tree_outlined,
                        size: 16, color: cs.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Part of: ${parentTransaction.merchantName ?? parentTransaction.title} '
                        '(${formatCurrency(parentTransaction.amount)})',
                        style: tt.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            // ── Transaction header ───────────────────────────────────────
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: cs.surfaceContainerHighest,
                  child: Icon(
                    TransactionModel.iconForCategory(transaction.category),
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.merchantName ?? transaction.title,
                        style: tt.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _formatFullDate(transaction.date),
                        style: tt.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Amount',
                      style: tt.labelMedium
                          ?.copyWith(color: cs.onSurfaceVariant)),
                  Text(
                    '$amountPrefix${formatCurrency(transaction.amount)}',
                    style: tt.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: amountColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _DetailRow(
              label: 'Category',
              value: transaction.category,
              leading: Icon(
                TransactionModel.iconForCategory(transaction.category),
                size: 18,
                color: cs.primary,
              ),
            ),
            if (_accountLabel() != null)
              _DetailRow(label: 'Account', value: _accountLabel()!),
            if (transaction.merchantName != null &&
                transaction.merchantName!.isNotEmpty)
              _DetailRow(
                  label: 'Merchant', value: transaction.merchantName!),
            if (transaction.originalDescription != null &&
                transaction.originalDescription!.isNotEmpty)
              _DetailRow(
                label: 'Original description',
                value: transaction.originalDescription!,
              ),
            _DetailRow(
              label: 'Status',
              value: transaction.pending ? 'Pending' : 'Cleared',
            ),
            // ── Editable notes row ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _editingNotes
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Notes',
                          style: tt.labelMedium
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _notesController,
                          autofocus: true,
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: 'Add a note…',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                _notesController.text =
                                    widget.transaction.notes ?? '';
                                setState(() => _editingNotes = false);
                              },
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: _saveNotes,
                              child: const Text('Save'),
                            ),
                          ],
                        ),
                      ],
                    )
                  : InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () => setState(() => _editingNotes = true),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 130,
                            child: Text(
                              'Notes',
                              style: tt.labelMedium
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              transaction.notes?.isNotEmpty == true
                                  ? transaction.notes!
                                  : 'Tap to add a note…',
                              style: tt.bodyMedium?.copyWith(
                                color: transaction.notes?.isNotEmpty == true
                                    ? null
                                    : cs.onSurfaceVariant,
                                fontStyle:
                                    transaction.notes?.isNotEmpty == true
                                        ? null
                                        : FontStyle.italic,
                              ),
                            ),
                          ),
                          Icon(Icons.edit_outlined,
                              size: 16, color: cs.onSurfaceVariant),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 20),
            // ── Action buttons ───────────────────────────────────────────
            if (transaction.isSplitParent)
              // Split parent: show unsplit only (children edited individually)
              OutlinedButton.icon(
                onPressed: _unsplitting ? null : () => _confirmUnsplit(context),
                icon: _unsplitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.undo),
                label: const Text('Unsplit Transaction'),
              )
            else if (transaction.isSplitChild)
              // Child split: allow category change + unsplit parent
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.onChangeCategory,
                      icon: const Icon(Icons.label_outline),
                      label: const Text('Category'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          _unsplitting ? null : () => _confirmUnsplit(context),
                      icon: _unsplitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.undo),
                      label: const Text('Unsplit'),
                    ),
                  ),
                ],
              )
            else
              // Normal unsplit transaction: change category + split
              // (Split is only available for server-persisted transactions —
              // locally-added rows have a client-generated 'u{timestamp}' id
              // and are not known to the server.)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.onChangeCategory,
                      icon: const Icon(Icons.label_outline),
                      label: const Text('Category'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => showTypePicker(context, ref, transaction),
                      icon: const Icon(Icons.swap_horiz_outlined),
                      label: const Text('Type'),
                    ),
                  ),
                  if (!transaction.id.startsWith('u')) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          showSplitTransactionSheet(context, ref, transaction);
                        },
                        icon: const Icon(Icons.call_split),
                        label: const Text('Split'),
                      ),
                    ),
                  ],
                ],
              ),
            // ── Reimbursements ─────────────────────────────────────────────
            // Available for any server-persisted income or expense that is not
            // a split-parent ghost row (server rule: split_parent_not_allowed).
            if (!transaction.isSplitParent &&
                !transaction.id.startsWith('u') &&
                transaction.type != TransactionType.transfer) ...[  
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () =>
                    showReimbursementSheet(context, ref, transaction),
                icon: const Icon(Icons.swap_horiz_outlined),
                label: const Text('Reimbursements'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Review banner ────────────────────────────────────────────────────────────

class _ReviewBanner extends StatelessWidget {
  const _ReviewBanner({
    required this.parentTransaction,
    required this.onFixNow,
    required this.onDismiss,
  });

  final TransactionModel parentTransaction;
  final VoidCallback onFixNow;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  size: 18, color: cs.onErrorContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Split Needs Re-reconciliation',
                  style: tt.labelMedium
                      ?.copyWith(color: cs.onErrorContainer),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Your bank updated this transaction\'s amount. '
            'The existing split no longer adds up correctly.',
            style: tt.bodySmall?.copyWith(color: cs.onErrorContainer),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: onDismiss,
                style: TextButton.styleFrom(
                  foregroundColor: cs.onErrorContainer,
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Dismiss'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: onFixNow,
                style: FilledButton.styleFrom(
                  backgroundColor: cs.onErrorContainer,
                  foregroundColor: cs.errorContainer,
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Fix Now'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Detail row ───────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.leading,
  });

  final String label;
  final String value;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(value, style: tt.bodyMedium),
          ),
        ],
      ),
    );
  }
}

// ── Category Picker Sheet ────────────────────────────────────────────────────

class CategoryPickerSheet extends ConsumerStatefulWidget {
  const CategoryPickerSheet({
    super.key,
    required this.current,
    required this.onSelected,
  });

  final String current;
  final void Function(String) onSelected;

  @override
  ConsumerState<CategoryPickerSheet> createState() =>
      _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends ConsumerState<CategoryPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final categories = ref.watch(categoriesProvider);

    final filtered = _query.isEmpty
        ? categories
        : categories
            .where((c) => c.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Change Category', style: tt.titleMedium),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SearchBar(
                hintText: 'Search categories…',
                leading: const Icon(Icons.search),
                onChanged: (v) => setState(() => _query = v),
                constraints: const BoxConstraints(minHeight: 44),
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No categories found',
                          style: tt.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final cat = filtered[i];
                        final isSelected = cat == widget.current;
                        return ListTile(
                          leading: Icon(
                            TransactionModel.iconForCategory(cat),
                            color:
                                isSelected ? cs.primary : cs.onSurfaceVariant,
                          ),
                          title: Text(cat),
                          trailing: isSelected
                              ? Icon(Icons.check, color: cs.primary)
                              : null,
                          selected: isSelected,
                          onTap: () {
                            widget.onSelected(cat);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Type Picker Sheet ────────────────────────────────────────────────────────

class TypePickerSheet extends StatelessWidget {
  const TypePickerSheet({
    super.key,
    required this.current,
    required this.onSelected,
  });

  final TransactionType current;
  final void Function(TransactionType) onSelected;

  static const _typeLabels = <TransactionType, String>{
    TransactionType.income: 'Income',
    TransactionType.expense: 'Expense',
    TransactionType.transfer: 'Transfer',
  };

  static const _typeIcons = <TransactionType, IconData>{
    TransactionType.income: Icons.trending_up,
    TransactionType.expense: Icons.trending_down,
    TransactionType.transfer: Icons.swap_horiz_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final types = [
      TransactionType.income,
      TransactionType.expense,
      TransactionType.transfer,
    ];

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Change Type', style: tt.titleMedium),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.builder(
                itemCount: types.length,
                itemBuilder: (context, i) {
                  final type = types[i];
                  final isSelected = type == current;
                  return ListTile(
                    leading: Icon(
                      _typeIcons[type]!,
                      color: isSelected ? cs.primary : cs.onSurfaceVariant,
                    ),
                    title: Text(_typeLabels[type]!),
                    trailing: isSelected
                        ? Icon(Icons.check, color: cs.primary)
                        : null,
                    selected: isSelected,
                    onTap: () {
                      onSelected(type);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
