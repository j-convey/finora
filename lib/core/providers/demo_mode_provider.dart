import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/demo_mode_service.dart';

/// Whether the app is currently showing demo data instead of real server data.
final demoModeProvider = StateNotifierProvider<DemoModeNotifier, bool>((ref) {
  final service = ref.watch(demoModeServiceProvider);
  return DemoModeNotifier(service);
});

class DemoModeNotifier extends StateNotifier<bool> {
  DemoModeNotifier(this._service) : super(_service.isDemoModeActive());

  final DemoModeService _service;

  void updateState(bool isActive) {
    state = isActive;
  }
}
