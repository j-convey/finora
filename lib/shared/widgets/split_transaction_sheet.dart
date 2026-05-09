import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/currency_formatter.dart';
import '../../features/transactions/data/models/split_input_model.dart';
import '../../features/transactions/data/models/transaction_model.dart';
import '../../features/transactions/presentation/providers/categories_provider.dart';
import '../../features/transactions/presentation/providers/transactions_provider.dart';

/// Opens the split-transaction bottom sheet. The caller passes the [parent]
/// transaction whose amount will be split into ≥ 2 named line items.
void showSplitTransactionSheet(
  BuildContext context,
  WidgetRef ref,
  TransactionModel parent,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => SplitTransactionSheet(parent: parent),
  );
}

// ── Sheet ────────────────────────────────────────────────────────────────────

class SplitTransactionSheet extends ConsumerStatefulWidget {
  const SplitTransactionSheet({super.key, required this.parent});

  final TransactionModel parent;

  @override
  ConsumerState<SplitTransactionSheet> createState() =>
      _SplitTransactionSheetState();
}

class _SplitTransactionSheetState extends ConsumerState<SplitTransactionSheet> {
  final List<_SplitRowState> _rows = [];
  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Start with two empty split rows
    _rows.addAll([_SplitRowState(), _SplitRowState()]);
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  double get _splitTotal =>
      _rows.fold(0.0, (sum, r) => sum + (double.tryParse(r.amountCtrl.text) ?? 0.0));

  double get _remaining => widget.parent.amount - _splitTotal;

  bool get _isBalanced =>
      (_remaining.abs() < 0.005); // allow half-cent rounding

  bool get _isValid {
    if (_rows.length < 2) return false;
    if (!_isBalanced) return false;
    return _rows.every((r) => r.titleCtrl.text.trim().isNotEmpty &&
        (double.tryParse(r.amountCtrl.text) ?? -1) > 0);
  }

  void _addRow() => setState(() => _rows.add(_SplitRowState()));

  void _removeRow(int index) {
    if (_rows.length <= 2) return;
    setState(() {
      _rows[index].dispose();
      _rows.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_isValid) return;
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final splits = _rows
        .map(
          (r) => SplitInputModel(
            title: r.titleCtrl.text.trim(),
            amount: double.parse(r.amountCtrl.text),
            category: r.category?.isNotEmpty == true ? r.category : null,
            notes: r.notesCtrl.text.trim().isEmpty ? null : r.notesCtrl.text.trim(),
          ),
        )
        .toList();

    try {
      await ref
          .read(transactionsProvider.notifier)
          .splitTransaction(widget.parent.id, splits);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _errorMessage = _friendlyError(e.toString());
        _submitting = false;
      });
    }
  }

  static String _friendlyError(String raw) {
    if (raw.contains('already split')) {
      return 'This transaction is already split. Use "Unsplit" to start over.';
    }
    if (raw.contains("sum")) {
      return 'Split amounts must add up exactly to the original amount.';
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final categories = ref.watch(categoriesProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text('Split Transaction',
                    style: tt.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          // ── Parent info card ─────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(bottom: 16, top: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: cs.surfaceContainerHigh,
                  child: Icon(
                    TransactionModel.iconForCategory(widget.parent.category),
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.parent.merchantName ?? widget.parent.title,
                        style: tt.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        widget.parent.category,
                        style: tt.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatCurrency(widget.parent.amount),
                  style: tt.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          // ── Split rows ───────────────────────────────────────────────────
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _rows.length,
              itemBuilder: (_, index) => _SplitRowWidget(
                key: ValueKey(_rows[index].hashCode),
                rowState: _rows[index],
                index: index,
                categories: categories,
                parentCategory: widget.parent.category,
                canRemove: _rows.length > 2,
                onRemove: () => _removeRow(index),
                onChanged: () => setState(() {}),
              ),
            ),
          ),
          // ── Add split ────────────────────────────────────────────────────
          TextButton.icon(
            onPressed: _addRow,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add another split'),
          ),
          // ── Balance indicator ────────────────────────────────────────────
          _BalanceBar(
            total: _splitTotal,
            parentAmount: widget.parent.amount,
            remaining: _remaining,
            isBalanced: _isBalanced,
          ),
          const SizedBox(height: 12),
          // ── Error message ────────────────────────────────────────────────
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _errorMessage!,
                style: tt.bodySmall?.copyWith(color: cs.error),
                textAlign: TextAlign.center,
              ),
            ),
          // ── Submit ───────────────────────────────────────────────────────
          FilledButton(
            onPressed: _isValid && !_submitting ? _submit : null,
            child: _submitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create Splits'),
          ),
        ],
      ),
    );
  }
}

// ── Individual split row ─────────────────────────────────────────────────────

/// Mutable state held by the parent widget for each split row.
class _SplitRowState {
  final titleCtrl = TextEditingController();
  final amountCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  String? category;

  void dispose() {
    titleCtrl.dispose();
    amountCtrl.dispose();
    notesCtrl.dispose();
  }
}

class _SplitRowWidget extends StatelessWidget {
  const _SplitRowWidget({
    super.key,
    required this.rowState,
    required this.index,
    required this.categories,
    required this.parentCategory,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
  });

  final _SplitRowState rowState;
  final int index;
  final List<String> categories;
  final String parentCategory;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Split ${index + 1}',
                  style: tt.labelMedium
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
                const Spacer(),
                if (canRemove)
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline,
                        size: 18, color: cs.error),
                    visualDensity: VisualDensity.compact,
                    onPressed: onRemove,
                    tooltip: 'Remove this split',
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: TextField(
                    controller: rowState.titleCtrl,
                    onChanged: (_) => onChanged(),
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: rowState.amountCtrl,
                    onChanged: (_) => onChanged(),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixText: '\$',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _CategoryDropdown(
              categories: categories,
              selected: rowState.category ?? parentCategory,
              onChanged: (cat) {
                rowState.category = cat;
                onChanged();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Category dropdown ────────────────────────────────────────────────────────

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({
    required this.categories,
    required this.selected,
    required this.onChanged,
  });

  final List<String> categories;
  final String selected;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    final effective = categories.contains(selected) ? selected : categories.first;
    return DropdownButtonFormField<String>(
      initialValue: effective,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: categories
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

// ── Balance bar ──────────────────────────────────────────────────────────────

class _BalanceBar extends StatelessWidget {
  const _BalanceBar({
    required this.total,
    required this.parentAmount,
    required this.remaining,
    required this.isBalanced,
  });

  final double total;
  final double parentAmount;
  final double remaining;
  final bool isBalanced;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final Color barColor;
    final String label;

    if (isBalanced) {
      barColor = const Color(0xFF4CAF50);
      label = 'Splits balance exactly ✓';
    } else if (remaining > 0) {
      barColor = cs.error;
      label = '${formatCurrency(remaining)} remaining';
    } else {
      barColor = cs.error;
      label = '${formatCurrency(remaining.abs())} over by';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: barColor.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: barColor.withAlpha(80)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: tt.bodySmall?.copyWith(color: barColor),
          ),
          Text(
            '${formatCurrency(total)} / ${formatCurrency(parentAmount)}',
            style: tt.bodySmall
                ?.copyWith(color: barColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
