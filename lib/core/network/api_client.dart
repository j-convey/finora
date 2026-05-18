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
    // Don't send demo header for auth endpoints or the demo toggle itself
    final isAuthRequest = options.path.contains('/api/auth/');
    final isDemoToggle = options.path.contains('/api/demo/');

    if (isDemoMode && !isAuthRequest && !isDemoToggle) {
      options.headers['X-Demo-Mode'] = 'true';
    } else {
      options.headers.remove('X-Demo-Mode');
    }
    
    // Log headers for debugging (masked for security)
    final authHeader = options.headers['Authorization'] as String?;
    final maskedAuth = authHeader != null
        ? (authHeader.length > 20
            ? '${authHeader.substring(0, 15)}...'
            : 'present')
        : 'missing';

    print('DEBUG [ApiClient]: Request ${options.method} ${options.path}');
    print('DEBUG [ApiClient]: X-Demo-Mode: ${options.headers['X-Demo-Mode']}');
    print('DEBUG [ApiClient]: Authorization: $maskedAuth');
    
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
    
    // If we're in demo mode, some backends might reject real user tokens.
    // However, the user wants to stay "signed in". 
    // We'll send the token unless we find it's causing 401s specifically 
    // in demo mode.
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final isDemoMode = _ref.read(demoModeProvider);
    print(
        'DEBUG [ApiClient]: Error ${err.response?.statusCode} on ${err.requestOptions.path}');

    if (err.response?.statusCode == 401) {
      final notifier = _ref.read(authProvider.notifier);
      final storage = _ref.read(tokenStorageProvider);
      final refreshToken = await storage.getRefreshToken();

      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          print('DEBUG [ApiClient]: Attempting token refresh...');
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

          final data = response.data!;
          final newAccess = data['access_token'] as String;
          final newRefresh = data['refresh_token'] as String;

          await storage.saveTokens(
            accessToken: newAccess,
            refreshToken: newRefresh,
          );
          print('DEBUG [ApiClient]: Token refresh successful.');

          // Retry original request with new token.
          final retryOptions = err.requestOptions;
          retryOptions.headers['Authorization'] = 'Bearer $newAccess';

          // Use a new Dio instance for the retry to avoid interceptor recursion
          final retryResponse = await Dio(BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          )).fetch(retryOptions);

          return handler.resolve(retryResponse);
        } catch (e) {
          print('DEBUG [ApiClient]: Token refresh failed: $e');
          // Refresh failed — only logout if NOT in demo mode.
          if (!isDemoMode) {
            await notifier.logout();
          }
        }
      } else {
        print('DEBUG [ApiClient]: No refresh token available.');
        if (!isDemoMode) {
          await notifier.logout();
        }
      }
    }
    handler.next(err);
  }
}
