import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finora/core/network/api_client.dart';
import 'package:finora/features/accounts/domain/entities/account.dart';
import 'package:finora/features/accounts/domain/repositories/i_accounts_repository.dart';
import 'package:finora/features/accounts/data/repositories/accounts_repository_impl.dart';

final accountsRepositoryProvider = Provider<IAccountsRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  return AccountsRepositoryImpl(dio);
});

class AccountsNotifier extends StateNotifier<List<Account>> {
  AccountsNotifier(this._ref) : super([]);

  final Ref _ref;

  Future<void> sync() async {
    final repository = _ref.read(accountsRepositoryProvider);
    state = await repository.getAccounts();
  }

  Future<void> updateAccountType(String accountId, AccountType type) async {
    final repository = _ref.read(accountsRepositoryProvider);

    // Snapshot previous state so we can revert on failure.
    final previous = state;

    // Update immediately so the UI regroups at once.
    state = state
        .map((a) => a.id == accountId ? a.copyWith(type: type) : a)
        .toList();

    try {
      await repository.updateAccountType(accountId, type);
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

final accountsProvider = StateNotifierProvider<AccountsNotifier, List<Account>>(
  (ref) => AccountsNotifier(ref),
);
