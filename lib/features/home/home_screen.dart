import 'package:flutter/material.dart';

import '../account/account_screen.dart';
import '../backup/backup_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('POS Penglaris')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('POS Penglaris — home screen placeholder'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => BackupScreen(),
                ),
              ),
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Backup'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AccountScreen(),
                ),
              ),
              icon: const Icon(Icons.account_circle),
              label: const Text('Akun'),
            ),
          ],
        ),
      ),
    );
  }
}
