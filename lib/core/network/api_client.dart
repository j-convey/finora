import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';

final apiClientProvider = Provider<Dio>((ref) {
  final serverUrl = ref.watch(authProvider).serverUrl;
  final baseUrl =
      serverUrl.startsWith('http') ? serverUrl : 'http://$serverUrl';

  return Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );
});
