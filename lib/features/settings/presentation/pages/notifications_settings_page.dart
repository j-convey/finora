import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/notification_preferences_provider.dart';

class NotificationsSettingsPage extends ConsumerStatefulWidget {
  const NotificationsSettingsPage({super.key});

  @override
  ConsumerState<NotificationsSettingsPage> createState() =>
      _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState
    extends ConsumerState<NotificationsSettingsPage> {
  late final TextEditingController _thresholdController;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(notificationPreferencesProvider);
    _thresholdController = TextEditingController(
      text: prefs.thresholdAmount.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _thresholdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(notificationPreferencesProvider);
    final notifier = ref.read(notificationPreferencesProvider.notifier);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.notifications_outlined, size: 20),
              const SizedBox(width: 12),
              Text('Charge alerts', style: tt.titleMedium),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Get notified when new charges are detected after a sync.',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          SegmentedButton<NotifyOn>(
            segments: const [
              ButtonSegment(
                value: NotifyOn.never,
                icon: Icon(Icons.notifications_off_outlined),
                label: Text('Off'),
              ),
              ButtonSegment(
                value: NotifyOn.always,
                icon: Icon(Icons.notifications_active_outlined),
                label: Text('All'),
              ),
              ButtonSegment(
                value: NotifyOn.aboveThreshold,
                icon: Icon(Icons.attach_money_outlined),
                label: Text('Above'),
              ),
            ],
            selected: {prefs.notifyOn},
            onSelectionChanged: (selection) =>
                notifier.update(prefs.copyWith(notifyOn: selection.first)),
            showSelectedIcon: false,
          ),
          if (prefs.notifyOn == NotifyOn.aboveThreshold) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Text('Notify for charges above  ', style: tt.bodyMedium),
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _thresholdController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      prefixText: '\$',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (val) {
                      final amount = double.tryParse(val);
                      if (amount != null && amount >= 0) {
                        notifier.update(
                          prefs.copyWith(thresholdAmount: amount),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
