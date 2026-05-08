import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/models/account_model.dart';

class AccountsNotifier extends StateNotifier<List<AccountModel>> {
  AccountsNotifier(this._ref) : super([]);

  final Ref _ref;

  Future<void> sync() async {
    final dio = _ref.read(apiClientProvider);
    final response = await dio.get<List<dynamic>>('/api/accounts');
    state = (response.data ?? [])
        .map((j) => AccountModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateAccountType(String accountId, AccountType type) async {
    final typeStr = switch (type) {
      AccountType.checking => 'checking',
      AccountType.savings => 'savings',
      AccountType.creditCard => 'credit_card',
      AccountType.investment => 'investment',
      AccountType.cash => 'cash',
    };

    // Snapshot previous state so we can revert on failure.
    final previous = state;

    // Update immediately so the UI regroups at once.
    state = state
        .map((a) => a.id == accountId
            ? AccountModel(
                id: a.id,
                name: a.name,
                type: type,
                balance: a.balance,
                availableBalance: a.availableBalance,
                institutionName: a.institutionName,
                color: a.color,
                updatedAt: a.updatedAt,
              )
            : a)
        .toList();

    try {
      final dio = _ref.read(apiClientProvider);
      await dio.patch<void>('/api/accounts/$accountId', data: {'type': typeStr});
    } catch (_) {
      // Revert to original state if the API call fails.
      state = previous;
      rethrow;
    }
  }

  void clear() {
    state = [];
  }
}

final accountsProvider =
    StateNotifierProvider<AccountsNotifier, List<AccountModel>>(
  (ref) => AccountsNotifier(ref),
);

