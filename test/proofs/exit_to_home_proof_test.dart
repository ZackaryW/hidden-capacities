@Tags(['proof_exit_to_home'])
library;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodCall, SystemChannels;
import 'package:flutter_test/flutter_test.dart';
import 'package:hidden_capacities/src/crypto/hidden_cap_cipher.dart';
import 'package:hidden_capacities/src/integration/capacities_gateway.dart';
import 'package:hidden_capacities/src/service/hidden_cap_service.dart';
import 'package:hidden_capacities/src/settings/settings_store.dart';
import 'package:hidden_capacities/src/transform/block_quill_transform.dart';
import 'package:hidden_capacities/src/ui/app.dart';
import 'package:unofficial_capacities/unofficial_capacities.dart';

class _MapKv implements SecureKeyValue {
  final Map<String, String> data = {'api_token': 'token'};

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async => data[key] = value;
}

HiddenCapService _service(String token) => HiddenCapService(
      gateway: CapacitiesGateway(
        CapacitiesClient(apiToken: token, dio: Dio()),
      ),
      cipher: HiddenCapCipher(),
      transform: BlockQuillTransform(),
    );

void main() {
  testWidgets('Exit returns to idle Home and keeps clipboard checks available',
      (tester) async {
    final kv = _MapKv();
    final platformCalls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        platformCalls.add(call);
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.pumpWidget(HiddenCapApp(
      settingsOverride: SettingsStore(kv),
      serviceFactory: _service,
      watchClipboard: false,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Ready'), findsOneWidget);
    expect(find.text('Check clipboard'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Exit'));
    await tester.pump();
    expect(find.text('Ready'), findsOneWidget);
    expect(find.text('Check clipboard'), findsOneWidget);
    expect(find.text('Hidden Capacities'), findsOneWidget);
    expect(
      platformCalls.where((call) => call.method == 'SystemNavigator.pop'),
      isEmpty,
    );

    final before = Map<String, String>.from(kv.data);
    await tester.tap(find.byTooltip('Exit'));
    await tester.pump();
    expect(find.text('Ready'), findsOneWidget);
    expect(kv.data, before);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tokenField')), findsOneWidget);
  });
}
