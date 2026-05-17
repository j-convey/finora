import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/providers/theme_provider.dart';
import '../../../../core/providers/demo_mode_provider.dart';
import '../../../../core/providers/notification_preferences_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/simplefin_provider.dart';
import '../../../../shared/widgets/add_transaction_sheet.dart';
import 'about_settings_page.dart';
import 'account_settings_page.dart';
import 'appearance_settings_page.dart';
import 'bank_connections_page.dart';
import 'data_settings_page.dart';
import 'demo_mode_settings_page.dart';
import 'notifications_settings_page.dart';
import 'profile_settings_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final themeMode = ref.watch(themeModeProvider);
    final notifPrefs = ref.watch(notificationPreferencesProvider);
    final isDemoMode = ref.watch(demoModeProvider);
    final simplefin = ref.watch(simplefinProvider);
    final cs = Theme.of(context).colorScheme;

    final themeLabel = switch (themeMode) {
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
      ThemeMode.system => 'System default',
    };

    final notifLabel = switch (notifPrefs.notifyOn) {
      NotifyOn.never => 'Off',
      NotifyOn.always => 'All charges',
      NotifyOn.aboveThreshold =>
        'Above \$${notifPrefs.thresholdAmount.toStringAsFixed(0)}',
    };

    final bankLabel = simplefin.isConnected
        ? (simplefin.connectedInstitutions.isEmpty
            ? 'Connected'
            : simplefin.connectedInstitutions.join(', '))
        : 'Not connected';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => showAddTransactionSheet(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        children: [
          // ── Profile ──────────────────────────────────────────
          ListTile(
            leading: CircleAvatar(
              backgroundImage: user?.profilePictureUrl != null
                  ? NetworkImage(user!.profilePictureUrl!)
                  : null,
              child: user?.profilePictureUrl == null
                  ? const Icon(Icons.person_outline)
                  : null,
            ),
            title: Text(user?.displayName ?? 'Set your name'),
            subtitle: Text(user?.email ?? 'Tap to edit profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileSettingsPage()),
            ),
          ),
          const Divider(),

          // ── Server & Account ──────────────────────────────────
          ListTile(
            leading: Icon(
              Icons.dns_outlined,
              color: auth.isAuthenticated ? cs.primary : cs.onSurfaceVariant,
            ),
            title: const Text('Server & Account'),
            subtitle: Text(
              auth.isAuthenticated ? auth.serverUrl : 'Not connected',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AccountSettingsPage()),
            ),
          ),
          const Divider(),

          // ── Bank Connections ──────────────────────────────────
          ListTile(
            leading: Icon(
              Icons.account_balance_outlined,
              color: simplefin.isConnected
                  ? const Color(0xFF4CAF50)
                  : cs.onSurfaceVariant,
            ),
            title: const Text('Bank Connections'),
            subtitle: Text(bankLabel),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BankConnectionsPage()),
            ),
          ),
          const Divider(),

          // ── Appearance ────────────────────────────────────────
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Appearance'),
            subtitle: Text(themeLabel),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AppearanceSettingsPage()),
            ),
          ),
          const Divider(),

          // ── Notifications ─────────────────────────────────────
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            subtitle: Text(notifLabel),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const NotificationsSettingsPage()),
            ),
          ),
          const Divider(),

          // ── Data & Backup ─────────────────────────────────────
          ListTile(
            leading: const Icon(Icons.storage_outlined),
            title: const Text('Data & Backup'),
            subtitle: const Text('Sync, export and import your data'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DataSettingsPage()),
            ),
          ),
          const Divider(),

          // ── Demo Mode ─────────────────────────────────────────
          ListTile(
            leading: Icon(
              Icons.science_outlined,
              color: isDemoMode ? const Color(0xFFE65100) : null,
            ),
            title: Text(
              'Demo Mode',
              style:
                  isDemoMode ? const TextStyle(color: Color(0xFFE65100)) : null,
            ),
            subtitle: Text(isDemoMode
                ? 'Active — tap to exit'
                : 'Explore with sample data'),
            trailing: isDemoMode
                ? const Icon(Icons.circle, color: Color(0xFFE65100), size: 10)
                : const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DemoModeSettingsPage()),
            ),
          ),
          const Divider(),

          // ── About ─────────────────────────────────────────────
          ListTile(
            leading: const Icon(Icons.info_outlined),
            title: const Text('About'),
            subtitle: const Text('Version 0.1.0'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutSettingsPage()),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
