import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthState {
  const AuthState({
    this.isConnected = false,
    this.serverUrl = '',
    this.isLoading = false,
    this.error,
  });

  final bool isConnected;
  final String serverUrl;
  final bool isLoading;
  final String? error;

  AuthState copyWith({
    bool? isConnected,
    String? serverUrl,
    bool? isLoading,
    String? error,
  }) =>
      AuthState(
        isConnected: isConnected ?? this.isConnected,
        serverUrl: serverUrl ?? this.serverUrl,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  Future<void> connect(String url) async {
    state = state.copyWith(isLoading: true, error: null);
    // Simulate a network handshake
    await Future.delayed(const Duration(milliseconds: 1400));
    state = state.copyWith(
      isLoading: false,
      isConnected: true,
      serverUrl: url.isEmpty ? 'localhost:3000' : url,
    );
  }

  void disconnect() {
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
