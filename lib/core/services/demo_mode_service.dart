import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/providers/theme_provider.dart';
import '../../features/accounts/presentation/providers/accounts_provider.dart';
import '../../features/accounts/presentation/providers/net_worth_history_provider.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/budgets/presentation/providers/budgets_provider.dart';
import '../../features/subscriptions/presentation/providers/subscriptions_provider.dart';
import '../../features/transactions/presentation/providers/categories_provider.dart';
import '../../features/transactions/presentation/providers/transactions_provider.dart';
import '../network/api_client.dart';
import '../providers/demo_mode_provider.dart';

final demoModeServiceProvider = Provider<DemoModeService>((ref) {
  final prefs = ref.watch(prefsProvider);
  return DemoModeService(ref, prefs);
});

class DemoModeService {
  DemoModeService(this._ref, this._prefs);

  final Ref _ref;
  final SharedPreferences _prefs;

  static const _kDemoModeKey = 'demo_mode_active';
  static const _kPreDemoAuthKey = 'pre_demo_was_authenticated';

  bool isDemoModeActive() => _prefs.getBool(_kDemoModeKey) ?? false;

  Future<void> toggleDemoMode(bool enable) async {
    if (enable) {
      await _enableDemo();
    } else {
      await _disableDemo();
    }
  }

  Future<void> _enableDemo() async {
    final wasAuthenticated = _ref.read(authProvider).isAuthenticated;
    await _prefs.setBool(_kPreDemoAuthKey, wasAuthenticated);
    await _prefs.setBool(_kDemoModeKey, true);

    _ref.read(demoModeProvider.notifier).updateState(true);

    try {
      final dio = _ref.read(apiClientProvider);
      await dio.post('/api/demo/enable');
    } catch (_) {
      // Ignore errors, we still want to toggle locally.
    }

    await clearCachesAndRefetch();
  }

  Future<void> _disableDemo() async {
    final wasAuthBefore = _prefs.getBool(_kPreDemoAuthKey) ?? false;
    await _prefs.setBool(_kDemoModeKey, false);

    _ref.read(demoModeProvider.notifier).updateState(false);

    try {
      final dio = _ref.read(apiClientProvider);
      await dio.post('/api/demo/disable');
    } catch (_) {
      // Ignore errors.
    }

    await _clearAllCaches();

    if (wasAuthBefore) {
      await clearCachesAndRefetch();
    } else {
      await _ref.read(authProvider.notifier).logout();
    }
  }

  Future<void> _clearAllCaches() async {
    // Note: since Riverpod handles caching internally,
    // refreshing providers is usually how we reset/refetch data.
    // However, if we need to explicitly clear things, we can do it here.
    // Sync calls down below accomplish this implicitly.
  }

  Future<void> clearCachesAndRefetch() async {
    try {
      await Future.wait([
        _ref.read(accountsProvider.notifier).sync(),
        _ref.read(transactionsProvider.notifier).sync(),
        _ref.read(budgetsProvider.notifier).sync(),
        _ref.read(subscriptionsProvider.notifier).sync(),
        _ref.read(categoryGroupsProvider.notifier).sync(),
        _ref.read(netWorthHistoryProvider.notifier).fetch(),
      ]);
    } catch (_) {
      // Swallow errors (e.g. no connectivity).
    }
  }
}
