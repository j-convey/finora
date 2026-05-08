import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/shell_index_provider.dart';
import '../../app/providers/sidebar_provider.dart';
import '../../core/providers/demo_mode_provider.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/transactions/presentation/pages/transactions_page.dart';
import '../../features/accounts/presentation/pages/accounts_page.dart';
import '../../features/budgets/presentation/pages/budgets_page.dart';
import '../../features/reports/presentation/pages/reports_page.dart';

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
    final isDemoMode = ref.watch(demoModeProvider);

    Widget body = IndexedStack(index: index, children: _pages);

    if (isDemoMode) {
      body = Column(
        children: [
          Material(
            color: const Color(0xFFE65100),
            child: InkWell(
              onTap: () {},
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.science_outlined,
                          size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        'DEMO MODE — sample data only',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(child: IndexedStack(index: index, children: _pages)),
        ],
      );
    }

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

    return Scaffold(
      body: Row(
        children: [
          _Sidebar(
            selectedIndex: selectedIndex,
            onTap: onTap,
            expanded: sidebarExpanded,
            onToggle: () => ref
                .read(sidebarExpandedProvider.notifier)
                .state = !sidebarExpanded,
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: body),
        ],
      ),
    );
  }
}

// ── Custom sidebar ───────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.selectedIndex,
    required this.onTap,
    required this.expanded,
    required this.onToggle,
  });

  final int selectedIndex;
  final void Function(int) onTap;
  final bool expanded;
  final VoidCallback onToggle;

  static const _collapsedWidth = 72.0;
  static const _expandedWidth = 220.0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      width: expanded ? _expandedWidth : _collapsedWidth,
      child: Material(
        color: cs.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Logo ──────────────────────────────────────────────────────
            SizedBox(
              height: 64,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(Icons.account_balance, color: cs.primary, size: 24),
                    if (expanded) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Finora',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 8),
            // ── Nav items ─────────────────────────────────────────────────
            for (var i = 0; i < _destinations.length; i++)
              _SidebarItem(
                icon: _destinations[i].icon,
                selectedIcon: _destinations[i].selectedIcon,
                label: _destinations[i].label,
                selected: selectedIndex == i,
                expanded: expanded,
                onTap: () => onTap(i),
              ),
            const Spacer(),
            const Divider(height: 1),
            const SizedBox(height: 4),
            // ── Settings ──────────────────────────────────────────────────
            _SidebarItem(
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings,
              label: 'Settings',
              selected: false,
              expanded: expanded,
              onTap: () => GoRouter.of(context).push('/settings'),
            ),
            // ── Collapse toggle ───────────────────────────────────────────
            _SidebarItem(
              icon: Icons.keyboard_double_arrow_left_outlined,
              selectedIcon: Icons.keyboard_double_arrow_right_outlined,
              label: 'Collapse',
              selected: false,
              expanded: expanded,
              flipIcon: !expanded,
              onTap: onToggle,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.expanded,
    required this.onTap,
    this.flipIcon = false,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final bool expanded;
  final bool flipIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final iconColor =
        selected ? cs.onSecondaryContainer : cs.onSurfaceVariant;
    final iconWidget = Transform.scale(
      scaleX: flipIcon ? -1 : 1,
      child: Icon(
        selected ? selectedIcon : icon,
        color: iconColor,
        size: 22,
      ),
    );

    return Tooltip(
      message: expanded ? '' : label,
      preferBelow: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 44,
            decoration: BoxDecoration(
              color:
                  selected ? cs.secondaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: expanded ? 12 : 0,
            ),
            child: expanded
                ? Row(
                    children: [
                      SizedBox(
                        width: 32,
                        child: Center(child: iconWidget),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: selected
                                ? cs.onSecondaryContainer
                                : cs.onSurfaceVariant,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(child: iconWidget),
          ),
        ),
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

