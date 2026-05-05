import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../data/models/budget_model.dart';
import '../providers/budgets_provider.dart';

// ── Preset colours the user can pick from ───────────────────────────────────

const _kPresetColors = [
  (hex: '#66BB6A', color: Color(0xFF66BB6A)),
  (hex: '#FFA726', color: Color(0xFFFFA726)),
  (hex: '#42A5F5', color: Color(0xFF42A5F5)),
  (hex: '#AB47BC', color: Color(0xFFAB47BC)),
  (hex: '#26A69A', color: Color(0xFF26A69A)),
  (hex: '#EF5350', color: Color(0xFFEF5350)),
  (hex: '#EC407A', color: Color(0xFFEC407A)),
  (hex: '#FF7043', color: Color(0xFFFF7043)),
  (hex: '#5C6BC0', color: Color(0xFF5C6BC0)),
  (hex: '#26C6DA', color: Color(0xFF26C6DA)),
  (hex: '#D4E157', color: Color(0xFFD4E157)),
  (hex: '#8D6E63', color: Color(0xFF8D6E63)),
];

// ── Page ────────────────────────────────────────────────────────────────────

class BudgetsPage extends ConsumerWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(budgetsProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final totalAllocated = budgets.fold(0.0, (s, b) => s + b.allocated);
    final totalSpent = budgets.fold(0.0, (s, b) => s + b.spent);
    final overallProgress =
        totalAllocated > 0 ? (totalSpent / totalAllocated) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_budgets',
        onPressed: () => _showBudgetSheet(context, ref, existing: null),
        icon: const Icon(Icons.add),
        label: const Text('Add Budget'),
      ),
      body: budgets.isEmpty
          ? _EmptyState(onAdd: () => _showBudgetSheet(context, ref, existing: null))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              children: [
                // ── Summary header ──────────────────────────────
                Card(
                  color: cs.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Monthly Budget',
                              style: tt.titleMedium
                                  ?.copyWith(color: cs.onPrimaryContainer),
                            ),
                            Text(
                              '${(overallProgress * 100).toStringAsFixed(0)}% used',
                              style: tt.bodyMedium?.copyWith(
                                color: cs.onPrimaryContainer.withAlpha(178),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: overallProgress.clamp(0.0, 1.0),
                          backgroundColor:
                              cs.onPrimaryContainer.withAlpha(40),
                          valueColor: AlwaysStoppedAnimation(
                            overallProgress > 1
                                ? cs.error
                                : cs.onPrimaryContainer,
                          ),
                          borderRadius: BorderRadius.circular(4),
                          minHeight: 8,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${formatCurrency(totalSpent)} spent',
                              style: tt.bodySmall
                                  ?.copyWith(color: cs.onPrimaryContainer),
                            ),
                            Text(
                              '${formatCurrency(totalAllocated - totalSpent)} remaining',
                              style: tt.bodySmall?.copyWith(
                                color:
                                    cs.onPrimaryContainer.withAlpha(178),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Categories', style: tt.titleMedium),
                const SizedBox(height: 8),
                ...budgets.map(
                  (b) => _BudgetCard(
                    budget: b,
                    onEdit: () => _showBudgetSheet(context, ref, existing: b),
                    onDelete: () => _confirmDelete(context, ref, b),
                  ),
                ),
              ],
            ),
    );
  }

  void _showBudgetSheet(
    BuildContext context,
    WidgetRef ref, {
    required BudgetModel? existing,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BudgetSheet(ref: ref, existing: existing),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    BudgetModel budget,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete budget?'),
        content: Text(
          'Remove the "${budget.category}" envelope? '
          'Your transactions are not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(budgetsProvider.notifier).delete(budget.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Budget card ──────────────────────────────────────────────────────────────

class _BudgetCard extends ConsumerWidget {
  const _BudgetCard({
    required this.budget,
    required this.onEdit,
    required this.onDelete,
  });

  final BudgetModel budget;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final barColor = budget.isOverBudget ? cs.error : budget.color;
    final pct = (budget.progress * 100).toStringAsFixed(0);

    return Dismissible(
      key: Key(budget.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false; // dialog handles the actual delete
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: cs.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete_outlined, color: cs.onError),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: barColor.withAlpha(30),
                      child: Icon(budget.icon, size: 18, color: barColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            budget.category,
                            style: tt.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            budget.isOverBudget
                                ? 'Over budget by \$${(budget.spent - budget.allocated).toStringAsFixed(2)}'
                                : '${formatCurrency(budget.remaining)} remaining',
                            style: tt.bodySmall?.copyWith(
                              color: budget.isOverBudget
                                  ? cs.error
                                  : cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$pct%',
                          style: tt.titleSmall?.copyWith(
                            color: barColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${formatCurrency(budget.spent)} / ${formatCurrency(budget.allocated)}',
                          style: tt.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.edit_outlined,
                        size: 16, color: cs.onSurfaceVariant),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: budget.progress,
                  backgroundColor: cs.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(barColor),
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 6,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Add / Edit sheet ─────────────────────────────────────────────────────────

class _BudgetSheet extends StatefulWidget {
  const _BudgetSheet({required this.ref, required this.existing});
  final WidgetRef ref;
  final BudgetModel? existing;

  @override
  State<_BudgetSheet> createState() => _BudgetSheetState();
}

class _BudgetSheetState extends State<_BudgetSheet> {
  final _categoryCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  late String _selectedColorHex;
  bool _isSaving = false;
  String? _error;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _categoryCtrl.text = widget.existing!.category;
      _amountCtrl.text = widget.existing!.allocated.toStringAsFixed(2);
      _selectedColorHex = widget.existing!.toColorHex();
    } else {
      _selectedColorHex = _kPresetColors.first.hex;
    }
  }

  @override
  void dispose() {
    _categoryCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final category = _categoryCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text);
    if (category.isEmpty || amount == null || amount <= 0) {
      setState(() => _error = 'Please enter a valid category and amount.');
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      if (_isEditing) {
        await widget.ref.read(budgetsProvider.notifier).update(
              widget.existing!.id,
              allocated: amount,
              colorHex: _selectedColorHex,
            );
      } else {
        await widget.ref.read(budgetsProvider.notifier).create(
              category: category,
              allocated: amount,
              colorHex: _selectedColorHex,
            );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isEditing ? 'Edit Budget' : 'Add Budget',
                style: tt.titleMedium,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _categoryCtrl,
            enabled: !_isEditing, // category is immutable on PATCH
            decoration: InputDecoration(
              labelText: 'Category',
              hintText: 'e.g. Groceries',
              border: const OutlineInputBorder(),
              helperText: _isEditing
                  ? 'Category cannot be changed after creation'
                  : null,
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountCtrl,
            decoration: const InputDecoration(
              labelText: 'Monthly Allocation',
              prefixText: '\$',
              border: OutlineInputBorder(),
            ),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          Text('Color', style: tt.labelMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _kPresetColors.map((preset) {
              final isSelected = preset.hex == _selectedColorHex;
              return GestureDetector(
                onTap: () => setState(() => _selectedColorHex = preset.hex),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: preset.color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: cs.onSurface, width: 3)
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: preset.color.withAlpha(120),
                              blurRadius: 6,
                            )
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? Icon(Icons.check,
                          size: 18, color: cs.surface)
                      : null,
                ),
              );
            }).toList(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: tt.bodySmall?.copyWith(color: cs.error),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isEditing ? 'Save Changes' : 'Create Budget'),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.donut_large_outlined,
              size: 64, color: cs.onSurfaceVariant),
          const SizedBox(height: 16),
          Text('No budgets yet', style: tt.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Tap below to create your first budget envelope.',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Budget'),
          ),
        ],
      ),
    );
  }
}

