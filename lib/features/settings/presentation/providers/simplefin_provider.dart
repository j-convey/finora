import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/providers/notification_preferences_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../budgets/presentation/providers/budgets_provider.dart';
import '../../../subscriptions/presentation/providers/subscriptions_provider.dart';
import '../../../transactions/presentation/providers/categories_provider.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';

enum SimplefinConnectionStatus { disconnected, connected, syncing, error }

class SimplefinState {
  const SimplefinState({
    this.status = SimplefinConnectionStatus.disconnected,
    this.connectedInstitutions = const [],
    this.lastSyncedAt,
    this.errorMessage,
  });

  final SimplefinConnectionStatus status;
  final List<String> connectedInstitutions;
  final DateTime? lastSyncedAt;
  final String? errorMessage;

  bool get isConnected =>
      status == SimplefinConnectionStatus.connected ||
      status == SimplefinConnectionStatus.syncing;

  SimplefinState copyWith({
    SimplefinConnectionStatus? status,
    List<String>? connectedInstitutions,
    DateTime? lastSyncedAt,
    String? errorMessage,
  }) => SimplefinState(
    status: status ?? this.status,
    connectedInstitutions: connectedInstitutions ?? this.connectedInstitutions,
    lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    errorMessage: errorMessage,
  );
}

class SimplefinNotifier extends StateNotifier<SimplefinState> {
  SimplefinNotifier(this._ref) : super(const SimplefinState()) {
    refreshStatus();
  }

  final Ref _ref;

  /// Called on startup — asks the server if a SimpleFIN access URL is already
  /// stored, so the UI can show the correct connected/disconnected state.
  Future<void> refreshStatus() async {
    try {
      final dio = _ref.read(apiClientProvider);
      final res = await dio.get<Map<String, dynamic>>('/api/simplefin/status');
      final data = res.data!;
      if (data['connected'] == true) {
        state = state.copyWith(
          status: SimplefinConnectionStatus.connected,
          connectedInstitutions: List<String>.from(
            data['institutions'] as List? ?? [],
          ),
          lastSyncedAt: data['last_synced_at'] != null
              ? DateTime.tryParse(data['last_synced_at'] as String)
              : null,
        );
      } else {
        state = const SimplefinState();
      }
    } catch (_) {
      // Server unreachable or not yet set up — stay disconnected, silently.
    }
  }

  /// User pastes their one-time SimpleFIN setup token here.
  /// The server exchanges it for a permanent access URL and stores it.
  Future<void> connect(String setupToken) async {
    state = state.copyWith(
      status: SimplefinConnectionStatus.syncing,
      errorMessage: null,
    );
    try {
      final dio = _ref.read(apiClientProvider);
      final res = await dio.post<Map<String, dynamic>>(
        '/api/simplefin/connect',
        data: {'setup_token': setupToken.trim()},
      );
      final data = res.data!;
      state = state.copyWith(
        status: SimplefinConnectionStatus.connected,
        connectedInstitutions: List<String>.from(
          data['institutions'] as List? ?? [],
        ),
        lastSyncedAt: DateTime.now(),
      );
      _syncAll();
    } catch (e) {
      final message = e is DioException ? _extractError(e) : e.toString();
      state = state.copyWith(
        status: SimplefinConnectionStatus.error,
        errorMessage: message,
      );
      rethrow;
    }
  }

  /// Triggers a fresh fetch from SimpleFIN via the server.
  /// The server pulls new transactions/balances and they appear on next sync.
  Future<void> fetchLatest() async {
    state = state.copyWith(status: SimplefinConnectionStatus.syncing);
    try {
      final dio = _ref.read(apiClientProvider);
      final res = await dio.post<Map<String, dynamic>>('/api/simplefin/fetch');
      state = state.copyWith(
        status: SimplefinConnectionStatus.connected,
        lastSyncedAt: DateTime.now(),
      );

      // Refresh all local data so new transactions/balances appear immediately.
      _syncAll();

      // Fire local notifications for new charges that exceed the threshold.
      final notifPrefs = _ref.read(notificationPreferencesProvider);
      if (notifPrefs.notifyOn != NotifyOn.never && res.data != null) {
        final newTxns = (res.data!['new_transactions'] as List? ?? []);
        for (final tx in newTxns) {
          final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
          if (notifPrefs.shouldNotify(amount)) {
            await NotificationService.showChargeNotification(
              title: tx['title'] as String? ?? 'New charge',
              amount: amount,
              accountName: tx['account_name'] as String?,
            );
          }
        }
      }
    } catch (e) {
      final message = e is DioException ? _extractError(e) : e.toString();
      state = state.copyWith(
        status: SimplefinConnectionStatus.error,
        errorMessage: message,
      );
      rethrow;
    }
  }

  /// Removes the stored access URL from the server.
  Future<void> disconnect() async {
    try {
      final dio = _ref.read(apiClientProvider);
      await dio.delete<void>('/api/simplefin/disconnect');
    } catch (_) {
      // Best-effort
    }
    state = const SimplefinState();
  }

  /// Resets the local state without calling the server.
  void clear() {
    state = const SimplefinState();
  }

  /// Refreshes all cached application data from the server.
  void _syncAll() {
    Future.wait([
      _ref.read(accountsProvider.notifier).sync(),
      _ref.read(transactionsProvider.notifier).sync(),
      _ref.read(budgetsProvider.notifier).sync(),
      _ref.read(subscriptionsProvider.notifier).sync(),
      _ref.read(categoryGroupsProvider.notifier).sync(),
    ]).catchError((_) => []);
  }

  static String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      return (data['error'] ?? data['detail'] ?? e.message).toString();
    }
    return e.message ?? 'Unknown error';
  }
}

final simplefinProvider =
    StateNotifierProvider<SimplefinNotifier, SimplefinState>(
      (ref) => SimplefinNotifier(ref),
    );
