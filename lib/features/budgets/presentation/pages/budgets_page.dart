import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../data/models/budget_model.dart';
import '../providers/budgets_provider.dart';
import '../../../../shared/widgets/add_transaction_sheet.dart';
import '../../../../shared/widgets/main_drawer.dart';

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
    final isMobilePlatform =
        Theme.of(context).platform == TargetPlatform.android ||
            Theme.of(context).platform == TargetPlatform.iOS;

    final totalAllocated = budgets.fold(0.0, (s, b) => s + b.allocated);
    final totalSpent = budgets.fold(0.0, (s, b) => s + b.spent);
    final overallProgress =
        totalAllocated > 0 ? (totalSpent / totalAllocated) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget'),
        leading: isMobilePlatform
            ? Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => showAddTransactionSheet(context),
          ),
        ],
      ),
      drawer: isMobilePlatform ? const MainDrawer() : null,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_budgets',
        onPressed: () => _showBudgetSheet(context, ref, existing: null),
        icon: const Icon(Icons.add),
        label: const Text('Add Budget'),
      ),
      body: budgets.isEmpty
          ? _EmptyState(
              onAdd: () => _showBudgetSheet(context, ref, existing: null))
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
                          backgroundColor: cs.onPrimaryContainer.withAlpha(40),
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
                                color: cs.onPrimaryContainer.withAlpha(178),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
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

  String _getImageForCategory(String category) {
    return switch (category) {
      'Groceries' =>
        'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=800&q=80',
      'Dining' =>
        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=800&q=80',
      'Transport' =>
        'https://images.unsplash.com/photo-1449965408869-eaa3f722e40d?auto=format&fit=crop&w=800&q=80',
      'Entertainment' =>
        'https://images.unsplash.com/photo-1485846234645-a62644f84728?auto=format&fit=crop&w=800&q=80',
      'Utilities' =>
        'https://images.unsplash.com/photo-1473341304170-971dccb5ac1e?auto=format&fit=crop&w=800&q=80',
      'Health' =>
        'https://images.unsplash.com/photo-1532938911079-1b06ac7ceec7?auto=format&fit=crop&w=800&q=80',
      'Shopping' =>
        'https://images.unsplash.com/photo-1483985988355-763728e1935b?auto=format&fit=crop&w=800&q=80',
      'Rent' =>
        'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=800&q=80',
      'Travel' =>
        'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?auto=format&fit=crop&w=800&q=80',
      _ =>
        'https://images.unsplash.com/photo-1579621970563-ebec7560ff3e?auto=format&fit=crop&w=800&q=80',
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final imageUrl = _getImageForCategory(budget.category);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onEdit,
          onLongPress: onDelete,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest, // Base color if image fails
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withAlpha(100),
                  BlendMode.darken,
                ),
              ),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        budget.category.toUpperCase(),
                        style: tt.labelLarge?.copyWith(
                          color: Colors.white.withAlpha(200),
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatCurrency(budget.allocated),
                        style: tt.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Progress bar
                      Stack(
                        children: [
                          Container(
                            height: 8,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(40),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: budget.progress,
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Icon in the corner
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.white.withAlpha(40),
                    child: Icon(
                      budget.icon,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                      ? Icon(Icons.check, size: 18, color: cs.surface)
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
