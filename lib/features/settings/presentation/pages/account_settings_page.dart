import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../accounts/presentation/providers/net_worth_history_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../budgets/presentation/providers/budgets_provider.dart';
import '../../../subscriptions/presentation/providers/subscriptions_provider.dart';
import '../../../transactions/presentation/providers/categories_provider.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';

class AccountSettingsPage extends ConsumerWidget {
  const AccountSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Server & Account')),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          // ── Connection status card ────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      auth.isAuthenticated
                          ? Icons.cloud_done_outlined
                          : Icons.cloud_off_outlined,
                      color: auth.isAuthenticated
                          ? const Color(0xFF4CAF50)
                          : cs.error,
                      size: 36,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.isAuthenticated ? 'Connected' : 'Not connected',
                            style: tt.titleMedium,
                          ),
                          if (auth.serverUrl.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              auth.serverUrl,
                              style: tt.bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ],
                          if (auth.user?.email != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              auth.user!.email,
                              style: tt.bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // ── Account details ───────────────────────────────────
          if (auth.user != null) ...[
            ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: const Text('Name'),
              trailing: Text(
                auth.user!.displayName,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.alternate_email),
              title: const Text('Email'),
              trailing: Text(
                auth.user!.email,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          ],
          const Divider(),
          // ── Sign Out ──────────────────────────────────────────
          ListTile(
            leading: Icon(Icons.logout, color: cs.error),
            title: Text('Sign Out', style: TextStyle(color: cs.error)),
            onTap: () async {
              _clearLocalCaches(ref);
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/setup');
            },
          ),
        ],
      ),
    );
  }

  void _clearLocalCaches(WidgetRef ref) {
    ref.read(transactionsProvider.notifier).clear();
    ref.read(accountsProvider.notifier).clear();
    ref.read(budgetsProvider.notifier).clear();
    ref.read(subscriptionsProvider.notifier).clear();
    ref.read(categoryGroupsProvider.notifier).clear();
    ref.read(netWorthHistoryProvider.notifier).clear();
  }
}
