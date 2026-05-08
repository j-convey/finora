import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/hide_amounts_provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/masked_amount.dart';
import '../../data/models/account_model.dart';

class AssetLiabilitySummaryPanel extends ConsumerWidget {
  const AssetLiabilitySummaryPanel({required this.accounts, super.key});

  final List<AccountModel> accounts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final hidden = ref.watch(hideAmountsProvider);

    final assets = accounts
        .where((a) => a.balance > 0)
        .fold<double>(0, (sum, a) => sum + a.balance);
    final liabilities = accounts
        .where((a) => a.balance < 0)
        .fold<double>(0, (sum, a) => sum + a.balance.abs());

    // Group by type for display purposes
    final assetsByType = <AccountType, double>{};
    final liabilitiesByType = <AccountType, double>{};

    for (final account in accounts) {
      if (account.balance > 0) {
        assetsByType.update(
          account.type,
          (v) => v + account.balance,
          ifAbsent: () => account.balance,
        );
      } else if (account.balance < 0) {
        liabilitiesByType.update(
          account.type,
          (v) => v + account.balance.abs(),
          ifAbsent: () => account.balance.abs(),
        );
      }
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Summary', style: tt.titleMedium),
          const SizedBox(height: 16),
          // Assets section
          Text('Assets', style: tt.labelMedium),
          const SizedBox(height: 8),
          // Stacked bar chart for assets breakdown
          Container(
            height: 16,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: cs.outline),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Row(
                children: _buildAssetBars(assetsByType, assets),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Asset type breakdown
          ...assetsByType.entries.map((entry) {
            return _AssetTypeItem(
              type: entry.key,
              amount: entry.value,
              total: assets,
            );
          }),
          const SizedBox(height: 20),
          // Total assets
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withAlpha(25),
              border: Border.all(color: const Color(0xFF4CAF50)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Assets', style: tt.labelMedium),
                Text(
                  hidden ? '••••••' : formatCurrency(assets),
                  style: tt.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Liabilities section
          Text('Liabilities', style: tt.labelMedium),
          const SizedBox(height: 8),
          // Stacked bar chart for liabilities breakdown
          Container(
            height: 16,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: cs.outline),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Row(
                children: _buildLiabilityBars(liabilitiesByType, liabilities),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Liability type breakdown
          ...liabilitiesByType.entries.map((entry) {
            return _LiabilityTypeItem(
              type: entry.key,
              amount: entry.value,
              total: liabilities,
            );
          }),
          const SizedBox(height: 20),
          // Total liabilities
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEF5350).withAlpha(25),
              border: Border.all(color: const Color(0xFFEF5350)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Liabilities', style: tt.labelMedium),
                Text(
                  hidden ? '••••••' : formatCurrency(liabilities),
                  style: tt.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFEF5350),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Download CSV button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Implement CSV download
              },
              icon: const Icon(Icons.download_outlined),
              label: const Text('Download CSV'),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAssetBars(Map<AccountType, double> assets, double total) {
    final colors = {
      AccountType.cash: Colors.blue,
      AccountType.checking: Colors.green,
      AccountType.savings: Colors.teal,
      AccountType.investment: Colors.purple,
      AccountType.creditCard: Colors.red,
    };

    return assets.entries.map((entry) {
      final percent = total > 0 ? (entry.value / total) * 100 : 0;
      return Expanded(
        flex: percent.toInt(),
        child: Container(
          color: colors[entry.key] ?? Colors.grey,
        ),
      );
    }).toList();
  }

  List<Widget> _buildLiabilityBars(
    Map<AccountType, double> liabilities,
    double total,
  ) {
    final colors = {
      AccountType.creditCard: Color(0xFFEF5350),
      AccountType.cash: Colors.orange,
      AccountType.checking: Colors.yellow,
      AccountType.savings: Colors.amber,
      AccountType.investment: Colors.red,
    };

    return liabilities.entries.map((entry) {
      final percent = total > 0 ? (entry.value / total) * 100 : 0;
      return Expanded(
        flex: percent.toInt(),
        child: Container(
          color: colors[entry.key] ?? Colors.grey,
        ),
      );
    }).toList();
  }
}

class _AssetTypeItem extends StatelessWidget {
  const _AssetTypeItem({
    required this.type,
    required this.amount,
    required this.total,
  });

  final AccountType type;
  final double amount;
  final double total;

  @override
  Widget build(BuildContext context) {
    final percent = total > 0 ? (amount / total) * 100 : 0;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${AccountModel.labelForType(type)} ${percent.toStringAsFixed(0)}%',
            style: tt.labelSmall,
          ),
          MaskedAmount(
            amount,
            style: tt.labelSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _LiabilityTypeItem extends StatelessWidget {
  const _LiabilityTypeItem({
    required this.type,
    required this.amount,
    required this.total,
  });

  final AccountType type;
  final double amount;
  final double total;

  @override
  Widget build(BuildContext context) {
    final percent = total > 0 ? (amount / total) * 100 : 0;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${AccountModel.labelForType(type)} ${percent.toStringAsFixed(0)}%',
            style: tt.labelSmall,
          ),
          MaskedAmount(
            amount,
            style: tt.labelSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
