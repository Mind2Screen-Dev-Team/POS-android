/// A POS transaction pending backup.
///
/// Backend contract is unversioned; the payload is kept opaque so the store
/// survives backend field changes without data loss.
class Transaction {
  const Transaction({required this.id, required this.data});

  /// Server-side id (usually the created `id`).
  final String id;

  /// Free-form transaction payload (created_at, totals, items, ...).
  final Map<String, dynamic> data;

  Map<String, dynamic> toJson() => {'id': id, 'data': data};

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'] as String,
        data: (json['data'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
}
