import 'package:flutter_test/flutter_test.dart';

import 'package:pos_android/core/device/uuid_service.dart';

void main() {
  group('UuidService.generateV4', () {
    test('produces valid RFC 4122 v4 shape', () {
      final uuid = UuidService.generateV4();
      expect(UuidService.isValidV4(uuid), isTrue);
    });

    test('version and variant bits set', () {
      final uuid = UuidService.generateV4();
      // Version nibble after third dash, variant nibble after fourth.
      expect(uuid.substring(14, 15), '4');
      expect('89ab'.contains(uuid.substring(19, 20)), isTrue);
    });

    test('produces distinct values', () {
      final a = UuidService.generateV4();
      final b = UuidService.generateV4();
      expect(a, isNot(b));
    });
  });

  group('UuidService.isValidV4', () {
    test('rejects malformed values', () {
      expect(UuidService.isValidV4(''), isFalse);
      expect(UuidService.isValidV4('not-a-uuid'), isFalse);
      expect(
        UuidService.isValidV4('12345678-1234-1234-1234-1234567890ab'),
        isFalse, // version nibble not 4
      );
    });
  });

  group('UuidService.getOrCreate', () {
    test('generates and persists a UUID on first run', () async {
      final prefs = _MemoryPrefs();
      final service = UuidService(preferences: prefs);

      final uuid = await service.getOrCreate();
      expect(UuidService.isValidV4(uuid), isTrue);
      expect(prefs.get('user_uuid'), uuid, reason: 'saved to storage');
    });

    test('returns the same persisted UUID on later calls', () async {
      final prefs = _MemoryPrefs()
        ..put('user_uuid', '11111111-1111-4111-8111-111111111111');
      final service = UuidService(preferences: prefs);

      final a = await service.getOrCreate();
      final b = await service.getOrCreate();
      expect(a, b);
      expect(a, '11111111-1111-4111-8111-111111111111');
    });

    test('regenerates when stored value is empty', () async {
      final prefs = _MemoryPrefs()..put('user_uuid', '');
      final service = UuidService(preferences: prefs);

      final uuid = await service.getOrCreate();
      expect(UuidService.isValidV4(uuid), isTrue);
      expect(uuid, isNot(''));
    });
  });
}

class _MemoryPrefs implements UuidPreferences {
  final Map<String, String> _store = {};

  void put(String key, String value) => _store[key] = value;
  String? get(String key) => _store[key];

  @override
  Future<String?> getString(String key) async => _store[key];

  @override
  Future<void> setString(String key, String value) async => _store[key] = value;
}
