import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../data/models/subscription_model.dart';
import '../providers/subscriptions_provider.dart';
import '../../../../shared/widgets/add_transaction_sheet.dart';

class SubscriptionsPage extends ConsumerWidget {
  const SubscriptionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptions = ref.watch(subscriptionsProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final activeCount = subscriptions
        .where((s) => s.status == SubscriptionStatus.active)
        .length;
    final totalCount = subscriptions.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscriptions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => showAddTransactionSheet(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_subscriptions',
        onPressed: () => _showSubscriptionSheet(context, ref, existing: null),
        icon: const Icon(Icons.add),
        label: const Text('Add Subscription'),
      ),
      body: subscriptions.isEmpty
          ? _EmptyState(
              onAdd: () => _showSubscriptionSheet(context, ref, existing: null),
            )
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
                        Text(
                          'Subscriptions',
                          style: tt.titleMedium?.copyWith(
                            color: cs.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$activeCount active',
                              style: tt.bodyMedium?.copyWith(
                                color: cs.onPrimaryContainer.withAlpha(178),
                              ),
                            ),
                            Text(
                              '$totalCount total',
                              style: tt.bodyMedium?.copyWith(
                                color: cs.onPrimaryContainer.withAlpha(178),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // ── Subscriptions list ──────────────────────────────
                ..._buildSubscriptionsList(subscriptions, context, ref),
              ],
            ),
    );
  }

  List<Widget> _buildSubscriptionsList(
    List<SubscriptionModel> subscriptions,
    BuildContext context,
    WidgetRef ref,
  ) {
    return [
      for (final subscription in subscriptions)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _SubscriptionCard(
            subscription: subscription,
            onEdit: () =>
                _showSubscriptionSheet(context, ref, existing: subscription),
            onDelete: () => _showDeleteConfirmation(context, ref, subscription),
          ),
        ),
    ];
  }

  void _showSubscriptionSheet(
    BuildContext context,
    WidgetRef ref, {
    SubscriptionModel? existing,
  }) {
    final isEditing = existing != null;
    final nameController = TextEditingController(text: existing?.name);
    final merchantController = TextEditingController(
      text: existing?.merchantName,
    );
    final categoryController = TextEditingController(text: existing?.category);
    final expectedAmountController = TextEditingController(
      text: existing?.expectedAmount?.toString() ?? '',
    );
    final minAmountController = TextEditingController(
      text: existing?.minAmount?.toString() ?? '',
    );
    final maxAmountController = TextEditingController(
      text: existing?.maxAmount?.toString() ?? '',
    );
    final matchingNotesController = TextEditingController(
      text: existing?.matchingNotes,
    );

    var selectedStatus = existing?.status ?? SubscriptionStatus.active;
    var selectedRecurrenceUnit =
        existing?.recurrenceUnit ?? RecurrenceUnit.month;
    var selectedRecurrenceInterval = existing?.recurrenceInterval ?? 1;
    var autoLinkEnabled = existing?.autoLinkEnabled ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSheet) => SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEditing ? 'Edit Subscription' : 'Add Subscription',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name*',
                  hintText: 'e.g., Netflix',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: merchantController,
                decoration: const InputDecoration(
                  labelText: 'Merchant',
                  hintText: 'e.g., Netflix Inc.',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  hintText: 'e.g., Entertainment',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: expectedAmountController,
                decoration: const InputDecoration(
                  labelText: 'Expected Amount',
                  prefixText: '\$ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: minAmountController,
                      decoration: const InputDecoration(
                        labelText: 'Min Amount',
                        prefixText: '\$ ',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: maxAmountController,
                      decoration: const InputDecoration(
                        labelText: 'Max Amount',
                        prefixText: '\$ ',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: selectedRecurrenceInterval,
                      decoration: const InputDecoration(labelText: 'Every'),
                      items: List.generate(
                        12,
                        (i) => DropdownMenuItem(
                          value: i + 1,
                          child: Text('${i + 1}'),
                        ),
                      ),
                      onChanged: (value) {
                        if (value != null) {
                          setStateSheet(() {
                            selectedRecurrenceInterval = value;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<RecurrenceUnit>(
                      initialValue: selectedRecurrenceUnit,
                      decoration: const InputDecoration(labelText: 'Unit'),
                      items: RecurrenceUnit.values
                          .map(
                            (unit) => DropdownMenuItem(
                              value: unit,
                              child: Text(
                                unit.toString().split('.').last.capitalize(),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setStateSheet(() {
                            selectedRecurrenceUnit = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<SubscriptionStatus>(
                initialValue: selectedStatus,
                decoration: const InputDecoration(labelText: 'Status'),
                items: SubscriptionStatus.values
                    .map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(
                          status.toString().split('.').last.capitalize(),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setStateSheet(() {
                      selectedStatus = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                title: const Text('Auto-link enabled'),
                value: autoLinkEnabled,
                onChanged: (value) {
                  setStateSheet(() {
                    autoLinkEnabled = value ?? true;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: matchingNotesController,
                decoration: const InputDecoration(
                  labelText: 'Matching Notes',
                  hintText: 'e.g., Hints for transaction matching',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Name is required')),
                      );
                      return;
                    }
                    try {
                      if (isEditing) {
                        await ref
                            .read(subscriptionsProvider.notifier)
                            .update(
                              existing.id,
                              name: nameController.text,
                              merchantName: merchantController.text.isEmpty
                                  ? null
                                  : merchantController.text,
                              category: categoryController.text.isEmpty
                                  ? null
                                  : categoryController.text,
                              expectedAmount:
                                  expectedAmountController.text.isEmpty
                                  ? null
                                  : double.parse(expectedAmountController.text),
                              minAmount: minAmountController.text.isEmpty
                                  ? null
                                  : double.parse(minAmountController.text),
                              maxAmount: maxAmountController.text.isEmpty
                                  ? null
                                  : double.parse(maxAmountController.text),
                              recurrenceInterval: selectedRecurrenceInterval,
                              recurrenceUnit: selectedRecurrenceUnit
                                  .toString()
                                  .split('.')
                                  .last,
                              status: selectedStatus.toString().split('.').last,
                              autoLinkEnabled: autoLinkEnabled,
                              matchingNotes:
                                  matchingNotesController.text.isEmpty
                                  ? null
                                  : matchingNotesController.text,
                            );
                      } else {
                        await ref
                            .read(subscriptionsProvider.notifier)
                            .create(
                              name: nameController.text,
                              merchantName: merchantController.text.isEmpty
                                  ? null
                                  : merchantController.text,
                              category: categoryController.text.isEmpty
                                  ? null
                                  : categoryController.text,
                              expectedAmount:
                                  expectedAmountController.text.isEmpty
                                  ? null
                                  : double.parse(expectedAmountController.text),
                              minAmount: minAmountController.text.isEmpty
                                  ? null
                                  : double.parse(minAmountController.text),
                              maxAmount: maxAmountController.text.isEmpty
                                  ? null
                                  : double.parse(maxAmountController.text),
                              recurrenceInterval: selectedRecurrenceInterval,
                              recurrenceUnit: selectedRecurrenceUnit
                                  .toString()
                                  .split('.')
                                  .last,
                              status: selectedStatus.toString().split('.').last,
                              autoLinkEnabled: autoLinkEnabled,
                              matchingNotes:
                                  matchingNotesController.text.isEmpty
                                  ? null
                                  : matchingNotesController.text,
                            );
                      }
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                  child: Text(isEditing ? 'Update' : 'Create'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    SubscriptionModel subscription,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subscription?'),
        content: Text(
          'Are you sure you want to delete "${subscription.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await ref
                    .read(subscriptionsProvider.notifier)
                    .delete(subscription.id);
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Delete'),
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
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.subscriptions_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text('No subscriptions yet', style: tt.titleMedium),
          const SizedBox(height: 8),
          Text('Track recurring charges and income', style: tt.bodyMedium),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Subscription'),
          ),
        ],
      ),
    );
  }
}

// ── Subscription card ────────────────────────────────────────────────────────

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    required this.subscription,
    required this.onEdit,
    required this.onDelete,
  });

  final SubscriptionModel subscription;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        title: Text(subscription.name, style: tt.titleMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              subscription.merchantName ?? 'No merchant',
              style: tt.bodySmall?.copyWith(color: cs.outline),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(subscription.statusLabel),
                  labelStyle: tt.labelSmall?.copyWith(
                    color: subscription.statusColor,
                  ),
                  backgroundColor: subscription.statusColor.withAlpha(40),
                  side: BorderSide(color: subscription.statusColor),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text('Every ${subscription.recurrenceLabel}'),
                  backgroundColor: cs.secondaryContainer,
                  side: BorderSide(color: cs.secondary.withAlpha(100)),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            if (subscription.expectedAmount != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Expected: ${formatCurrency(subscription.expectedAmount!)}',
                  style: tt.bodySmall?.copyWith(color: cs.outline),
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(onTap: onEdit, child: const Text('Edit')),
            PopupMenuItem(onTap: onDelete, child: const Text('Delete')),
          ],
        ),
      ),
    );
  }
}

extension on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1)}';
}
