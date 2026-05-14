import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages secure persistence of JWT tokens.
///
/// Tokens (sensitive) → flutter_secure_storage with SharedPreferences fallback
///   for macOS dev builds where the Keychain is unavailable without a paid
///   Apple Developer provisioning profile.
/// Server URL (non-sensitive) → SharedPreferences directly.
///
/// All other code should go through this service — never read/write tokens
/// directly from providers or UI code.
class TokenStorageService {
  // No MacOsOptions / IOSOptions with explicit keychain-access-groups — those
  // require a paid provisioning profile.  Use defaults so the OS picks a safe
  // fallback automatically.
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyServerUrl = 'finora_server_url'; // SharedPreferences key

  // ── Server URL (SharedPreferences, non-sensitive) ─────────────────────────

  Future<String?> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyServerUrl);
  }

  Future<void> saveServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyServerUrl, url);
  }

  // ── Tokens (secure storage only) ──────────────────────────────────────────

  Future<String?> getAccessToken() => _secureRead(_keyAccessToken);
  Future<String?> getRefreshToken() => _secureRead(_keyRefreshToken);

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _secureWrite(_keyAccessToken, accessToken),
      _secureWrite(_keyRefreshToken, refreshToken),
    ]);
  }

  Future<void> clearTokens() async {
    await Future.wait([
      _secureDelete(_keyAccessToken),
      _secureDelete(_keyRefreshToken),
    ]);
  }

  Future<bool> hasTokens() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// SharedPreferences key prefix used as a fallback when the OS keychain /
  /// secure enclave is unavailable (e.g. macOS dev builds without a paid
  /// provisioning profile).
  static const _spFallbackPrefix = 'finora_token_fb_';

  Future<String?> _secureRead(String key) async {
    try {
      final value = await _storage.read(key: key);
      if (value != null) return value;
      // Keychain returned null (either missing or unavailable without throwing) —
      // fall through to the SharedPreferences fallback.
    } catch (_) {
      // Keychain threw (e.g. macOS without provisioning profile).
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_spFallbackPrefix + key);
  }

  Future<void> _secureWrite(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {
      // Keychain unavailable (e.g. macOS without provisioning profile) —
      // fall back to SharedPreferences so login actually works in dev builds.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_spFallbackPrefix + key, value);
    }
  }

  Future<void> _secureDelete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {
      // Best effort delete.
    }
    // Always clear the fallback entry too.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_spFallbackPrefix + key);
  }
}

