// ignore_for_file: use_null_aware_elements

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/auth_tokens.dart';
import '../../data/models/user_model.dart';
import '../../data/services/token_storage_service.dart';

// ── Supporting types ──────────────────────────────────────────────────────────

class ServerProbeResult {
  const ServerProbeResult({required this.reachable, required this.hasUsers});
  final bool reachable;
  final bool hasUsers;
}

// ── Providers ─────────────────────────────────────────────────────────────────

final tokenStorageProvider = Provider<TokenStorageService>(
  (_) => TokenStorageService(),
);

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref),
);

// ── State ─────────────────────────────────────────────────────────────────────

enum AuthStatus {
  /// No stored tokens, haven't checked yet.
  unknown,

  /// No tokens — needs server URL + register or login.
  unauthenticated,

  /// Has tokens & verified user — ready for main app.
  authenticated,
}

class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.serverUrl = '',
    this.user,
    this.isLoading = false,
    this.error,
  });

  final AuthStatus status;

  /// Base URL e.g. "http://localhost:8080".
  final String serverUrl;

  /// Non-null only when [status] == [AuthStatus.authenticated].
  final UserModel? user;
  final bool isLoading;
  final String? error;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    String? serverUrl,
    UserModel? user,
    bool clearUser = false,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      AuthState(
        status: status ?? this.status,
        serverUrl: serverUrl ?? this.serverUrl,
        user: clearUser ? null : user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref) : super(const AuthState());

  final Ref _ref;
  TokenStorageService get _storage => _ref.read(tokenStorageProvider);

  /// Called on app startup — loads stored URL + validates existing tokens.
  Future<void> initialize() async {
    state = state.copyWith(isLoading: true);
    final url = await _storage.getServerUrl();
    if (url != null && url.isNotEmpty) {
      state = state.copyWith(serverUrl: url);
    }
    final hasTokens = await _storage.hasTokens();
    if (!hasTokens) {
      state = state.copyWith(
        isLoading: false,
        status: AuthStatus.unauthenticated,
      );
      return;
    }
    await _fetchCurrentUser();
  }

  /// Saves the server URL (needed before login/register).
  Future<void> setServerUrl(String url) async {
    final normalised = url.startsWith('http') ? url : 'http://$url';
    state = state.copyWith(serverUrl: normalised);
    await _storage.saveServerUrl(normalised);
  }

  /// POST /api/auth/register — first-run only. Returns true on success.
  Future<bool> register({
    required String email,
    required String password,
    String? fullName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dio = _buildDio();
      final response = await dio.post<Map<String, dynamic>>(
        '/api/auth/register',
        data: {
          'email': email,
          'password': password,
          if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
        },
      );
      final tokens = AuthTokens.fromJson(response.data!);
      await _storage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      await _fetchCurrentUser();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
      return false;
    }
  }

  /// POST /api/auth/login
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dio = _buildDio();
      final response = await dio.post<Map<String, dynamic>>(
        '/api/auth/login',
        data: {'email': email, 'password': password},
      );
      final tokens = AuthTokens.fromJson(response.data!);
      await _storage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      await _fetchCurrentUser();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// POST /api/auth/logout — invalidates refresh token server-side, clears local tokens.
  Future<void> logout() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken != null) {
      try {
        final accessToken = await _storage.getAccessToken();
        final dio = _buildDio();
        if (accessToken != null) {
          dio.options.headers['Authorization'] = 'Bearer $accessToken';
        }
        await dio.post<void>(
          '/api/auth/logout',
          data: {'refresh_token': refreshToken},
        );
      } catch (_) {}
    }
    await _storage.clearTokens();
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      clearUser: true,
      clearError: true,
    );
  }

  void clearError() => state = state.copyWith(clearError: true);

  /// Updates the current user's profile info.
  /// If [profilePicturePath] is provided, it is uploaded as a multipart file.
  Future<bool> updateProfile({
    String? fullName,
    String? profilePicturePath,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dio = _buildDio();
      final accessToken = await _storage.getAccessToken();
      if (accessToken != null) {
        dio.options.headers['Authorization'] = 'Bearer $accessToken';
      }

      dynamic data;
      if (profilePicturePath != null) {
        data = FormData.fromMap({
          if (fullName != null) 'full_name': fullName,
          'profile_picture': await MultipartFile.fromFile(
            profilePicturePath,
            filename: 'profile_picture.jpg',
          ),
        });
      } else {
        data = {
          if (fullName != null) 'full_name': fullName,
        };
      }

      final response = await dio.patch<Map<String, dynamic>>(
        '/api/users/me',
        data: data,
      );

      final updatedUser = UserModel.fromJson(response.data!);
      state = state.copyWith(isLoading: false, user: updatedUser);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
      return false;
    }
  }

  /// Changes the current user's password.
  /// Returns null on success, or an error message string on failure.
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final dio = _buildDio();
      final accessToken = await _storage.getAccessToken();
      if (accessToken != null) {
        dio.options.headers['Authorization'] = 'Bearer $accessToken';
      }
      await dio.post<void>(
        '/api/users/me/password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );
      return null;
    } on DioException catch (e) {
      return _extractError(e);
    } catch (e) {
      return e.toString();
    }
  }

  /// Probes a candidate server URL. Returns a [ServerProbeResult] describing
  /// whether the server is reachable and whether it already has users.
  /// Does NOT persist any state — purely informational.
  Future<ServerProbeResult> probeServer(String url) async {
    final normalised = url.startsWith('http') ? url : 'http://$url';
    try {
      final dio = Dio(BaseOptions(
        baseUrl: normalised,
        connectTimeout: const Duration(seconds: 6),
        receiveTimeout: const Duration(seconds: 6),
      ));
      // Use a syntactically valid email so Pydantic passes validation and the
      // handler actually runs the user-count check.  If users exist → 409.
      // If no users yet → 422 (missing password field) after the count passes.
      try {
        await dio.post<void>(
          '/api/auth/register',
          data: {'email': 'probe@finora.invalid', 'password': ''},
        );
        return ServerProbeResult(reachable: true, hasUsers: false);
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        if (status == 409) {
          return ServerProbeResult(reachable: true, hasUsers: true);
        }
        if (status == 422 || status == 400) {
          // Validation error means the endpoint exists and no users yet.
          return ServerProbeResult(reachable: true, hasUsers: false);
        }
        if (status == 401 || status == 403) {
          return ServerProbeResult(reachable: true, hasUsers: true);
        }
        return ServerProbeResult(reachable: false, hasUsers: false);
      }
    } catch (_) {
      return ServerProbeResult(reachable: false, hasUsers: false);
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<void> _fetchCurrentUser() async {
    try {
      final accessToken = await _storage.getAccessToken();
      if (accessToken == null) {
        state = state.copyWith(
          isLoading: false,
          status: AuthStatus.unauthenticated,
        );
        return;
      }
      final dio = _buildDio();
      dio.options.headers['Authorization'] = 'Bearer $accessToken';
      final response = await dio.get<Map<String, dynamic>>('/api/users/me');
      final user = UserModel.fromJson(response.data!);
      state = state.copyWith(
        isLoading: false,
        status: AuthStatus.authenticated,
        user: user,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        final refreshed = await _tryRefreshTokens();
        if (refreshed) {
          await _fetchCurrentUser();
          return;
        }
        await _storage.clearTokens();
        state = state.copyWith(
          isLoading: false,
          status: AuthStatus.unauthenticated,
          clearUser: true,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          status: AuthStatus.unauthenticated,
          error: _extractError(e),
        );
      }
    }
  }

  /// POST /api/auth/refresh. Returns true if new tokens were saved.
  Future<bool> _tryRefreshTokens() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null) return false;
    try {
      final dio = _buildDio();
      final response = await dio.post<Map<String, dynamic>>(
        '/api/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final tokens = AuthTokens.fromJson(response.data!);
      await _storage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Dio _buildDio() => Dio(
        BaseOptions(
          baseUrl: state.serverUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {'Content-Type': 'application/json'},
        ),
      );

  static String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      return (data['error'] ?? data['detail'] ?? e.message).toString();
    }
    return e.message ?? 'Unknown error';
  }
}
