@Tags(['proof_edit_after_encrypt'])
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

/// Real service + controller + widgets; the gateway (HTTP boundary) is faked.
class _FakeGateway extends CapacitiesGateway {
  _FakeGateway() : super(CapacitiesClient(apiToken: 't', dio: Dio()));

  LoadedBlock? next;

  @override
  Future<LoadedBlock> loadBlock(CapacitiesLink link) async => next!;

  @override
  Future<CapacitiesLink> encryptBlock({
    required String spaceId,
    required String objectId,
    required Block original,
    required String blob,
  }) async =>
      CapacitiesLink(spaceId: spaceId, objectId: objectId, blockId: 'new-enc');
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
  testWidgets('post-encrypt Edit reopens the block in the editor',
      (tester) async {
    final transform = BlockQuillTransform();
    final cipher = HiddenCapCipher();

    final gateway = _FakeGateway()
      ..next = LoadedBlock(
        objectId: 'obj',
        blockId: 'orig',
        block: TextBlock(id: 'orig', tokens: [const TextToken('secret')]),
        plainText: 'secret',
      );
    final service = HiddenCapService(
        gateway: gateway, cipher: cipher, transform: transform);
    final settings = SettingsStore(_MapKv({'passphrase': 'pw'}));
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

    // Reach the post-encrypt success screen by encrypting a plain block.
    await controller.handleClipboard('capacities://sp/obj?bid=orig');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.widgetWithText(FilledButton, 'Encrypt'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Encrypted'), findsOneWidget);

    // The just-encrypted block, seen when Edit reloads it.
    final ops = transform.blockToDeltaOps(
        TextBlock(id: 'new-enc', tokens: [const TextToken('secret')]));
    final blob = cipher.encrypt(transform.opsToJson(ops), 'pw');
    gateway.next = LoadedBlock(
      objectId: 'obj',
      blockId: 'new-enc',
      block: CodeBlock(id: 'new-enc', lang: 'Text', text: blob),
      plainText: blob,
    );

    // Edit → reopens the block directly in the editable editor.
    await tester.tap(find.widgetWithText(OutlinedButton, 'Edit'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.widgetWithText(FilledButton, 'Save'), findsOneWidget);
    expect(find.byType(QuillEditor), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
