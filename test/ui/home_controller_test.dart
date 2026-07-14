import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hidden_capacities/src/crypto/hidden_cap_cipher.dart';
import 'package:hidden_capacities/src/integration/capacities_gateway.dart';
import 'package:hidden_capacities/src/service/hidden_cap_service.dart';
import 'package:hidden_capacities/src/settings/settings_store.dart';
import 'package:hidden_capacities/src/transform/block_quill_transform.dart';
import 'package:hidden_capacities/src/ui/home_controller.dart';
import 'package:unofficial_capacities/unofficial_capacities.dart';

class _FakeGateway extends CapacitiesGateway {
  _FakeGateway() : super(CapacitiesClient(apiToken: 't', dio: Dio()));

  LoadedBlock? next;
  Object? loadError;

  @override
  Future<LoadedBlock> loadBlock(CapacitiesLink link) async {
    if (loadError != null) throw loadError!;
    return next!;
  }

  @override
  Future<CapacitiesLink> encryptBlock({
    required String spaceId,
    required String objectId,
    required Block original,
    required String blob,
  }) async =>
      CapacitiesLink(spaceId: spaceId, objectId: objectId, blockId: 'new-code');
}

class _MapKv implements SecureKeyValue {
  final Map<String, String> data = {};
  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> write(String key, String value) async => data[key] = value;
}

void main() {
  late _FakeGateway gateway;
  late _MapKv kv;
  late SettingsStore settings;
  late HiddenCapService service;
  late HomeController controller;

  setUp(() {
    gateway = _FakeGateway();
    kv = _MapKv();
    settings = SettingsStore(kv);
    service = HiddenCapService(
      gateway: gateway,
      cipher: HiddenCapCipher(),
      transform: BlockQuillTransform(),
    );
    controller = HomeController(service: service, settings: settings);
  });

  LoadedBlock plain() => LoadedBlock(
        objectId: 'obj-1',
        blockId: 'orig',
        block: TextBlock(id: 'orig', tokens: [const TextToken('secret')]),
        plainText: 'secret',
      );

  LoadedBlock encryptedWith(String passphrase) {
    final blob = HiddenCapCipher().encrypt(
      BlockQuillTransform()
          .opsToJson(BlockQuillTransform().blockToDeltaOps(plain().block)),
      passphrase,
    );
    return LoadedBlock(
      objectId: 'obj-1',
      blockId: 'enc',
      block: CodeBlock(lang: 'Text', text: blob),
      plainText: blob,
    );
  }

  group('clipboard handling', () {
    test('non-deeplink content leaves the state idle', () async {
      await controller.handleClipboard('just text');
      expect(controller.state, isA<HomeIdle>());
    });

    test('object-only link asks for a specific block', () async {
      await controller.handleClipboard('capacities://sp/obj');
      expect(controller.state, isA<HomeNeedsBlock>());
    });

    test('a ready link to a plain block offers encryption', () async {
      gateway.next = plain();
      await controller.handleClipboard('capacities://sp/obj?bid=orig');
      expect(controller.state, isA<HomeLoadedPlain>());
    });

    test('an API error surfaces as an error state', () async {
      gateway.loadError =
          CapacitiesApiException(httpStatus: 401, message: 'no');
      await controller.handleClipboard('capacities://sp/obj?bid=orig');
      expect(controller.state, isA<HomeError>());
    });
  });

  group('auto-decrypt', () {
    test('Off leaves an encrypted block awaiting a manual action', () async {
      await settings.saveAutoDecrypt(AutoDecrypt.off);
      gateway.next = encryptedWith('pw');
      await controller.handleClipboard('capacities://sp/obj?bid=enc');
      expect(controller.state, isA<HomeLoadedEncrypted>());
    });

    test('On with the correct passphrase decrypts and yields delta', () async {
      await settings.saveAutoDecrypt(AutoDecrypt.on);
      await settings.savePassphrase('pw');
      gateway.next = encryptedWith('pw');
      await controller.handleClipboard('capacities://sp/obj?bid=enc');
      expect(controller.state, isA<HomeDecrypted>());
      expect((controller.state as HomeDecrypted).deltaOps, isNotEmpty);
    });

    test('On with the wrong passphrase surfaces incorrect-password', () async {
      await settings.saveAutoDecrypt(AutoDecrypt.on);
      await settings.savePassphrase('wrong');
      gateway.next = encryptedWith('right');
      await controller.handleClipboard('capacities://sp/obj?bid=enc');
      expect(controller.state, isA<HomeWrongPassword>());
    });
  });

  group('more branches', () {
    test('a malformed capacities link surfaces invalid-link', () async {
      await controller.handleClipboard('capacities://sp');
      expect(controller.state, isA<HomeInvalidLink>());
    });

    test('block-not-found surfaces an error', () async {
      gateway.loadError = BlockNotFoundException('missing');
      await controller.handleClipboard('capacities://sp/obj?bid=missing');
      expect(controller.state, isA<HomeError>());
    });

    test('manual decrypt (Off path) with the right passphrase yields delta',
        () async {
      await settings.saveAutoDecrypt(AutoDecrypt.off);
      await settings.savePassphrase('pw');
      gateway.next = encryptedWith('pw');
      await controller.handleClipboard('capacities://sp/obj?bid=enc');
      expect(controller.state, isA<HomeLoadedEncrypted>());

      await controller.decryptCurrent();
      expect(controller.state, isA<HomeDecrypted>());
    });

    test('encrypt without a passphrase surfaces an error', () async {
      gateway.next = plain();
      await controller.handleClipboard('capacities://sp/obj?bid=orig');
      final ops = (controller.state as HomeLoadedPlain).initialOps;
      await controller.encryptCurrent(ops);
      expect(controller.state, isA<HomeError>());
    });

    test('a plain but unsupported block surfaces an error', () async {
      gateway.next = LoadedBlock(
        objectId: 'obj-1',
        blockId: 'orig',
        block: const GridBlock(),
        plainText: '',
      );
      await controller.handleClipboard('capacities://sp/obj?bid=orig');
      expect(controller.state, isA<HomeError>());
    });
  });

  group('actions', () {
    test('a plain block loads its content as editable initial ops', () async {
      gateway.next = plain();
      await controller.handleClipboard('capacities://sp/obj?bid=orig');
      expect((controller.state as HomeLoadedPlain).initialOps, isNotEmpty);
    });

    test('encrypt on a plain target yields the new deeplink', () async {
      await settings.savePassphrase('pw');
      gateway.next = plain();
      await controller.handleClipboard('capacities://sp/obj?bid=orig');
      final ops = (controller.state as HomeLoadedPlain).initialOps;

      await controller.encryptCurrent(ops);
      expect(controller.state, isA<HomeEncrypted>());
      // Encryption creates a new code block at the original's slot; new id.
      expect((controller.state as HomeEncrypted).link.blockId, 'new-code');
    });
  });
}
