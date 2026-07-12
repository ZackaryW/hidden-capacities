/// A minimal async secure key-value seam. The app backs this with
/// flutter_secure_storage; tests back it with an in-memory fake, so the store
/// logic is unit-testable without the platform plugin.
abstract class SecureKeyValue {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

/// What happens when a linked block is detected as a HIDDEN-CAP blob.
enum AutoDecrypt {
  /// Never auto-decrypt; offer a manual action.
  off('off'),

  /// Prompt before decrypting.
  ask('ask'),

  /// Decrypt immediately with the stored passphrase.
  on('on');

  const AutoDecrypt(this.storageValue);

  /// Stable string used for persistence.
  final String storageValue;

  static AutoDecrypt fromStorage(String? value) {
    return AutoDecrypt.values.firstWhere(
      (v) => v.storageValue == value,
      orElse: () => AutoDecrypt.off,
    );
  }
}

/// Immutable snapshot of the app's settings.
class Settings {
  final String? apiToken;
  final String? passphrase;
  final AutoDecrypt autoDecrypt;

  const Settings({
    this.apiToken,
    this.passphrase,
    this.autoDecrypt = AutoDecrypt.off,
  });
}

/// Reads and writes settings through a [SecureKeyValue] backend.
class SettingsStore {
  static const _tokenKey = 'api_token';
  static const _passphraseKey = 'passphrase';
  static const _autoDecryptKey = 'auto_decrypt';

  final SecureKeyValue _kv;

  SettingsStore(this._kv);

  Future<Settings> load() async {
    return Settings(
      apiToken: await _kv.read(_tokenKey),
      passphrase: await _kv.read(_passphraseKey),
      autoDecrypt: AutoDecrypt.fromStorage(await _kv.read(_autoDecryptKey)),
    );
  }

  Future<void> saveApiToken(String value) => _kv.write(_tokenKey, value);

  Future<void> savePassphrase(String value) => _kv.write(_passphraseKey, value);

  Future<void> saveAutoDecrypt(AutoDecrypt value) =>
      _kv.write(_autoDecryptKey, value.storageValue);
}
