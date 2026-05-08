import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/demo_mode_provider.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../accounts/presentation/providers/net_worth_history_provider.dart';
import '../../../budgets/presentation/providers/budgets_provider.dart';
import '../../../subscriptions/presentation/providers/subscriptions_provider.dart';
import '../../../transactions/presentation/providers/categories_provider.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';

class DemoModeSettingsPage extends ConsumerStatefulWidget {
  const DemoModeSettingsPage({super.key});

  @override
  ConsumerState<DemoModeSettingsPage> createState() =>
      _DemoModeSettingsPageState();
}

class _DemoModeSettingsPageState extends ConsumerState<DemoModeSettingsPage> {
  bool _isLoading = false;

  Future<void> _toggle(bool enable) async {
    setState(() => _isLoading = true);
    ref.read(demoModeProvider.notifier).state = enable;
    // apiClientProvider rebuilds automatically because it watches demoModeProvider.
    // Trigger a full data resync so every provider picks up either demo or
    // real data immediately.
    try {
      await Future.wait([
        ref.read(accountsProvider.notifier).sync(),
        ref.read(transactionsProvider.notifier).sync(),
        ref.read(budgetsProvider.notifier).sync(),
        ref.read(subscriptionsProvider.notifier).sync(),
        ref.read(categoriesProvider.notifier).sync(),
        ref.read(netWorthHistoryProvider.notifier).fetch(),
      ]);
    } catch (_) {
      // Swallow errors from the real server when exiting demo mode with no
      // connectivity — the user can manually sync later.
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDemoMode = ref.watch(demoModeProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Demo Mode')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Info card ──────────────────────────────────────────────────────
          Card(
            color: isDemoMode
                ? const Color(0xFFFFF3E0)
                : cs.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.science_outlined,
                        color: isDemoMode
                            ? const Color(0xFFE65100)
                            : cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isDemoMode ? 'Demo Mode is ON' : 'Demo Mode is OFF',
                        style: tt.titleMedium?.copyWith(
                          color: isDemoMode
                              ? const Color(0xFFE65100)
                              : cs.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Demo mode loads a set of realistic sample data — accounts, '
                    'transactions, budgets and subscriptions — so you can explore '
                    'Finora without touching your real finances.\n\n'
                    '• Your real server data is completely untouched\n'
                    '• Any changes made in demo mode are not saved\n'
                    '• Turning demo mode off restores your real data',
                    style: tt.bodySmall?.copyWith(
                      color: isDemoMode
                          ? const Color(0xFFBF360C)
                          : cs.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Toggle ─────────────────────────────────────────────────────────
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else ...[
            if (!isDemoMode)
              FilledButton.icon(
                icon: const Icon(Icons.science_outlined),
                label: const Text('Enter Demo Mode'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE65100),
                ),
                onPressed: () => _toggle(true),
              )
            else
              OutlinedButton.icon(
                icon: const Icon(Icons.exit_to_app),
                label: const Text('Exit Demo Mode'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.error,
                  side: BorderSide(color: cs.error),
                ),
                onPressed: () => _toggle(false),
              ),
          ],

          if (isDemoMode) ...[
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Demo data',
              style: tt.labelMedium?.copyWith(
                  color: cs.primary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _demoInfoRow(
                context, Icons.account_balance_wallet_outlined, '3 accounts'),
            _demoInfoRow(
                context, Icons.credit_card_outlined, '35 transactions'),
            _demoInfoRow(
                context, Icons.account_balance_outlined, '4 budgets'),
            _demoInfoRow(context, Icons.repeat_outlined, '3 subscriptions'),
            _demoInfoRow(context, Icons.timeline_outlined,
                '6 months net worth history'),
          ],
        ],
      ),
    );
  }

  Widget _demoInfoRow(BuildContext context, IconData icon, String label) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
