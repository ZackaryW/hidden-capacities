@Tags(['proof_settings_persist'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hidden_capacities/src/settings/settings_store.dart';
import 'package:hidden_capacities/src/ui/app.dart';

class _MapKv implements SecureKeyValue {
  final Map<String, String> data = {};
  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> write(String key, String value) async => data[key] = value;
}

void main() {
  testWidgets('saving token, passphrase and auto-decrypt persists them',
      (tester) async {
    final store = SettingsStore(_MapKv());
    await tester.pumpWidget(HiddenCapApp(
      settingsOverride: store,
      watchClipboard: false,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('tokenField')), 'cap-api-abc');
    await tester.enterText(find.byKey(const Key('passphraseField')), 'hunter2');
    await tester.tap(find.text('On'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saveButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('savedNotice')), findsOneWidget);

    // The store now holds the saved values.
    final saved = await store.load();
    expect(saved.apiToken, 'cap-api-abc');
    expect(saved.passphrase, 'hunter2');
    expect(saved.autoDecrypt, AutoDecrypt.on);
  });
}
