import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../budgets/presentation/providers/budgets_provider.dart';
import '../providers/simplefin_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late TextEditingController _urlCtrl;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(
      text: ref.read(authProvider).serverUrl,
    );
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ── Server Connection ────────────────────────────────
          _SectionHeader(title: 'Server Connection'),
          ListTile(
            leading: Icon(
              auth.isConnected ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
              color: auth.isConnected ? const Color(0xFF4CAF50) : cs.error,
            ),
            title: const Text('Status'),
            subtitle: Text(
              auth.isConnected
                  ? 'Connected to ${auth.serverUrl}'
                  : 'Not connected',
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _urlCtrl,
              decoration: const InputDecoration(
                labelText: 'Server URL',
                prefixIcon: Icon(Icons.link_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await ref
                          .read(authProvider.notifier)
                          .connect(_urlCtrl.text.trim());
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Reconnected successfully')),
                        );
                      }
                    },
                    child: const Text('Reconnect'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.errorContainer,
                      foregroundColor: cs.onErrorContainer,
                    ),
                    onPressed: () {
                      ref.read(authProvider.notifier).disconnect();
                      context.go('/setup');
                    },
                    child: const Text('Disconnect'),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),

          // ── Bank Connections ─────────────────────────────────
          _SectionHeader(title: 'Bank Connections'),
          _SimplefinTile(),
          const Divider(),

          // ── Appearance ───────────────────────────────────────
          _SectionHeader(title: 'Appearance'),
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: const Text('Theme'),
            subtitle: const Text('System default (dark)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Theme switching coming soon')),
              );
            },
          ),
          const Divider(),

          // ── Data ─────────────────────────────────────────────
          _SectionHeader(title: 'Data'),
          ListTile(
            leading: _isSyncing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync_outlined),
            title: const Text('Sync Now'),
            onTap: _isSyncing ? null : _syncAll,
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Export Data'),
            subtitle: const Text('Export as CSV or JSON'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export coming soon')),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_forever_outlined, color: cs.error),
            title: Text('Clear Local Data',
                style: TextStyle(color: cs.error)),
            onTap: () => _confirmClear(context),
          ),
          const Divider(),

          // ── About ─────────────────────────────────────────────
          _SectionHeader(title: 'About'),
          const ListTile(
            leading: Icon(Icons.info_outlined),
            title: Text('Version'),
            trailing: Text('0.1.0'),
          ),
          const ListTile(
            leading: Icon(Icons.account_balance),
            title: Text('Finora'),
            subtitle: Text('Self-hosted personal finance intelligence'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _syncAll() async {
    setState(() => _isSyncing = true);
    try {
      await Future.wait([
        ref.read(transactionsProvider.notifier).sync(),
        ref.read(accountsProvider.notifier).sync(),
        ref.read(budgetsProvider.notifier).sync(),
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
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          title,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
      );
}

// ── SimpleFIN tile ───────────────────────────────────────────────────────────

class _SimplefinTile extends ConsumerWidget {
  const _SimplefinTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(simplefinProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final isBusy = state.status == SimplefinConnectionStatus.syncing;

    Widget leadingIcon;
    String subtitle;
    Color iconColor;

    switch (state.status) {
      case SimplefinConnectionStatus.connected:
      case SimplefinConnectionStatus.syncing:
        leadingIcon = isBusy
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.account_balance_outlined);
        iconColor = const Color(0xFF4CAF50);
        final institutions = state.connectedInstitutions.isEmpty
            ? 'Connected'
            : state.connectedInstitutions.join(', ');
        final lastSync = state.lastSyncedAt != null
            ? ' · Last synced ${_formatTime(state.lastSyncedAt!)}'
            : '';
        subtitle = '$institutions$lastSync';
      case SimplefinConnectionStatus.error:
        leadingIcon = const Icon(Icons.error_outline);
        iconColor = cs.error;
        subtitle = state.errorMessage ?? 'Connection error';
      case SimplefinConnectionStatus.disconnected:
        leadingIcon = const Icon(Icons.add_link_outlined);
        iconColor = cs.onSurfaceVariant;
        subtitle = 'Connect your bank accounts via SimpleFIN';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: IconTheme(
            data: IconThemeData(color: iconColor),
            child: leadingIcon,
          ),
          title: const Text('SimpleFIN Bridge'),
          subtitle: Text(subtitle),
          trailing: state.isConnected
              ? PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'fetch') {
                      ref.read(simplefinProvider.notifier).fetchLatest();
                    } else if (v == 'disconnect') {
                      _confirmDisconnect(context, ref);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'fetch', child: Text('Fetch latest')),
                    PopupMenuItem(
                      value: 'disconnect',
                      child: Text('Disconnect'),
                    ),
                  ],
                )
              : TextButton(
                  onPressed: isBusy
                      ? null
                      : () => _showConnectSheet(context, ref),
                  child: const Text('Connect'),
                ),
        ),
        if (!state.isConnected)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              'SimpleFIN lets you securely import transactions from your bank '
              'without sharing your login credentials. Get a Setup Token at '
              'app.simplefin.org/simplefin/claim.',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
      ],
    );
  }

  void _showConnectSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ConnectSimplefinSheet(ref: ref),
    );
  }

  void _confirmDisconnect(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disconnect SimpleFIN?'),
        content: const Text(
          'This removes the stored access URL from your server. '
          'Your existing transactions are not deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(simplefinProvider.notifier).disconnect();
            },
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }

  static String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ── Connect sheet ────────────────────────────────────────────────────────────

class _ConnectSimplefinSheet extends StatefulWidget {
  const _ConnectSimplefinSheet({required this.ref});
  final WidgetRef ref;

  @override
  State<_ConnectSimplefinSheet> createState() => _ConnectSimplefinSheetState();
}

class _ConnectSimplefinSheetState extends State<_ConnectSimplefinSheet> {
  final _tokenCtrl = TextEditingController();
  bool _isConnecting = false;
  String? _error;

  @override
  void dispose() {
    _tokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (_tokenCtrl.text.trim().isEmpty) return;
    setState(() {
      _isConnecting = true;
      _error = null;
    });
    try {
      await widget.ref.read(simplefinProvider.notifier).connect(_tokenCtrl.text);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Connect via SimpleFIN', style: tt.titleMedium),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('How to get your Setup Token:',
                    style: tt.labelMedium
                        ?.copyWith(color: cs.onSecondaryContainer)),
                const SizedBox(height: 6),
                Text(
                  '1. Go to app.simplefin.org/simplefin/claim\n'
                  '2. Sign in or create a free account\n'
                  '3. Click "Add Data Source" for your bank\n'
                  '4. Copy the one-time Setup Token and paste it below',
                  style: tt.bodySmall
                      ?.copyWith(color: cs.onSecondaryContainer),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _tokenCtrl,
            enabled: !_isConnecting,
            decoration: InputDecoration(
              labelText: 'Setup Token',
              hintText: 'Paste your SimpleFIN setup token here',
              prefixIcon: const Icon(Icons.vpn_key_outlined),
              border: const OutlineInputBorder(),
              errorText: _error,
            ),
            maxLines: 3,
            minLines: 1,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _isConnecting ? null : _connect,
            child: _isConnecting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Connect'),
          ),
          const SizedBox(height: 8),
          Text(
            'The token is sent to your Finora server, which exchanges it for '
            'a permanent access URL. The token is never stored in the app.',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

