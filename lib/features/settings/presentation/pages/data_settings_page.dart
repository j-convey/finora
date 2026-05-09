import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../accounts/presentation/providers/net_worth_history_provider.dart';
import '../../../budgets/presentation/providers/budgets_provider.dart';
import '../../../subscriptions/presentation/providers/subscriptions_provider.dart';
import '../../../transactions/presentation/providers/categories_provider.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../providers/database_backup_provider.dart';

class DataSettingsPage extends ConsumerStatefulWidget {
  const DataSettingsPage({super.key});

  @override
  ConsumerState<DataSettingsPage> createState() => _DataSettingsPageState();
}

class _DataSettingsPageState extends ConsumerState<DataSettingsPage> {
  bool _isSyncing = false;
  bool _isExporting = false;
  bool _isImporting = false;
  bool _isResettingDatabase = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Data & Backup')),
      body: ListView(
        children: [
          // ── Sync ──────────────────────────────────────────────
          _header(context, 'Sync'),
          ListTile(
            leading: _isSyncing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync_outlined),
            title: const Text('Sync Now'),
            subtitle: const Text('Pull the latest data from your server'),
            onTap: _isSyncing ? null : _syncAll,
          ),
          const Divider(),

          // ── Backup ────────────────────────────────────────────
          _header(context, 'Backup'),
          ListTile(
            leading: _isExporting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file_outlined),
            title: const Text('Export Backup'),
            subtitle: const Text('Save a full database snapshot as JSON'),
            onTap: _isExporting ? null : _exportDatabase,
          ),
          ListTile(
            leading: _isImporting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_outlined),
            title: const Text('Import Backup'),
            subtitle: const Text('Restore a previously exported JSON backup'),
            onTap: _isImporting ? null : _confirmImport,
          ),
          const Divider(),

          // ── Danger zone ───────────────────────────────────────
          _header(context, 'Danger Zone'),
          ListTile(
            leading: Icon(Icons.delete_forever_outlined, color: cs.error),
            title: Text('Clear Local Data',
                style: TextStyle(color: cs.error)),
            subtitle: const Text('Removes cached data — server data unaffected'),
            onTap: () => _confirmClear(context),
          ),
          ListTile(
            leading: _isResettingDatabase
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.warning_amber_outlined, color: cs.error),
            title: Text('Reset Server Database',
                style: TextStyle(color: cs.error)),
            subtitle: const Text('Permanently deletes all server data'),
            onTap:
                _isResettingDatabase ? null : () => _confirmServerReset(context),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          title,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
      );

  Future<void> _syncAll() async {
    setState(() => _isSyncing = true);
    try {
      await Future.wait([
        ref.read(transactionsProvider.notifier).sync(),
        ref.read(accountsProvider.notifier).sync(),
        ref.read(budgetsProvider.notifier).sync(),
        ref.read(subscriptionsProvider.notifier).sync(),
        ref.read(netWorthHistoryProvider.notifier).fetch(),
        ref.read(categoriesProvider.notifier).sync(),
      ]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sync complete')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _exportDatabase() async {
    setState(() => _isExporting = true);
    try {
      await ref.read(databaseBackupProvider.notifier).exportDatabase();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _confirmImport() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Backup?'),
        content: const Text(
          'This will replace all server data (accounts, transactions, budgets) '
          'with the contents of the selected backup file. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _importDatabase();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  Future<void> _importDatabase() async {
    setState(() => _isImporting = true);
    try {
      await ref.read(databaseBackupProvider.notifier).importDatabase();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup imported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Local Data?'),
        content: const Text(
            'This will remove all locally cached data. Your server data is unaffected.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _clearLocalCaches();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Local data cleared')),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _confirmServerReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Server Database?'),
        content: const Text(
          'This will permanently delete all data on the server via '
          '/api/admin/reset-database. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _resetServerDatabase();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Reset Database'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetServerDatabase() async {
    setState(() => _isResettingDatabase = true);
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.post<Map<String, dynamic>>(
        '/api/admin/reset-database',
      );
      _clearLocalCaches();
      if (!mounted) return;
      final message = response.data?['message'] as String?;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message ?? 'Server database reset complete')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Database reset failed: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isResettingDatabase = false);
    }
  }

  void _clearLocalCaches() {
    ref.read(transactionsProvider.notifier).clear();
    ref.read(accountsProvider.notifier).clear();
    ref.read(budgetsProvider.notifier).clear();
    ref.read(subscriptionsProvider.notifier).clear();
    ref.read(categoriesProvider.notifier).clear();
    ref.read(netWorthHistoryProvider.notifier).clear();
  }
}
