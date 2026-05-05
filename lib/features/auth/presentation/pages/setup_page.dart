import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

class SetupPage extends ConsumerStatefulWidget {
  const SetupPage({super.key});

  @override
  ConsumerState<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends ConsumerState<SetupPage> {
  final _urlController =
      TextEditingController(text: 'http://localhost:8080');

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    await ref
        .read(authProvider.notifier)
        .connect(_urlController.text.trim());
    if (mounted) context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isLoading = ref.watch(authProvider).isLoading;

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
                // Logo
                Icon(Icons.account_balance, size: 72, color: cs.primary),
                const SizedBox(height: 16),
                Text(
                  'Finora',
                  textAlign: TextAlign.center,
                  style: tt.displaySmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Self-hosted personal finance intelligence',
                  textAlign: TextAlign.center,
                  style:
                      tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 48),
                Text('Server URL', style: tt.titleSmall),
                const SizedBox(height: 8),
                TextField(
                  controller: _urlController,
                  enabled: !isLoading,
                  decoration: const InputDecoration(
                    hintText: 'http://localhost:3000',
                    prefixIcon: Icon(Icons.link_outlined),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: isLoading ? null : _connect,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Connect to Server'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: isLoading ? null : _connect,
                  icon: const Icon(Icons.science_outlined),
                  label: const Text('Launch Demo Mode'),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(child: Divider(color: cs.outlineVariant)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Demo mode uses mock data — no server needed',
                        style: tt.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ),
                    Expanded(child: Divider(color: cs.outlineVariant)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
