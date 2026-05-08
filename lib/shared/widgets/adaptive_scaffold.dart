import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/shell_index_provider.dart';
import '../../app/providers/sidebar_provider.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/transactions/presentation/pages/transactions_page.dart';
import '../../features/accounts/presentation/pages/accounts_page.dart';
import '../../features/budgets/presentation/pages/budgets_page.dart';
import '../../features/subscriptions/presentation/pages/subscriptions_page.dart';
import '../../features/reports/presentation/pages/reports_page.dart';
import 'add_transaction_sheet.dart';
import 'main_drawer.dart';

class _Destination {
  const _Destination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const _destinations = [
  _Destination(
    label: 'Dashboard',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
  ),
  _Destination(
    label: 'Accounts',
    icon: Icons.layers_outlined,
    selectedIcon: Icons.layers,
  ),
  _Destination(
    label: 'Transactions',
    icon: Icons.credit_card_outlined,
    selectedIcon: Icons.credit_card,
  ),
  _Destination(
    label: 'Cash Flow',
    icon: Icons.bar_chart_outlined,
    selectedIcon: Icons.bar_chart,
  ),
  _Destination(
    label: 'Budget',
    icon: Icons.account_balance_outlined,
    selectedIcon: Icons.account_balance,
  ),
];

/// Main shell widget. Uses [IndexedStack] for tab state preservation.
/// All tab switching goes through [shellIndexProvider] — the router is only
/// used for full-screen pushes (Settings, Reports), which always land on the
/// single root navigator with no branch-navigator conflicts.
class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  static const _pages = [
    DashboardPage(),
    AccountsPage(),
    TransactionsPage(),
    ReportsPage(),
    BudgetsPage(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(shellIndexProvider);
    void onTap(int i) => ref.read(shellIndexProvider.notifier).state = i;

    final body = IndexedStack(index: index, children: _pages);
    final width = MediaQuery.sizeOf(context).width;

    return width >= 600
        ? _WideLayout(selectedIndex: index, onTap: onTap, body: body)
        : _NarrowLayout(selectedIndex: index, onTap: onTap, body: body);
  }
}

// ── Wide layout ──────────────────────────────────────────────────────────────

class _WideLayout extends ConsumerWidget {
  const _WideLayout({
    required this.selectedIndex,
    required this.onTap,
    required this.body,
  });

  final int selectedIndex;
  final void Function(int) onTap;
  final Widget body;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sidebarExpanded = ref.watch(sidebarExpandedProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: onTap,
            extended: sidebarExpanded,
            labelType: NavigationRailLabelType.none,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: sidebarExpanded
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.account_balance, color: cs.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Finora',
                          style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    )
                  : Icon(Icons.account_balance, color: cs.primary, size: 26),
            ),
            trailing: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(sidebarExpanded ? Icons.chevron_left : Icons.chevron_right),
                    tooltip: sidebarExpanded ? 'Collapse sidebar' : 'Expand sidebar',
                    onPressed: () {
                      ref.read(sidebarExpandedProvider.notifier).state = !sidebarExpanded;
                    },
                  ),
                  const SizedBox(height: 8),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    tooltip: 'Settings',
                    onPressed: () => context.push('/settings'),
                  ),
                ],
              ),
            ),
            destinations: _destinations
                .map(
                  (d) => NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
                )
                .toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: body),
        ],
      ),
    );
  }
}

// ── Narrow layout ────────────────────────────────────────────────────────────

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout({
    required this.selectedIndex,
    required this.onTap,
    required this.body,
  });

  final int selectedIndex;
  final void Function(int) onTap;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onTap,
        destinations: _destinations
            .map(
              (d) => NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

