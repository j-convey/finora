import 'package:flutter/material.dart';

class AboutSettingsPage extends StatelessWidget {
  const AboutSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        children: [
          const SizedBox(height: 32),
          Center(
            child: Icon(Icons.account_balance, size: 64, color: cs.primary),
          ),
          const SizedBox(height: 16),
          Center(child: Text('Finora', style: tt.headlineMedium)),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Self-hosted personal finance intelligence',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.tag_outlined),
            title: Text('Version'),
            trailing: Text('0.1.0'),
          ),
          const ListTile(
            leading: Icon(Icons.code_outlined),
            title: Text('License'),
            trailing: Text('MIT'),
          ),
        ],
      ),
    );
  }
}
