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
    print('DEBUG [DemoModeService]: toggleDemoMode(enable: $enable)');
    if (enable) {
      await _enableDemo();
    } else {
      await _disableDemo();
    }
  }

  Future<void> _enableDemo() async {
    print('DEBUG [DemoModeService]: Entering _enableDemo()');
    final wasAuthenticated = _ref.read(authProvider).status == AuthStatus.authenticated;
    print('DEBUG [DemoModeService]: _enableDemo() - pre-demo wasAuthenticated (real): $wasAuthenticated');

    await _prefs.setBool(_kPreDemoAuthKey, wasAuthenticated);
    await _prefs.setBool(_kDemoModeKey, true);
    print('DEBUG [DemoModeService]: _enableDemo() - Saved preferences');

    _ref.read(demoModeProvider.notifier).updateState(true);
    print('DEBUG [DemoModeService]: _enableDemo() - Updated Riverpod state to true');

    try {
      final dio = _ref.read(apiClientProvider);
      print('DEBUG [DemoModeService]: _enableDemo() - Triggering POST /api/demo/enable');
      final response = await dio.post('/api/demo/enable');
      print('DEBUG [DemoModeService]: _enableDemo() - Server response: ${response.statusCode}');
    } catch (e, st) {
      print('DEBUG [DemoModeService]: _enableDemo() - Server error (ignored): $e');
      print('DEBUG [DemoModeService]: _enableDemo() - Server error stack: $st');
      // Ignore errors, we still want to toggle locally.
    }

    print('DEBUG [DemoModeService]: _enableDemo() - Clearing caches and refetching data');
    await clearCachesAndRefetch();
    print('DEBUG [DemoModeService]: _enableDemo() - Finished');
  }

  Future<void> _disableDemo() async {
    print('DEBUG [DemoModeService]: Entering _disableDemo()');
    final wasAuthBefore = _prefs.getBool(_kPreDemoAuthKey) ?? false;
    print('DEBUG [DemoModeService]: _disableDemo() - pre-demo wasAuthBefore: $wasAuthBefore');

    await _prefs.setBool(_kDemoModeKey, false);
    print('DEBUG [DemoModeService]: _disableDemo() - Saved preference demo_mode_active = false');

    _ref.read(demoModeProvider.notifier).updateState(false);
    print('DEBUG [DemoModeService]: _disableDemo() - Updated Riverpod state to false');

    try {
      final dio = _ref.read(apiClientProvider);
      print('DEBUG [DemoModeService]: _disableDemo() - Triggering POST /api/demo/disable');
      final response = await dio.post('/api/demo/disable');
      print('DEBUG [DemoModeService]: _disableDemo() - Server response: ${response.statusCode}');
    } catch (e, st) {
      print('DEBUG [DemoModeService]: _disableDemo() - Server error (ignored): $e');
      print('DEBUG [DemoModeService]: _disableDemo() - Server error stack: $st');
      // Ignore errors.
    }

    await _clearAllCaches();

    if (wasAuthBefore) {
      print('DEBUG [DemoModeService]: _disableDemo() - User was authenticated before demo, refetching caches');
      await clearCachesAndRefetch();
    } else {
      print('DEBUG [DemoModeService]: _disableDemo() - User was NOT authenticated before demo, logging out');
      await _ref.read(authProvider.notifier).logout();
    }
    print('DEBUG [DemoModeService]: _disableDemo() - Finished');
  }

  Future<void> _clearAllCaches() async {
    // Note: since Riverpod handles caching internally,
    // refreshing providers is usually how we reset/refetch data.
    // However, if we need to explicitly clear things, we can do it here.
    // Sync calls down below accomplish this implicitly.
    print('DEBUG [DemoModeService]: _clearAllCaches() called');
  }

  Future<void> clearCachesAndRefetch() async {
    print('DEBUG [DemoModeService]: clearCachesAndRefetch() called. Refreshing providers...');
    try {
      await Future.wait([
        _ref.read(accountsProvider.notifier).sync(),
        _ref.read(transactionsProvider.notifier).sync(),
        _ref.read(budgetsProvider.notifier).sync(),
        _ref.read(subscriptionsProvider.notifier).sync(),
        _ref.read(categoryGroupsProvider.notifier).sync(),
        _ref.read(netWorthHistoryProvider.notifier).fetch(),
      ]);
      print('DEBUG [DemoModeService]: clearCachesAndRefetch() finished successfully');
    } catch (e, st) {
      print('DEBUG [DemoModeService]: clearCachesAndRefetch() error: $e');
      print('DEBUG [DemoModeService]: clearCachesAndRefetch() stack: $st');
      // Swallow errors (e.g. no connectivity).
      throw e; // RETHROW SO THE UI CATCHES IT
    }
  }
}
