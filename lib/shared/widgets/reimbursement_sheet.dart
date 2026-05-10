import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/currency_formatter.dart';
import '../../features/transactions/data/models/reimbursement_model.dart';
import '../../features/transactions/data/models/transaction_model.dart';
import '../../features/transactions/presentation/providers/reimbursement_provider.dart';
import '../../features/transactions/presentation/providers/transactions_provider.dart';
import 'transaction_card.dart';

/// Opens the reimbursement management sheet for [transaction].
/// Works for both expense and income transactions.
void showReimbursementSheet(
  BuildContext context,
  WidgetRef ref,
  TransactionModel transaction,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => ReimbursementSheet(transaction: transaction),
  );
}

// ── Internal view enum ───────────────────────────────────────────────────────

enum _SheetView { list, pick, form }

// ── Sheet ────────────────────────────────────────────────────────────────────

class ReimbursementSheet extends ConsumerStatefulWidget {
  const ReimbursementSheet({super.key, required this.transaction});

  final TransactionModel transaction;

  @override
  ConsumerState<ReimbursementSheet> createState() =>
      _ReimbursementSheetState();
}

class _ReimbursementSheetState extends ConsumerState<ReimbursementSheet> {
  _SheetView _view = _SheetView.list;

  // Shared across pick → form flow
  TransactionModel? _counterpart;
  String? _editingId;
  String _pickQuery = '';

  // Form state
  bool _submitting = false;
  String? _errorMessage;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController();
    _notesCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ── Navigation helpers ───────────────────────────────────────────────────

  void _goToList() => setState(() {
        _view = _SheetView.list;
        _errorMessage = null;
        _submitting = false;
      });

  void _goToPick() => setState(() {
        _view = _SheetView.pick;
        _pickQuery = '';
      });

  void _selectCounterpart(TransactionModel t, double myRemaining) {
    // Pre-fill with the smaller of what I have left and the counterpart's total.
    // The server validates capacity precisely; the user can adjust before submit.
    final prefill = myRemaining.clamp(0.0, t.amount);
    _amountCtrl.text = prefill.toStringAsFixed(2);
    _notesCtrl.text = '';
    setState(() {
      _counterpart = t;
      _editingId = null;
      _view = _SheetView.form;
      _errorMessage = null;
    });
  }

  void _goToEdit(ReimbursementModel r, List<TransactionModel> allTxns) {
    _amountCtrl.text = r.amount.toStringAsFixed(2);
    _notesCtrl.text = r.notes ?? '';
    final isExpense = widget.transaction.isExpense;
    final counterpartId =
        isExpense ? r.incomeTransactionId : r.expenseTransactionId;
    setState(() {
      _editingId = r.id;
      _counterpart = allTxns.where((t) => t.id == counterpartId).firstOrNull;
      _view = _SheetView.form;
      _errorMessage = null;
    });
  }

  // ── Submit / delete ──────────────────────────────────────────────────────

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final notifier =
          ref.read(reimbursementProvider(widget.transaction.id).notifier);

      if (_editingId != null) {
        await notifier.updateReimbursement(
          _editingId!,
          amount: amount,
          notes: _notesCtrl.text.trim().isEmpty
              ? null
              : _notesCtrl.text.trim(),
        );
      } else {
        final cp = _counterpart!;
        final isExpense = widget.transaction.isExpense;
        await notifier.create(
          expenseTransactionId: isExpense ? widget.transaction.id : cp.id,
          incomeTransactionId: isExpense ? cp.id : widget.transaction.id,
          amount: amount,
          notes: _notesCtrl.text.trim().isEmpty
              ? null
              : _notesCtrl.text.trim(),
        );
      }
      _goToList();
    } on DioException catch (e) {
      setState(() {
        _errorMessage = _parseError(e);
        _submitting = false;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Something went wrong. Please try again.';
        _submitting = false;
      });
    }
  }

  Future<void> _confirmDelete(String reimbursementId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Reimbursement?'),
        content: const Text(
          'This will unlink the reimbursement. Both transactions remain unchanged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref
        .read(reimbursementProvider(widget.transaction.id).notifier)
        .delete(reimbursementId);
  }

  static String _parseError(DioException e) {
    final data = e.response?.data;
    final code = data is Map ? data['error'] as String? : null;
    final msg = data is Map ? data['message'] as String? : null;

    if (code == 'over_reimbursement') {
      final max =
          data is Map ? (data['max_allowed'] as num?)?.toDouble() : null;
      if (max != null) return 'Exceeds capacity. Maximum: ${formatCurrency(max)}';
      return msg ?? 'Amount exceeds available capacity.';
    }
    if (code == 'duplicate_link') {
      return 'A link already exists between these transactions. Edit the existing one instead.';
    }
    if (code == 'invalid_directionality') {
      return 'Transaction types are not compatible for reimbursement.';
    }
    if (code == 'split_parent_not_allowed') {
      return 'Cannot reimburse a split parent. Use the individual split items instead.';
    }
    if (e.response?.statusCode == 409) {
      return 'A reimbursement link already exists between these transactions.';
    }
    if (e.response?.statusCode == 404) return 'Transaction not found.';
    return 'Something went wrong. Please try again.';
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) => switch (_view) {
        _SheetView.list => _buildList(context),
        _SheetView.pick => _buildPick(context),
        _SheetView.form => _buildForm(context),
      };

  // ── List view ────────────────────────────────────────────────────────────

  Widget _buildList(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final txn = widget.transaction;
    final asyncData = ref.watch(reimbursementProvider(txn.id));
    final allTxns = ref.watch(transactionsProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Reimbursements',
                    style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            // Transaction summary
            _TxnCard(transaction: txn),
            const SizedBox(height: 12),
            // Async content
            asyncData.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Failed to load reimbursements.',
                  style: tt.bodyMedium?.copyWith(color: cs.error),
                  textAlign: TextAlign.center,
                ),
              ),
              data: (data) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TotalsCard(data: data, isExpense: txn.isExpense),
                  const SizedBox(height: 12),
                  if (data.reimbursements.isNotEmpty) ...[
                    ...data.reimbursements.map(
                      (r) => _ReimbursementTile(
                        reimbursement: r,
                        currentTransaction: txn,
                        allTransactions: allTxns,
                        onEdit: () => _goToEdit(r, allTxns),
                        onDelete: () => _confirmDelete(r.id),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (data.remainingAmount > 0.001)
                    OutlinedButton.icon(
                      onPressed: _goToPick,
                      icon: const Icon(Icons.add_link),
                      label: const Text('Link Reimbursement'),
                    )
                  else if (data.allocatedAmount > 0)
                    _FullyReimbursedBadge(isExpense: txn.isExpense),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Pick view ────────────────────────────────────────────────────────────

  Widget _buildPick(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final txn = widget.transaction;
    final isExpense = txn.isExpense;

    final myRemaining =
        ref.watch(reimbursementProvider(txn.id)).valueOrNull?.remainingAmount ??
            txn.amount;

    final all = ref.watch(transactionsProvider);
    final eligible = all.where((t) {
      if (t.id == txn.id) return false;
      if (isExpense) return t.isIncome;
      // Income side: pick from expenses (split parents not allowed by server)
      return t.isExpense && !t.isSplitParent;
    }).toList();

    final filtered = _pickQuery.isEmpty
        ? eligible
        : eligible
            .where((t) =>
                t.title.toLowerCase().contains(_pickQuery.toLowerCase()) ||
                (t.merchantName
                        ?.toLowerCase()
                        .contains(_pickQuery.toLowerCase()) ??
                    false))
            .toList();

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _goToList,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      isExpense
                          ? 'Select Income Transaction'
                          : 'Select Expense Transaction',
                      style:
                          tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SearchBar(
                hintText: 'Search…',
                leading: const Icon(Icons.search),
                onChanged: (v) => setState(() => _pickQuery = v),
                constraints: const BoxConstraints(minHeight: 44),
              ),
            ),
            const Divider(height: 1),
            // Transaction list
            Flexible(
              child: filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          isExpense
                              ? 'No income transactions found'
                              : 'No expense transactions found',
                          style: tt.bodyMedium
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final t = filtered[i];
                        final color = t.isIncome
                            ? const Color(0xFF4CAF50)
                            : cs.onSurface;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: t.isIncome
                                ? const Color(0xFF4CAF50).withAlpha(30)
                                : cs.surfaceContainerHighest,
                            child: Icon(
                              TransactionModel.iconForCategory(t.category),
                              size: 18,
                              color: t.isIncome
                                  ? const Color(0xFF4CAF50)
                                  : cs.onSurfaceVariant,
                            ),
                          ),
                          title: Text(t.merchantName ?? t.title),
                          subtitle: Text(
                            '${t.category} · ${TransactionCard.relativeDate(t.date)}',
                            style: tt.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                          trailing: Text(
                            formatCurrency(t.amount),
                            style: tt.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          onTap: () => _selectCounterpart(t, myRemaining),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Form view ────────────────────────────────────────────────────────────

  Widget _buildForm(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final isEditing = _editingId != null;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: isEditing ? _goToList : _goToPick,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    isEditing ? 'Edit Reimbursement' : 'Link Reimbursement',
                    style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            // Counterpart card
            if (_counterpart != null) ...[
              const SizedBox(height: 4),
              _TxnCard(transaction: _counterpart!),
            ],
            const SizedBox(height: 16),
            // Amount
            TextField(
              controller: _amountCtrl,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '\$ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Notes
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            // Error
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: tt.bodySmall?.copyWith(color: cs.error),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEditing ? 'Save Changes' : 'Link Reimbursement'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared private sub-widgets ────────────────────────────────────────────────

/// Compact summary card for a transaction (used in the sheet header area).
class _TxnCard extends StatelessWidget {
  const _TxnCard({required this.transaction});

  final TransactionModel transaction;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isIncome = transaction.isIncome;
    final amountColor = isIncome ? const Color(0xFF4CAF50) : cs.onSurface;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isIncome
                ? const Color(0xFF4CAF50).withAlpha(30)
                : cs.surfaceContainerHigh,
            child: Icon(
              TransactionModel.iconForCategory(transaction.category),
              size: 18,
              color: isIncome ? const Color(0xFF4CAF50) : cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.merchantName ?? transaction.title,
                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  transaction.category,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Text(
            formatCurrency(transaction.amount),
            style: tt.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Allocation totals card shown below the transaction card in the list view.
class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.data, required this.isExpense});

  final ReimbursementListResponse data;
  final bool isExpense;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          _TotalsRow(
            label: isExpense ? 'Gross expense' : 'Gross income',
            value: formatCurrency(data.transactionAmount),
            style: tt.bodyMedium,
          ),
          _TotalsRow(
            label: 'Reimbursed',
            value: '− ${formatCurrency(data.allocatedAmount)}',
            style: tt.bodyMedium?.copyWith(color: const Color(0xFF4CAF50)),
          ),
          const Divider(height: 16),
          _TotalsRow(
            label: isExpense ? 'Net cost' : 'Remaining',
            value: formatCurrency(data.remainingAmount),
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _TotalsRow extends StatelessWidget {
  const _TotalsRow({
    required this.label,
    required this.value,
    this.style,
  });

  final String label;
  final String value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
          Text(value, style: style),
        ],
      ),
    );
  }
}

/// One row in the reimbursement list, showing the counterpart transaction
/// name, amount, optional notes, and edit/delete actions.
class _ReimbursementTile extends StatelessWidget {
  const _ReimbursementTile({
    required this.reimbursement,
    required this.currentTransaction,
    required this.allTransactions,
    required this.onEdit,
    required this.onDelete,
  });

  final ReimbursementModel reimbursement;
  final TransactionModel currentTransaction;
  final List<TransactionModel> allTransactions;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isExpense = currentTransaction.isExpense;

    final counterpartId = isExpense
        ? reimbursement.incomeTransactionId
        : reimbursement.expenseTransactionId;
    final counterpart =
        allTransactions.where((t) => t.id == counterpartId).firstOrNull;
    final label = counterpart != null
        ? (counterpart.merchantName ?? counterpart.title)
        : counterpartId;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.swap_horiz, size: 18, color: cs.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: tt.bodyMedium),
                  if (reimbursement.notes?.isNotEmpty == true)
                    Text(
                      reimbursement.notes!,
                      style: tt.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              formatCurrency(reimbursement.amount),
              style: tt.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF4CAF50),
              ),
            ),
            PopupMenuButton<_TileAction>(
              onSelected: (action) =>
                  action == _TileAction.edit ? onEdit() : onDelete(),
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: _TileAction.edit,
                  child: Text('Edit'),
                ),
                PopupMenuItem(
                  value: _TileAction.delete,
                  child: Text('Remove'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _TileAction { edit, delete }

/// Badge shown when the transaction is fully reimbursed.
class _FullyReimbursedBadge extends StatelessWidget {
  const _FullyReimbursedBadge({required this.isExpense});

  final bool isExpense;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Color(0xFF4CAF50),
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            isExpense ? 'Fully reimbursed' : 'Fully allocated',
            style: tt.bodySmall?.copyWith(color: const Color(0xFF4CAF50)),
          ),
        ],
      ),
    );
  }
}
