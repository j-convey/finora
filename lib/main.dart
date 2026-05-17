import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/providers/theme_provider.dart';
import 'core/services/notification_service.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load prefs and initialise auth before the first frame so:
  //  • The correct theme is applied immediately (no flash).
  //  • The router redirect lands on the right screen without flickering.
  final prefs = await SharedPreferences.getInstance();
  await NotificationService.init();

  final container = ProviderContainer(
    overrides: [
      prefsProvider.overrideWithValue(prefs),
    ],
  );

  await container.read(authProvider.notifier).initialize();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const FinoraApp(),
    ),
  );
}
