import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/account_model.dart';
import '../providers/accounts_provider.dart';
import '../providers/net_worth_history_provider.dart';
import '../widgets/asset_liability_summary_panel.dart';
import '../widgets/grouped_accounts_widget.dart';
import '../widgets/net_worth_chart_widget.dart';
import '../widgets/net_worth_summary_widget.dart';
import '../../../../shared/widgets/add_transaction_sheet.dart';
import '../../../../shared/widgets/main_drawer.dart';

class AccountsPage extends ConsumerStatefulWidget {
  const AccountsPage({super.key});

  @override
  ConsumerState<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends ConsumerState<AccountsPage> {
  @override
  void initState() {
    super.initState();
    // Load data on page initialization
    Future.microtask(() {
      ref.read(netWorthHistoryProvider.notifier).fetch();
      ref.read(accountsProvider.notifier).sync();
    });
  }

  @override
  Widget build(BuildContext context) {
    final accountsList = ref.watch(accountsProvider);
    final netWorthHistory = ref.watch(netWorthHistoryProvider);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => showAddTransactionSheet(context),
          ),
        ],
      ),
      drawer: const MainDrawer(),
      body: isMobile
          ? _buildMobileLayout(accountsList, netWorthHistory)
          : _buildDesktopLayout(accountsList, netWorthHistory),
    );
  }

  Widget _buildMobileLayout(
    List<AccountModel> accounts,
    AsyncValue<dynamic> netWorthHistory,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Net worth summary
          netWorthHistory.when(
            data: (history) =>
                NetWorthSummaryWidget(
                  history: history,
                  currentAccounts: accounts,
                ),
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (e, st) => Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text('Error loading net worth: $e'),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Net worth chart
          netWorthHistory.when(
            data: (history) => NetWorthChartWidget(history: history),
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (e, st) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          // Grouped accounts
          GroupedAccountsWidget(
            accounts: accounts,
            onTypeChanged: (account, newType) {
              ref
                  .read(accountsProvider.notifier)
                  .updateAccountType(account.id, newType)
                  .catchError((Object e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update account type: $e')),
                  );
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(
    List<AccountModel> accounts,
    AsyncValue<dynamic> netWorthHistory,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column - main content
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Net worth summary
                  netWorthHistory.when(
                    data: (history) =>
                        NetWorthSummaryWidget(
                          history: history,
                          currentAccounts: accounts,
                        ),
                    loading: () => const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                    error: (e, st) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Text('Error loading net worth: $e'),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Net worth chart
                  netWorthHistory.when(
                    data: (history) =>
                        NetWorthChartWidget(history: history),
                    loading: () => const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                    error: (e, st) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),
                  // Grouped accounts
                  GroupedAccountsWidget(
                    accounts: accounts,
                    onTypeChanged: (account, newType) {
                      ref
                          .read(accountsProvider.notifier)
                          .updateAccountType(account.id, newType)
                          .catchError((Object e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('Failed to update account type: $e')),
                          );
                        }
                      });
                    },
                  ),
                ],

              ),
            ),
          ),
          const SizedBox(width: 16),
          // Right column - summary panel
          SizedBox(
            width: 300,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child:
                    AssetLiabilitySummaryPanel(accounts: accounts),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
