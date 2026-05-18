import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';

enum _ServerState { idle, checking, ok, error }

/// Single-screen auth page.
///
/// Layout:
///   • Server URL field — provides a button to probe the server.
///   • Once server is reachable: Email + Password fields appear.
///   • If server has no users yet: "First Time Setup" button appears
///     alongside the regular Sign In button.
class SetupPage extends ConsumerStatefulWidget {
  const SetupPage({super.key});

  @override
  ConsumerState<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends ConsumerState<SetupPage> {
  final _urlController = TextEditingController(text: 'http://localhost:8080');
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _urlFocus = FocusNode();

  bool _obscurePassword = true;
  _ServerState _serverState = _ServerState.idle;
  bool? _serverHasUsers; // null = not probed yet

  @override
  void initState() {
    super.initState();
    _urlController.addListener(_onUrlChange);

    // If a server URL is already stored, probe it immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final storedUrl = ref.read(authProvider).serverUrl;
      if (storedUrl.isNotEmpty) {
        _urlController.text = storedUrl;
        _probeServer();
      }
    });
  }

  @override
  void dispose() {
    _urlController.removeListener(_onUrlChange);
    _urlController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _urlFocus.dispose();
    super.dispose();
  }

  void _onUrlChange() {
    // If the user starts typing, reset the server state so they can "Check Connection" again.
    if (_serverState != _ServerState.idle) {
      setState(() {
        _serverState = _ServerState.idle;
        _serverHasUsers = null;
      });
    }
  }

  Future<void> _probeServer() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _serverState = _ServerState.checking;
      _serverHasUsers = null;
    });

    final result = await ref.read(authProvider.notifier).probeServer(url);

    if (!mounted) return;

    if (result.reachable) {
      // Save the confirmed URL so other providers can use it.
      await ref.read(authProvider.notifier).setServerUrl(url);
    }

    setState(() {
      _serverState = result.reachable ? _ServerState.ok : _ServerState.error;
      _serverHasUsers = result.reachable ? result.hasUsers : null;
    });
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) return;
    ref.read(authProvider.notifier).clearError();
    await ref
        .read(authProvider.notifier)
        .login(email: email, password: password);
    // Router redirect takes over on success.
  }

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) return;
    ref.read(authProvider.notifier).clearError();
    await ref
        .read(authProvider.notifier)
        .register(email: email, password: password);
    // Router redirect takes over on success.
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final auth = ref.watch(authProvider);
    final serverReady = _serverState == _ServerState.ok;
    final isLoading = auth.isLoading || _serverState == _ServerState.checking;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Logo ─────────────────────────────────────────
                Icon(Icons.account_balance, size: 64, color: cs.primary),
                const SizedBox(height: 12),
                Text(
                  'Finora',
                  textAlign: TextAlign.center,
                  style: tt.displaySmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Self-hosted personal finance',
                  textAlign: TextAlign.center,
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 40),

                // ── Server URL ────────────────────────────────────
                TextField(
                  controller: _urlController,
                  focusNode: _urlFocus,
                  enabled: !auth.isLoading,
                  decoration: InputDecoration(
                    labelText: 'Server URL',
                    hintText: 'http://192.168.1.100:8080',
                    prefixIcon: const Icon(Icons.dns_outlined),
                    border: const OutlineInputBorder(),
                    suffixIcon: switch (_serverState) {
                      _ServerState.checking => const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      _ServerState.ok => Icon(
                        Icons.check_circle,
                        color: const Color(0xFF4CAF50),
                      ),
                      _ServerState.error => Icon(
                        Icons.error_outline,
                        color: cs.error,
                      ),
                      _ServerState.idle => null,
                    },
                  ),
                  keyboardType: TextInputType.url,
                  onSubmitted: (_) => _probeServer(),
                ),
                if (_serverState == _ServerState.error) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Cannot reach server. Check the URL and try again.',
                    style: tt.bodySmall?.copyWith(color: cs.error),
                  ),
                ],
                if (!serverReady && _urlController.text.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: isLoading ? null : _probeServer,
                    icon: Icon(
                      _serverState == _ServerState.checking
                          ? Icons.hourglass_empty
                          : Icons.check_circle_outline,
                    ),
                    label: Text(
                      _serverState == _ServerState.checking
                          ? 'Checking...'
                          : 'Check Connection',
                    ),
                  ),
                ],

                // ── Credentials — shown once server is reachable ──
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  child: serverReady
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 16),
                            TextField(
                              controller: _emailController,
                              enabled: !isLoading,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email_outlined),
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _passwordController,
                              enabled: !isLoading,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                              ),
                              onSubmitted: (_) => _login(),
                            ),
                            if (auth.error != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                auth.error!,
                                style: tt.bodySmall?.copyWith(color: cs.error),
                              ),
                            ],
                            const SizedBox(height: 20),
                            FilledButton(
                              onPressed: isLoading ? null : _login,
                              child: isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Sign In'),
                            ),
                            // First-time setup button — only when no users exist
                            if (_serverHasUsers == false) ...[
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: isLoading ? null : _register,
                                icon: const Icon(Icons.person_add_outlined),
                                label: const Text(
                                  'First Time Setup — Create Account',
                                ),
                              ),
                            ],
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
