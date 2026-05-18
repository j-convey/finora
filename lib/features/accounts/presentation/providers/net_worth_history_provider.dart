import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/models/net_worth_history_model.dart';

class NetWorthHistoryNotifier
    extends StateNotifier<AsyncValue<NetWorthHistory>> {
  NetWorthHistoryNotifier(this._ref) : super(const AsyncValue.loading());

  final Ref _ref;

  Future<void> fetch() async {
    state = const AsyncValue.loading();
    try {
      final dio = _ref.read(apiClientProvider);
      final response = await dio.get<List<dynamic>>(
        '/api/accounts/net-worth-history',
      );
      final entries = (response.data ?? [])
          .map((j) => NetWorthHistoryEntry.fromJson(j as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(NetWorthHistory(entries: entries));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void clear() {
    state = const AsyncValue.data(NetWorthHistory(entries: []));
  }
}

final netWorthHistoryProvider =
    StateNotifierProvider<NetWorthHistoryNotifier, AsyncValue<NetWorthHistory>>(
      (ref) => NetWorthHistoryNotifier(ref),
    );
