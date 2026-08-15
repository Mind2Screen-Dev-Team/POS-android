import '../../core/network/api_client.dart';
import 'transaction.dart';
import 'transaction_store.dart';

/// End-to-end backup/restore against the POS backend.
///
/// Contract (backend Go):
///   POST /api/v1/backup  body {user_id, start_date, end_date,
///                              transactions:[{id,data},...]}
///                         200 {ack_ids:[...]}  — only then may rows be deleted
///   GET  /api/v1/backup?user_id=&start_date=&end_date=
///                         200 {transactions:[{id,data},...]}
///
/// Batch size is capped at [batchSize]; a batch is removed from local storage
/// only after the server acknowledges every row in it. On any error the local
/// data stays intact.
class BackupService {
  BackupService({required this.apiClient, required this.store, this.batchSize = 500});

  final ApiClient apiClient;
  final TransactionStore store;
  final int batchSize;

  static const _backupPath = '/api/v1/backup';

  /// Sends every pending transaction in batches, deleting each batch only
  /// after the server acknowledges it. Returns how many rows were backed up.
  /// Throws on the first non-2xx response — local data is left untouched.
  Future<int> backupAll({
    required String userId,
    DateTime? from,
    DateTime? to,
  }) async {
    int sent = 0;
    while (true) {
      final batch = await store.nextBatch(batchSize: batchSize);
      if (batch.isEmpty) break;
      await _sendBatch(userId: userId, batch: batch, from: from, to: to);
      sent += batch.length;
    }
    return sent;
  }

  Future<void> _sendBatch({
    required String userId,
    required List<Transaction> batch,
    DateTime? from,
    DateTime? to,
  }) async {
    final decoded = await apiClient.post(
      _backupPath,
      body: {
        'user_id': userId,
        'start_date': from?.toIso8601String(),
        'end_date': to?.toIso8601String(),
        'transactions': batch.map((t) => t.toJson()).toList(),
      },
    );
    final ackIds = _parseAckIds(decoded);
    if (ackIds.isEmpty) {
      throw ApiException(0, 'empty ack_ids in backup response');
    }
    await store.removeAll(ackIds);
  }

  /// Extracts acknowledged ids from the decoded response. Accepts both
  /// `{"ack_ids":[...]}` and a raw array of `{id,...}` rows so the endpoint
  /// can evolve.
  List<String> _parseAckIds(dynamic decoded) {
    if (decoded is Map) {
      final ids = decoded['ack_ids'];
      if (ids is List) return ids.whereType<String>().toList();
      return const [];
    }
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((m) => m['id'])
          .whereType<String>()
          .toList();
    }
    return const [];
  }

  /// Fetches transactions for [userId] in [from]..[to] and writes them into
  /// the local store (new-device restore). Returns the row count restored.
  Future<int> restore({
    required String userId,
    required DateTime from,
    required DateTime to,
  }) async {
    final query = 'user_id=${Uri.encodeQueryComponent(userId)}'
        '&start_date=${formatDate(from)}'
        '&end_date=${formatDate(to)}';
    final decoded = await apiClient.get('$_backupPath?$query');
    final transactions = _parseRestore(decoded);
    if (transactions.isNotEmpty) {
      await store.replaceAll(transactions);
    }
    return transactions.length;
  }

  List<Transaction> _parseRestore(dynamic decoded) {
    if (decoded is Map) decoded = decoded['transactions'];
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((m) => Transaction.fromJson(m.cast<String, dynamic>()))
        .toList();
  }

  /// yyyy-MM-dd from a local [DateTime], for range query params.
  static String formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
