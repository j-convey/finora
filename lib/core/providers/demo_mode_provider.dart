import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the app is currently showing demo data instead of real server data.
///
/// Not persisted — demo mode is always off on fresh app launch. The user
/// explicitly enters and exits it from Settings.
final demoModeProvider = StateProvider<bool>((ref) => false);
