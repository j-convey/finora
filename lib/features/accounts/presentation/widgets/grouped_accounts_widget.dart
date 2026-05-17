import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finora/core/providers/hide_amounts_provider.dart';
import 'package:finora/core/utils/currency_formatter.dart';
import 'package:finora/features/accounts/domain/entities/account.dart';
import 'package:finora/features/accounts/presentation/extensions/account_ui_extension.dart';

class GroupedAccountsWidget extends StatefulWidget {
  const GroupedAccountsWidget({
    required this.accounts,
    this.onTypeChanged,
    super.key,
  });

  final List<Account> accounts;
  final void Function(Account account, AccountType newType)? onTypeChanged;

  @override
  State<GroupedAccountsWidget> createState() => _GroupedAccountsWidgetState();
}

class _GroupedAccountsWidgetState extends State<GroupedAccountsWidget> {
  final Map<AccountType, bool> _expandedSections = {
    AccountType.cash: true,
    AccountType.checking: true,
    AccountType.savings: true,
    AccountType.creditCard: true,
    AccountType.investment: true,
  };

  @override
  Widget build(BuildContext context) {
    // Group accounts by type
    final groupedAccounts = <AccountType, List<Account>>{};
    for (final account in widget.accounts) {
      groupedAccounts.putIfAbsent(account.type, () => []).add(account);
    }

    // Sort types in display order
    final typeOrder = [
      AccountType.cash,
      AccountType.checking,
      AccountType.savings,
      AccountType.creditCard,
      AccountType.investment,
    ];

    final sortedTypes =
        typeOrder.where((t) => groupedAccounts.containsKey(t)).toList();

    return Column(
      children: sortedTypes.map((type) {
        final accountsOfType = groupedAccounts[type] ?? [];
        final total = accountsOfType.fold<double>(
          0,
          (sum, a) => sum + a.balance,
        );

        return _AccountGroup(
          type: type,
          accounts: accountsOfType,
          total: total,
          isExpanded: _expandedSections[type] ?? true,
          onExpandChanged: (value) {
            setState(() {
              _expandedSections[type] = value;
            });
          },
          onTypeChanged: widget.onTypeChanged,
        );
      }).toList(),
    );
  }
}

class _AccountGroup extends ConsumerWidget {
  const _AccountGroup({
    required this.type,
    required this.accounts,
    required this.total,
    required this.isExpanded,
    required this.onExpandChanged,
    this.onTypeChanged,
  });

  final AccountType type;
  final List<Account> accounts;
  final double total;
  final bool isExpanded;
  final ValueChanged<bool> onExpandChanged;
  final void Function(Account account, AccountType newType)? onTypeChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final hidden = ref.watch(hideAmountsProvider);

    return Column(
      children: [
        Card(
          child: ExpansionTile(
            initiallyExpanded: isExpanded,
            onExpansionChanged: onExpandChanged,
            title: Row(
              children: [
                Icon(
                  type.icon,
                  size: 24,
                  color: cs.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type.label,
                        style:
                            tt.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${accounts.length} ${accounts.length == 1 ? 'account' : 'accounts'}',
                        style:
                            tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Text(
                    hidden ? '••••••' : formatCurrency(total),
                    style: tt.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: total < 0 ? const Color(0xFFEF5350) : cs.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            children: accounts
                .map((a) => _AccountListItem(
                      account: a,
                      onTypeChanged: onTypeChanged,
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _AccountListItem extends ConsumerWidget {
  const _AccountListItem({
    required this.account,
    this.onTypeChanged,
  });

  final Account account;
  final void Function(Account account, AccountType newType)? onTypeChanged;

  Future<void> _showTypePicker(BuildContext context) async {
    final newType = await showDialog<AccountType>(
      context: context,
      builder: (ctx) => _AccountTypePickerDialog(current: account.type),
    );
    if (newType != null && newType != account.type) {
      onTypeChanged?.call(account, newType);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final hidden = ref.watch(hideAmountsProvider);
    final isNegative = account.balance < 0;
    final color = account.color ?? cs.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withAlpha(30),
            child: Icon(account.icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(account.name,
                    style:
                        tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                if (account.institutionName != null)
                  Text(
                    account.institutionName!,
                    style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                if (!hidden &&
                    account.availableBalance != null &&
                    (account.type == AccountType.checking ||
                        account.type == AccountType.savings))
                  Text(
                    'Available: ${formatCurrency(account.availableBalance!)}',
                    style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                hidden ? '••••••' : formatCurrency(account.balance),
                style: tt.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isNegative ? const Color(0xFFEF5350) : cs.onSurface,
                ),
              ),
              if (account.updatedAt != null)
                Text(
                  _relativeTime(account.updatedAt!),
                  style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                ),
            ],
          ),
          if (onTypeChanged != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.edit_outlined,
                  size: 18, color: cs.onSurfaceVariant),
              tooltip: 'Change account type',
              onPressed: () => _showTypePicker(context),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
    );
  }

  static String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _AccountTypePickerDialog extends StatelessWidget {
  const _AccountTypePickerDialog({required this.current});

  final AccountType current;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final types = AccountType.values;

    return AlertDialog(
      title: const Text('Account Type'),
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: types.map((type) {
          final selected = type == current;
          return ListTile(
            leading: Icon(
              type.icon,
              color: selected ? cs.primary : cs.onSurfaceVariant,
            ),
            title: Text(
              type.label,
              style: tt.bodyMedium?.copyWith(
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? cs.primary : null,
              ),
            ),
            trailing: selected ? Icon(Icons.check, color: cs.primary) : null,
            onTap: () => Navigator.of(context).pop(type),
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
