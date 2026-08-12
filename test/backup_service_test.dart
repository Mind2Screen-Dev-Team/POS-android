import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:pos_android/core/network/api_client.dart';
import 'package:pos_android/features/backup/backup_service.dart';
import 'package:pos_android/features/backup/transaction.dart';
import 'package:pos_android/features/backup/transaction_store.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('backup_test_');
  });

  tearDown(() async {
    await dir.delete(recursive: true);
  });

  group('BackupService backup / ack -> delete', () {
    test('deletes batch only after server acknowledges it', () async {
      final store = TransactionStore(directory: Future.value(dir));
      await store.add(Transaction(id: 't1', data: {'created_at': '2026-08-01T10:00:00Z'}));
      await store.add(Transaction(id: 't2', data: {'created_at': '2026-08-01T10:01:00Z'}));

      late http.Request captured;
      final mock = MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({'ack_ids': ['t1', 't2']}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final service = BackupService(
        apiClient: ApiClient(client: mock, baseUrl: 'http://x.test'),
        store: store,
        batchSize: 500,
      );

      final sent = await service.backupAll(userId: 'uuid-1');
      expect(sent, 2);
      expect(await store.all(), isEmpty, reason: 'acked rows must be removed');

      final body = jsonDecode(captured.body) as Map;
      expect(body['user_id'], 'uuid-1');
      expect((body['transactions'] as List).length, 2);
    });

    test('leaves data intact when server does not ack (500)', () async {
      final store = TransactionStore(directory: Future.value(dir));
      await store.add(Transaction(id: 't1', data: {}));

      final mock = MockClient((_) async => http.Response('boom', 500));
      final service = BackupService(
        apiClient: ApiClient(client: mock, baseUrl: 'http://x.test'),
        store: store,
      );

      await expectLater(
        service.backupAll(userId: 'uuid-1'),
        throwsA(isA<ApiException>()),
      );
      expect((await store.all()).map((t) => t.id), ['t1'],
          reason: 'no ack -> row stays on device');
    });

    test('splits into multiple batches of max 500', () async {
      final store = TransactionStore(directory: Future.value(dir));
      for (var i = 0; i < 1300; i++) {
        await store.add(Transaction(id: 't$i', data: {}));
      }

      var calls = 0;
      final mock = MockClient((request) async {
        calls++;
        final body = jsonDecode(request.body) as Map;
        final ids = (body['transactions'] as List)
            .map((t) => (t as Map)['id'] as String)
            .toList();
        return http.Response(
          jsonEncode({'ack_ids': ids}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final service = BackupService(
        apiClient: ApiClient(client: mock, baseUrl: 'http://x.test'),
        store: store,
        batchSize: 500,
      );

      final sent = await service.backupAll(userId: 'uuid-1');
      expect(sent, 1300);
      expect(calls, 3); // 500 + 500 + 300
      expect(await store.all(), isEmpty);
    });
  });

  group('BackupService restore', () {
    test('parses response and writes rows into store', () async {
      final store = TransactionStore(directory: Future.value(dir));
      final mock = MockClient((request) async {
        expect(request.url.queryParameters['start_date'], '2026-08-01');
        expect(request.url.queryParameters['end_date'], '2026-08-12');
        return http.Response(
          jsonEncode({
            'transactions': [
              {'id': 'r1', 'data': {'created_at': '2026-08-02T08:00:00Z'}},
              {'id': 'r2', 'data': {'created_at': '2026-08-05T09:00:00Z'}},
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final service = BackupService(
        apiClient: ApiClient(client: mock, baseUrl: 'http://x.test'),
        store: store,
      );

      final count = await service.restore(
        userId: 'uuid-1',
        from: DateTime(2026, 8, 1),
        to: DateTime(2026, 8, 12),
      );
      expect(count, 2);
      expect((await store.all()).map((t) => t.id), ['r1', 'r2']);
    });

    test('empty data leaves store unchanged', () async {
      final store = TransactionStore(directory: Future.value(dir));
      final mock = MockClient((_) async => http.Response(
            jsonEncode({'transactions': []}),
            200,
            headers: {'content-type': 'application/json'},
          ));
      final service = BackupService(
        apiClient: ApiClient(client: mock, baseUrl: 'http://x.test'),
        store: store,
      );

      final count = await service.restore(
        userId: 'uuid-1',
        from: DateTime(2026, 8, 1),
        to: DateTime(2026, 8, 3),
      );
      expect(count, 0);
      expect(await store.all(), isEmpty);
    });

    test('server error surfaces as ApiException without touching store', () async {
      final store = TransactionStore(directory: Future.value(dir));
      await store.add(Transaction(id: 'keep', data: {}));
      final mock = MockClient((_) async => http.Response('nope', 503));
      final service = BackupService(
        apiClient: ApiClient(client: mock, baseUrl: 'http://x.test'),
        store: store,
      );

      await expectLater(
        service.restore(
          userId: 'uuid-1',
          from: DateTime(2026, 8, 1),
          to: DateTime(2026, 8, 3),
        ),
        throwsA(isA<ApiException>()),
      );
      expect((await store.all()).map((t) => t.id), ['keep']);
    });
  });
}
