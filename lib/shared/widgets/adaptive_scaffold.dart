import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
  _Destination(label: 'Dashboard', icon: Icons.home_outlined, selectedIcon: Icons.home),
  _Destination(label: 'Transactions', icon: Icons.receipt_long_outlined, selectedIcon: Icons.receipt_long),
  _Destination(label: 'Accounts', icon: Icons.account_balance_wallet_outlined, selectedIcon: Icons.account_balance_wallet),
  _Destination(label: 'Budgets', icon: Icons.donut_large_outlined, selectedIcon: Icons.donut_large),
  _Destination(label: 'AI Insights', icon: Icons.auto_awesome_outlined, selectedIcon: Icons.auto_awesome),
];

/// Wraps the main [StatefulNavigationShell] with an adaptive nav layout:
/// - Wide screens (≥ 600 px) → [NavigationRail] on the left
/// - Narrow screens → [NavigationBar] at the bottom
class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= 600
        ? _WideLayout(shell: navigationShell, onTap: _onTap)
        : _NarrowLayout(shell: navigationShell, onTap: _onTap);
  }
}

// ── Wide layout ─────────────────────────────────────────────────────────────

class _WideLayout extends StatelessWidget {
  const _WideLayout({required this.shell, required this.onTap});

  final StatefulNavigationShell shell;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final extended = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: onTap,
            extended: extended,
            labelType: extended
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: extended
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
            trailing: IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Settings',
              onPressed: () => context.push('/settings'),
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
          Expanded(child: shell),
        ],
      ),
    );
  }
}

// ── Narrow layout ────────────────────────────────────────────────────────────

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout({required this.shell, required this.onTap});

  final StatefulNavigationShell shell;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
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
