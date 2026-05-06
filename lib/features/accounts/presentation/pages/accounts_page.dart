import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/account_model.dart';
import '../providers/accounts_provider.dart';
import '../providers/net_worth_history_provider.dart';
import '../widgets/asset_liability_summary_panel.dart';
import '../widgets/grouped_accounts_widget.dart';
import '../widgets/net_worth_chart_widget.dart';
import '../widgets/net_worth_summary_widget.dart';

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
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Refresh all',
            onPressed: () {
              ref.read(accountsProvider.notifier).sync();
              ref.read(netWorthHistoryProvider.notifier).fetch();
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_outlined),
            tooltip: 'Add account',
            onPressed: () {
              // TODO: Navigate to add account page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add account feature coming soon')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
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
                NetWorthSummaryWidget(history: history),
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
          GroupedAccountsWidget(accounts: accounts),
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
                        NetWorthSummaryWidget(history: history),
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
                  GroupedAccountsWidget(accounts: accounts),
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
