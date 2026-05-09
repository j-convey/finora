import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/setup_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/reports/presentation/pages/reports_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/subscriptions/presentation/pages/subscriptions_page.dart';
import '../../shared/widgets/adaptive_scaffold.dart';

/// A [ChangeNotifier] that pings GoRouter whenever [AuthStatus] changes.
/// Using this as [GoRouter.refreshListenable] means the router is created
/// *once* and re-evaluates its redirect — rather than being recreated from
/// scratch — which reliably triggers navigation after login / logout.
class _AuthStatusNotifier extends ChangeNotifier {
  _AuthStatusNotifier(Ref ref) {
    ref.listen<AuthStatus>(
      authProvider.select((s) => s.status),
      (_, _) => notifyListeners(),
    );
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthStatusNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/setup',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final loc = state.matchedLocation;

      // Still initialising — don't redirect yet.
      if (authState.status == AuthStatus.unknown) return null;

      final isAuthRoute = loc == '/setup';

      if (authState.status == AuthStatus.unauthenticated && !isAuthRoute) {
        return '/setup';
      }

      if (authState.status == AuthStatus.authenticated && isAuthRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/setup',
        builder: (context, state) => const SetupPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainShell(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsPage(),
      ),
      GoRoute(
        path: '/subscriptions',
        builder: (context, state) => const SubscriptionsPage(),
      ),
    ],
  );
});

