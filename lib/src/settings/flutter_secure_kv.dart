import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'settings_store.dart';

/// [SecureKeyValue] backed by `flutter_secure_storage` (the app's real store).
class FlutterSecureKv implements SecureKeyValue {
  final FlutterSecureStorage _storage;

  FlutterSecureKv([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
}
