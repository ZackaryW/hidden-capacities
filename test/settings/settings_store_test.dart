import 'package:flutter_test/flutter_test.dart';
import 'package:hidden_capacities/src/settings/settings_store.dart';

class _FakeKv implements SecureKeyValue {
  final Map<String, String> _data = {};
  @override
  Future<String?> read(String key) async => _data[key];
  @override
  Future<void> write(String key, String value) async => _data[key] = value;
}

void main() {
  late SettingsStore store;

  setUp(() => store = SettingsStore(_FakeKv()));

  test('defaults when nothing is stored: no secrets, auto-decrypt off', () async {
    final settings = await store.load();

    expect(settings.apiToken, isNull);
    expect(settings.passphrase, isNull);
    expect(settings.autoDecrypt, AutoDecrypt.off);
  });

  test('saved token and passphrase round-trip through load', () async {
    await store.saveApiToken('cap-api-xyz');
    await store.savePassphrase('correct horse');

    final settings = await store.load();
    expect(settings.apiToken, 'cap-api-xyz');
    expect(settings.passphrase, 'correct horse');
  });

  test('auto-decrypt preference persists', () async {
    await store.saveAutoDecrypt(AutoDecrypt.on);

    expect((await store.load()).autoDecrypt, AutoDecrypt.on);
  });

  test('an unrecognized stored auto-decrypt value defaults to off', () async {
    final kv = _FakeKv();
    await kv.write('auto_decrypt', 'garbage');

    expect((await SettingsStore(kv).load()).autoDecrypt, AutoDecrypt.off);
  });

  test('AutoDecrypt serializes to a stable token', () {
    expect(AutoDecrypt.off.storageValue, 'off');
    expect(AutoDecrypt.ask.storageValue, 'ask');
    expect(AutoDecrypt.on.storageValue, 'on');
  });
}
