import 'package:flutter/material.dart';

import '../../core/device/uuid_service.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/error_view.dart';
import 'backup_service.dart';
import 'transaction_store.dart';

/// Halaman backup: menampilkan ukuran storage lokal, tombol 'backup data'
/// (pilih rentang tanggal), dan restore dengan input UUID manual.
class BackupScreen extends StatefulWidget {
  BackupScreen({
    super.key,
    ApiClient? apiClient,
    UuidService? uuidService,
    TransactionStore? store,
    this.batchSize = 500,
  })  : _apiClient = apiClient ?? ApiClient(),
        _uuidService = uuidService ?? UuidService(),
        _store = store ?? TransactionStore();

  final ApiClient _apiClient;
  final UuidService _uuidService;
  final TransactionStore _store;
  final int batchSize;

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _loading = false;
  String? _error;
  String? _status;
  int _storageBytes = 0;

  @override
  void initState() {
    super.initState();
    _refreshStorage();
  }

  Future<void> _refreshStorage() async {
    final bytes = await widget._store.storageUsageBytes();
    if (mounted) setState(() => _storageBytes = bytes);
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Future<void> _pickRangeAndBackup() async {
    final now = DateTime.now();
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => DateRangeBottomSheet(
        onConfirm: (start, end) {
          _runBackup(from: start, to: end);
        },
      ),
    );
  }

  Future<void> _runBackup({DateTime? from, DateTime? to}) async {
    setState(() {
      _loading = true;
      _error = null;
      _status = null;
    });
    try {
      final userId = await widget._uuidService.getOrCreate();
      final service = BackupService(
        apiClient: widget._apiClient,
        store: widget._store,
        batchSize: widget.batchSize,
      );
      final sent = await service.backupAll(userId: userId, from: from, to: to);
      setState(() {
        _status = sent == 0
            ? 'Tidak ada transaksi yang perlu di-backup'
            : 'Backup selesai: $sent transaksi terkirim';
      });
    } on ApiException catch (e) {
      setState(() => _error = 'Gagal backup: ${e.message}');
    } catch (e) {
      setState(() => _error = 'Gagal backup: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        await _refreshStorage();
      }
    }
  }

  Future<void> _runRestore() async {
    final userIdController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore backup'),
        content: TextField(
          controller: userIdController,
          decoration: const InputDecoration(
            labelText: 'UUID pengguna (device lama)',
            hintText: 'xxxxxxxx-xxxx-4xxx-xxxx-xxxxxxxxxxxx',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final userId = userIdController.text.trim();
              Navigator.of(context).pop();
              _pickRestoreRange(userId);
            },
            child: const Text('Lanjut'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickRestoreRange(String rawUserId) async {
    final userId = rawUserId.trim();
    if (!UuidService.isValidV4(userId)) {
      _showError('Format UUID tidak valid. Gunakan format UUID v4.');
      return;
    }
    final now = DateTime.now();
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => DateRangeBottomSheet(
        onConfirm: (start, end) {
          _runRestoreRange(start: start, end: end, userId: userId);
        },
      ),
    );

    setState(() {
      _loading = true;
      _error = null;
      _status = null;
    });
    try {
      final service = BackupService(
        apiClient: widget._apiClient,
        store: widget._store,
        batchSize: widget.batchSize,
      );
      final count = await service.restore(userId: userId, from: from, to: to);
      setState(() {
        _status = count == 0
            ? 'Tidak ada data ditemukan untuk rentang tersebut'
            : 'Restore selesai: $count transaksi dipulihkan';
      });
    } on ApiException catch (e) {
      setState(() => _error = 'Gagal restore: ${e.message}');
    } catch (e) {
      setState(() => _error = 'Gagal restore: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        await _refreshStorage();
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.storage),
                  title: const Text('Penyimpanan terpakai'),
                  subtitle: Text(_formatBytes(_storageBytes)),
                  trailing: IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _refreshStorage,
                    tooltip: 'Perbarui ukuran',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loading ? null : _pickRangeAndBackup,
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Backup data'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _loading ? null : _runRestore,
                icon: const Icon(Icons.cloud_download),
                label: const Text('Restore backup'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                ErrorView(message: _error!),
              ],
              if (_status != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    title: Text(_status!),
                  ),
                ),
              ],
            ],
          ),
          if (_loading)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black26,
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}
