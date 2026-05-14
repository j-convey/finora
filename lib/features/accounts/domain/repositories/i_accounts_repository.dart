import '../entities/account.dart';

abstract class IAccountsRepository {
  Future<List<Account>> getAccounts();
  Future<void> updateAccountType(String accountId, AccountType type);
}
