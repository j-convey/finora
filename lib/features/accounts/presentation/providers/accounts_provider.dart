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

  void clear() {
    state = [];
  }
}

final accountsProvider =
    StateNotifierProvider<AccountsNotifier, List<AccountModel>>(
  (ref) => AccountsNotifier(ref),
);

