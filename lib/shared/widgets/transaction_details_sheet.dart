import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/currency_formatter.dart';
import '../../features/accounts/data/models/account_model.dart';
import '../../features/accounts/presentation/providers/accounts_provider.dart';
import '../../features/transactions/data/models/transaction_model.dart';
import '../../features/transactions/presentation/providers/categories_provider.dart';
import '../../features/transactions/presentation/providers/transactions_provider.dart';

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

// ── Transaction Details Sheet ────────────────────────────────────────────────

class TransactionDetailsSheet extends StatelessWidget {
  const TransactionDetailsSheet({
    super.key,
    required this.transaction,
    required this.account,
    required this.onChangeCategory,
  });

  final TransactionModel transaction;
  final AccountModel? account;
  final VoidCallback onChangeCategory;

  static const _months = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  String _formatFullDate(DateTime d) =>
      '${_months[d.month]} ${d.day}, ${d.year}';

  String? _accountLabel() {
    if (account == null) return null;
    final institution = account!.institutionName?.isNotEmpty == true
        ? account!.institutionName!
        : null;
    final parts = [if (institution != null) institution, account!.name];
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isIncome = transaction.isIncome;
    final amountColor = transaction.pending
        ? cs.onSurfaceVariant
        : isIncome
            ? const Color(0xFF4CAF50)
            : cs.onSurface;
    final amountPrefix = isIncome ? '+' : '-';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            if (transaction.notes != null && transaction.notes!.isNotEmpty)
              _DetailRow(label: 'Notes', value: transaction.notes!),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onChangeCategory,
              icon: const Icon(Icons.label_outline),
              label: const Text('Change Category'),
            ),
          ],
        ),
      ),
    );
  }
}

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

    return SafeArea(
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
    );
  }
}
