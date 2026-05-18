import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/providers/theme_provider.dart';

/// Whether the app is currently showing demo data instead of real server data.
final demoModeProvider = StateNotifierProvider<DemoModeNotifier, bool>((ref) {
  final prefs = ref.watch(prefsProvider);
  return DemoModeNotifier(prefs);
});

class DemoModeNotifier extends StateNotifier<bool> {
  DemoModeNotifier(SharedPreferences prefs)
      : super(prefs.getBool('demo_mode_active') ?? false);

  void updateState(bool isActive) {
    state = isActive;
  }
}
