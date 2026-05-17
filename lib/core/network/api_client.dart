import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../providers/demo_mode_provider.dart';

final apiClientProvider = Provider<Dio>((ref) {
  final serverUrl = ref.watch(authProvider).serverUrl;
  final baseUrl =
      serverUrl.startsWith('http') ? serverUrl : 'http://$serverUrl';

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(_AuthInterceptor(ref));
  dio.interceptors.add(_DemoHeaderInterceptor(ref));
  return dio;
});

class _DemoHeaderInterceptor extends Interceptor {
  _DemoHeaderInterceptor(this._ref);

  final Ref _ref;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final isDemoMode = _ref.read(demoModeProvider);
    if (isDemoMode) {
      options.headers['X-Demo-Mode'] = 'true';
    } else {
      options.headers.remove('X-Demo-Mode');
    }
    handler.next(options);
  }
}

/// Injects the Bearer token on every request, and auto-refreshes on 401.
class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._ref);

  final Ref _ref;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final storage = _ref.read(tokenStorageProvider);
    final token = await storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final notifier = _ref.read(authProvider.notifier);
      // Attempt a token refresh using the auth notifier's private helper
      // indirectly by calling initialize() — this re-fetches the user using
      // the stored refresh token, which rotates both tokens on success.
      //
      // The cleaner path: expose a public refresh method and retry once.
      final storage = _ref.read(tokenStorageProvider);
      final refreshToken = await storage.getRefreshToken();
      if (refreshToken != null) {
        try {
          final baseUrl = _ref.read(authProvider).serverUrl;
          final refreshDio = Dio(BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ));
          final response = await refreshDio.post<Map<String, dynamic>>(
            '/api/auth/refresh',
            data: {'refresh_token': refreshToken},
          );
          final newAccess = response.data!['access_token'] as String;
          final newRefresh = response.data!['refresh_token'] as String;
          await storage.saveTokens(
            accessToken: newAccess,
            refreshToken: newRefresh,
          );
          // Retry original request with new token.
          final retryOptions = err.requestOptions;
          retryOptions.headers['Authorization'] = 'Bearer $newAccess';
          final retryResponse = await Dio(BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          )).fetch(retryOptions);
          return handler.resolve(retryResponse);
        } catch (_) {
          // Refresh failed — force logout.
          await notifier.logout();
        }
      } else {
        await notifier.logout();
      }
    }
    handler.next(err);
  }
}
