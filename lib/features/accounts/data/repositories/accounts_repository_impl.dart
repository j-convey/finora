import 'package:dio/dio.dart';
import '../../domain/entities/account.dart';
import '../../domain/repositories/i_accounts_repository.dart';
import '../models/account_model.dart';

class AccountsRepositoryImpl implements IAccountsRepository {
  AccountsRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<Account>> getAccounts() async {
    final response = await _dio.get<List<dynamic>>('/api/accounts');
    return (response.data ?? [])
        .map((j) => AccountModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> updateAccountType(String accountId, AccountType type) async {
    await _dio.patch<void>(
      '/api/accounts/$accountId',
      data: {'type': type.toJson()},
    );
  }
}
