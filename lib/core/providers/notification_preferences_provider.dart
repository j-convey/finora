import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// When the user wants to be notified about new charges.
enum NotifyOn {
  /// Notifications are disabled.
  never,

  /// Notify for every new charge regardless of amount.
  always,

  /// Notify only when a charge exceeds [NotificationPreferences.thresholdAmount].
  aboveThreshold,
}

class NotificationPreferences {
  const NotificationPreferences({
    this.notifyOn = NotifyOn.never,
    this.thresholdAmount = 50.0,
  });

  final NotifyOn notifyOn;

  /// Dollar threshold used when [notifyOn] is [NotifyOn.aboveThreshold].
  final double thresholdAmount;

  static const _keyNotifyOn = 'notification_notify_on';
  static const _keyThreshold = 'notification_threshold';

  NotificationPreferences copyWith({
    NotifyOn? notifyOn,
    double? thresholdAmount,
  }) => NotificationPreferences(
    notifyOn: notifyOn ?? this.notifyOn,
    thresholdAmount: thresholdAmount ?? this.thresholdAmount,
  );

  /// Returns true if [amount] should trigger a notification.
  bool shouldNotify(double amount) => switch (notifyOn) {
    NotifyOn.never => false,
    NotifyOn.always => true,
    NotifyOn.aboveThreshold => amount >= thresholdAmount,
  };

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyNotifyOn, notifyOn.name);
    await prefs.setDouble(_keyThreshold, thresholdAmount);
  }

  static Future<NotificationPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyNotifyOn);
    final notifyOn = raw != null
        ? NotifyOn.values.firstWhere(
            (e) => e.name == raw,
            orElse: () => NotifyOn.never,
          )
        : NotifyOn.never;
    final threshold = prefs.getDouble(_keyThreshold) ?? 50.0;
    return NotificationPreferences(
      notifyOn: notifyOn,
      thresholdAmount: threshold,
    );
  }
}

class NotificationPreferencesNotifier
    extends StateNotifier<NotificationPreferences> {
  NotificationPreferencesNotifier() : super(const NotificationPreferences()) {
    _load();
  }

  Future<void> _load() async {
    state = await NotificationPreferences.load();
  }

  Future<void> update(NotificationPreferences prefs) async {
    state = prefs;
    await prefs.save();
  }
}

final notificationPreferencesProvider =
    StateNotifierProvider<
      NotificationPreferencesNotifier,
      NotificationPreferences
    >((_) => NotificationPreferencesNotifier());
