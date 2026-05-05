import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/setup_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/transactions/presentation/pages/transactions_page.dart';
import '../../features/accounts/presentation/pages/accounts_page.dart';
import '../../features/budgets/presentation/pages/budgets_page.dart';
import '../../features/ai_insights/presentation/pages/ai_insights_page.dart';
import '../../features/reports/presentation/pages/reports_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../shared/widgets/adaptive_scaffold.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/setup',
    routes: [
      GoRoute(
        path: '/setup',
        builder: (context, state) => const SetupPage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AdaptiveScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardPage(),
                routes: [
                  // Nested inside the dashboard branch so it pushes on the
                  // branch navigator rather than the root — avoids a
                  // StatefulShellRoute navigator conflict that caused freezes.
                  GoRoute(
                    path: 'reports',
                    builder: (context, state) => const ReportsPage(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/transactions',
                builder: (context, state) => const TransactionsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/accounts',
                builder: (context, state) => const AccountsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/budgets',
                builder: (context, state) => const BudgetsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/ai',
                builder: (context, state) => const AiInsightsPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
