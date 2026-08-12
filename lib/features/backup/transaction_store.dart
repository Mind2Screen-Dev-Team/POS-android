import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'transaction.dart';

/// Local durable store for transactions pending backup.
///
/// Persisted as a JSON file inside the app's local data directory, so backup
/// data is never lost between runs and [storageUsageBytes] reflects real
/// on-disk usage. Rows are removed only after the server acknowledges them
/// (see [removeAll]).
class TransactionStore {
  TransactionStore({Future<Directory>? directory})
      : _dir = directory ?? getApplicationDocumentsDirectory();

  static const _fileName = 'pending_backup.json';

  final Future<Directory> _dir;

  Future<Directory> _dirFor() async => _dir;

  Future<File> _file() async =>
      File('${(await _dirFor()).path}/$_fileName');

  /// Loads all transactions in insertion order, newest last.
  Future<List<Transaction>> all() async {
    final file = await _file();
    if (!await file.exists()) return [];
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) return [];
    final decoded = jsonDecode(raw) as List;
    return decoded
        .map((e) => Transaction.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<void> _write(List<Transaction> transactions) async {
    final file = await _file();
    final encoded = jsonEncode(
      transactions.map((t) => t.toJson()).toList(),
    );
    await file.writeAsString(encoded, flush: true);
  }

  /// Appends [transaction] durably.
  Future<void> add(Transaction transaction) async {
    final transactions = await all();
    transactions.add(transaction);
    await _write(transactions);
  }

  /// Returns the next batch (at most [batchSize]) oldest-first.
  Future<List<Transaction>> nextBatch({int batchSize = 500}) async {
    final transactions = await all();
    return transactions.take(batchSize).toList();
  }

  /// Removes [ids] after the server acknowledged them. Any other id stays.
  Future<void> removeAll(Iterable<String> ids) async {
    final toRemove = ids.toSet();
    final remaining = (await all())
        .where((t) => !toRemove.contains(t.id))
        .toList();
    await _write(remaining);
  }

  /// Replaces all local data with the restored transactions (new device).
  Future<void> replaceAll(Iterable<Transaction> transactions) =>
      _write(transactions.toList());

  /// Removes all pending data. Use for a completed backup or a full restore.
  Future<void> clear() => _write(const []);

  /// Bytes used by the local backup file (0 when nothing pending).
  Future<int> storageUsageBytes() async {
    final file = await _file();
    if (!await file.exists()) return 0;
    return file.length();
  }
}
