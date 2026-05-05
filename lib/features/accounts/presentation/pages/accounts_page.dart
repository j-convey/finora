import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../data/models/account_model.dart';
import '../providers/accounts_provider.dart';

class AccountsPage extends ConsumerWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final netWorth = accounts.fold(0.0, (s, a) => s + a.balance);
    final assets = accounts
        .where((a) => a.balance > 0)
        .fold(0.0, (s, a) => s + a.balance);
    final liabilities = accounts
        .where((a) => a.balance < 0)
        .fold(0.0, (s, a) => s + a.balance.abs());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Net worth summary
          Card(
            color: cs.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NetWorthStat(
                    label: 'Net Worth',
                    value: formatCurrency(netWorth),
                    valueColor: cs.onPrimaryContainer,
                  ),
                  _NetWorthStat(
                    label: 'Assets',
                    value: formatCurrency(assets),
                    valueColor: const Color(0xFF4CAF50),
                  ),
                  _NetWorthStat(
                    label: 'Liabilities',
                    value: formatCurrency(liabilities),
                    valueColor: const Color(0xFFEF5350),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('All Accounts', style: tt.titleMedium),
          const SizedBox(height: 8),
          ...accounts.map((a) => _AccountCard(account: a)),
        ],
      ),
    );
  }
}

class _NetWorthStat extends StatelessWidget {
  const _NetWorthStat(
      {required this.label, required this.value, required this.valueColor});
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(label,
            style: tt.labelSmall
                ?.copyWith(color: cs.onPrimaryContainer.withAlpha(178))),
        const SizedBox(height: 4),
        Text(value,
            style: tt.titleSmall
                ?.copyWith(color: valueColor, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.account});
  final AccountModel account;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isNegative = account.balance < 0;
    final color = account.color ?? cs.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withAlpha(30),
              child: Icon(AccountModel.iconForType(account.type),
                  color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(account.name,
                      style: tt.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w500)),
                  Text(
                    [
                      AccountModel.labelForType(account.type),
                      if (account.institutionName != null)
                        account.institutionName!,
                    ].join(' · '),
                    style: tt.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  if (account.availableBalance != null &&
                      (account.type == AccountType.checking ||
                          account.type == AccountType.savings)) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Available: ${formatCurrency(account.availableBalance!)}',
                      style: tt.labelSmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatCurrency(account.balance),
                  style: tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isNegative
                        ? const Color(0xFFEF5350)
                        : cs.onSurface,
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
