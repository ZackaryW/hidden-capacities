@Tags(['proof_edit_reencrypt'])
library;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Block;
import 'package:flutter_test/flutter_test.dart';
import 'package:hidden_capacities/src/crypto/hidden_cap_cipher.dart';
import 'package:hidden_capacities/src/integration/capacities_gateway.dart';
import 'package:hidden_capacities/src/service/hidden_cap_service.dart';
import 'package:hidden_capacities/src/settings/settings_store.dart';
import 'package:hidden_capacities/src/transform/block_quill_transform.dart';
import 'package:hidden_capacities/src/ui/home_controller.dart';
import 'package:hidden_capacities/src/ui/home_page.dart';
import 'package:unofficial_capacities/unofficial_capacities.dart';

/// Real service + controller + widgets; only the Capacities gateway (the HTTP
/// boundary) is faked. Captures the re-encrypted blob so the proof can assert
/// only ciphertext is written.
class _FakeGateway extends CapacitiesGateway {
  _FakeGateway() : super(CapacitiesClient(apiToken: 't', dio: Dio()));

  LoadedBlock? next;
  String? lastBlob;

  @override
  Future<LoadedBlock> loadBlock(CapacitiesLink link) async => next!;

  @override
  Future<CapacitiesLink> encryptBlock({
    required String spaceId,
    required String objectId,
    required Block original,
    required String blob,
  }) async {
    lastBlob = blob;
    return CapacitiesLink(spaceId: spaceId, objectId: objectId, blockId: 'reenc');
  }
}

class _MapKv implements SecureKeyValue {
  final Map<String, String> data;
  _MapKv(this.data);
  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> write(String key, String value) async => data[key] = value;
}

void main() {
  testWidgets('decrypt -> Edit -> Save re-encrypts in place and shows the result',
      (tester) async {
    final transform = BlockQuillTransform();
    final cipher = HiddenCapCipher();
    final ops = transform.blockToDeltaOps(
        TextBlock(id: 'enc', tokens: [const TextToken('secret note')]));
    final blob = cipher.encrypt(transform.opsToJson(ops), 'pw');

    final gateway = _FakeGateway()
      ..next = LoadedBlock(
        objectId: 'obj',
        blockId: 'enc',
        block: CodeBlock(id: 'enc', lang: 'Text', text: blob),
        plainText: blob,
      );
    final service = HiddenCapService(
        gateway: gateway, cipher: cipher, transform: transform);
    final settings =
        SettingsStore(_MapKv({'passphrase': 'pw', 'auto_decrypt': 'on'}));
    final controller = HomeController(service: service, settings: settings);

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: HomePage(controller: controller, onCheckClipboard: () async {}),
        ),
      ),
    ));

    // Journey: load the encrypted block (auto-decrypts) → read-only view.
    await controller.handleClipboard('capacities://sp/obj?bid=enc');
    await tester.pump();
    expect(find.text('Decrypted'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Edit'), findsOneWidget);

    // Edit → the editable editor renders with a Save action.
    await tester.tap(find.widgetWithText(OutlinedButton, 'Edit'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.widgetWithText(FilledButton, 'Save'), findsOneWidget);
    expect(find.byType(QuillEditor), findsOneWidget);

    // Save → re-encrypts and shows the encrypted result.
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Encrypted'), findsOneWidget);

    // Only ciphertext was written back.
    expect(gateway.lastBlob, isNotNull);
    expect(gateway.lastBlob, startsWith('HIDDEN-CAP:'));

    await tester.pumpWidget(const SizedBox()); // dispose editors cleanly
  });
}
