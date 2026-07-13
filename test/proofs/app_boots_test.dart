@Tags(['proof_app_boots'])
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
  testWidgets('boots to Home no-token prompt and navigates to Settings',
      (tester) async {
    await tester.pumpWidget(HiddenCapApp(
      settingsOverride: SettingsStore(_MapKv()),
      watchClipboard: false,
    ));
    await tester.pumpAndSettle();

    expect(find.text('No API token'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tokenField')), findsOneWidget);
    expect(find.byKey(const Key('saveButton')), findsOneWidget);
  });
}
