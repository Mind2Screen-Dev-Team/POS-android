import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Minimal key-value surface [UuidService] needs from [SharedPreferences].
/// Keeps the service testable without a platform channel.
abstract class UuidPreferences {
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);
}

/// Lazy [SharedPreferences] adapter used when no store is injected.
class _SharedPrefs implements UuidPreferences {
  Future<SharedPreferences>? _instance;
  Future<SharedPreferences> _get() =>
      _instance ??= SharedPreferences.getInstance();

  @override
  Future<String?> getString(String key) async => (await _get()).getString(key);

  @override
  Future<void> setString(String key, String value) async {
    await (await _get()).setString(key, value);
  }
}

/// First-run user identifier.
///
/// Generates a random UUID v4 on first use and persists it with
/// [SharedPreferences]. The same value is sent as `user_id` on every backup
/// request so batches from one device can be restored on another.
class UuidService {
  UuidService({UuidPreferences? preferences})
      : _prefs = preferences ?? _SharedPrefs();

  static const _prefsKey = 'user_uuid';

  final UuidPreferences _prefs;

  /// Returns the persisted UUID, generating and saving a new v4 on first run.
  Future<String> getOrCreate() async {
    final existing = await _prefs.getString(_prefsKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final uuid = generateV4();
    await _prefs.setString(_prefsKey, uuid);
    return uuid;
  }

  /// RFC 4122 version 4 UUID built from [Random.secure] — no external dep.
  static String generateV4() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    // Set the version (4) and variant (10xx) bits.
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

  /// True when [value] matches the canonical UUID v4 shape.
  static bool isValidV4(String value) {
    final re = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-'
      r'[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    );
    return re.hasMatch(value);
  }
}
