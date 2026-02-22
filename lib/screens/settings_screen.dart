import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/sync_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _syncing = false;

  Future<void> _syncNow() async {
    setState(() => _syncing = true);
    final res = await SyncService.instance.syncNow();
    if (!mounted) return;

    final text = res.ok
        ? 'Synchronization completed successfully. ${res.pushed} task(s) uploaded and ${res.pulled} task(s) downloaded.'
        : res.message;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    setState(() => _syncing = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Signed in as'),
              subtitle: Text(user?.email ?? 'Unknown'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _syncing ? null : _syncNow,
              icon: _syncing
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.sync),
              label: const Text('Sync now'),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () async {
                await AuthService.instance.logout();
                if (mounted) Navigator.pop(context);
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
