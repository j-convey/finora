import 'package:flutter/material.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../data/models/account_model.dart';

class GroupedAccountsWidget extends StatefulWidget {
  const GroupedAccountsWidget({required this.accounts, super.key});

  final List<AccountModel> accounts;

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
    final groupedAccounts = <AccountType, List<AccountModel>>{};
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
        );
      }).toList(),
    );
  }
}

class _AccountGroup extends StatelessWidget {
  const _AccountGroup({
    required this.type,
    required this.accounts,
    required this.total,
    required this.isExpanded,
    required this.onExpandChanged,
  });

  final AccountType type;
  final List<AccountModel> accounts;
  final double total;
  final bool isExpanded;
  final ValueChanged<bool> onExpandChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      children: [
        Card(
          child: ExpansionTile(
            initiallyExpanded: isExpanded,
            onExpansionChanged: onExpandChanged,
            title: Row(
              children: [
                Icon(
                  AccountModel.iconForType(type),
                  size: 24,
                  color: cs.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AccountModel.labelForType(type),
                        style: tt.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${accounts.length} ${accounts.length == 1 ? 'account' : 'accounts'}',
                        style: tt.labelSmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatCurrency(total),
                  style: tt.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: total < 0 ? const Color(0xFFEF5350) : cs.onSurface,
                  ),
                ),
              ],
            ),
            children: accounts
                .map((a) => _AccountListItem(account: a))
                .toList(),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _AccountListItem extends StatelessWidget {
  const _AccountListItem({required this.account});

  final AccountModel account;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isNegative = account.balance < 0;
    final color = account.color ?? cs.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withAlpha(30),
            child: Icon(AccountModel.iconForType(account.type),
                color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(account.name,
                    style: tt.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500)),
                if (account.institutionName != null)
                  Text(
                    account.institutionName!,
                    style: tt.labelSmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                if (account.availableBalance != null &&
                    (account.type == AccountType.checking ||
                        account.type == AccountType.savings))
                  Text(
                    'Available: ${formatCurrency(account.availableBalance!)}',
                    style: tt.labelSmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatCurrency(account.balance),
                style: tt.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isNegative ? const Color(0xFFEF5350) : cs.onSurface,
                ),
              ),
              if (account.updatedAt != null)
                Text(
                  _relativeTime(account.updatedAt!),
                  style: tt.labelSmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
            ],
          ),
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
