import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/device/uuid_service.dart';

/// Halaman Akun: menampilkan UUID device, dengan tombol salin & ekspor manual.
class AccountScreen extends StatelessWidget {
  AccountScreen({super.key, UuidService? uuidService})
      : _uuidService = uuidService ?? UuidService();

  final UuidService _uuidService;

  Future<String> _loadUuid() => _uuidService.getOrCreate();

  Future<void> _copy(BuildContext context, String uuid) async {
    await Clipboard.setData(ClipboardData(text: uuid));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('UUID disalin ke clipboard')),
      );
    }
  }

  Future<void> _export(BuildContext context, String uuid) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ekspor manual UUID'),
        content: SelectableText(uuid),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Akun')),
      body: FutureBuilder<String>(
        future: _loadUuid(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Gagal memuat UUID: ${snapshot.error}'));
          }
          final uuid = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ID Pengguna (UUID)'),
                      const SizedBox(height: 8),
                      SelectableText(
                        uuid,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          FilledButton.icon(
                            onPressed: () => _copy(context, uuid),
                            icon: const Icon(Icons.copy),
                            label: const Text('Salin'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () => _export(context, uuid),
                            icon: const Icon(Icons.ios_share),
                            label: const Text('Ekspor manual'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'UUID ini dipakai sebagai user_id di semua permintaan backup. '
                'Simpan untuk restore di device baru.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        },
      ),
    );
  }
}
