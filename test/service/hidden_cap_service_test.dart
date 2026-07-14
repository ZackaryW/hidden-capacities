import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hidden_capacities/src/crypto/hidden_cap_cipher.dart';
import 'package:hidden_capacities/src/integration/capacities_gateway.dart';
import 'package:hidden_capacities/src/service/hidden_cap_service.dart';
import 'package:hidden_capacities/src/transform/block_quill_transform.dart';
import 'package:unofficial_capacities/unofficial_capacities.dart';

/// Fake gateway: the HIDDEN-CAP blob is random (salt/nonce), so we capture it
/// rather than match exact request bytes.
class _FakeGateway extends CapacitiesGateway {
  _FakeGateway() : super(CapacitiesClient(apiToken: 't', dio: Dio()));

  String? capturedBlob;

  @override
  Future<CapacitiesLink> encryptBlock({
    required String spaceId,
    required String objectId,
    required Block original,
    required String blob,
  }) async {
    capturedBlob = blob;
    // In-place: the deeplink keeps the original block id.
    return CapacitiesLink(spaceId: spaceId, objectId: objectId, blockId: original.id);
  }
}

void main() {
  late _FakeGateway gateway;
  late HiddenCapService service;

  setUp(() {
    gateway = _FakeGateway();
    service = HiddenCapService(
      gateway: gateway,
      cipher: HiddenCapCipher(),
      transform: BlockQuillTransform(),
    );
  });

  LoadedBlock plainTarget() => LoadedBlock(
        objectId: 'obj-1',
        blockId: 'orig',
        block: TextBlock(id: 'orig', tokens: [const TextToken('secret note')]),
        plainText: 'secret note',
      );

  test('encrypt then decrypt round-trips the editor delta ops', () async {
    final target = plainTarget();
    final ops = service.editableOps(target.block);

    final link = await service.encrypt(
      target: target,
      deltaOps: ops,
      passphrase: 'pw',
      spaceId: 'sp',
    );

    // Wrote a HIDDEN-CAP blob; the deeplink keeps the original block id.
    expect(link.blockId, 'orig');
    expect(gateway.capturedBlob, startsWith('HIDDEN-CAP:'));

    // Decrypting that blob recovers exactly the delta ops that were encrypted.
    final encryptedTarget = LoadedBlock(
      objectId: 'obj-1',
      blockId: 'orig',
      block: CodeBlock(lang: 'Text', text: gateway.capturedBlob!),
      plainText: gateway.capturedBlob!,
    );

    expect(service.decrypt(target: encryptedTarget, passphrase: 'pw'), ops);
  });

  test('decrypt with the wrong passphrase throws WrongPasswordException', () async {
    final target = plainTarget();
    await service.encrypt(
      target: target,
      deltaOps: service.editableOps(target.block),
      passphrase: 'right',
      spaceId: 'sp',
    );

    final encryptedTarget = LoadedBlock(
      objectId: 'obj-1',
      blockId: 'new-code',
      block: CodeBlock(lang: 'Text', text: gateway.capturedBlob!),
      plainText: gateway.capturedBlob!,
    );

    expect(
      () => service.decrypt(target: encryptedTarget, passphrase: 'wrong'),
      throwsA(isA<WrongPasswordException>()),
    );
  });

  test('editableOps on a supported block returns its Quill delta', () {
    expect(
      service.editableOps(plainTarget().block),
      BlockQuillTransform().blockToDeltaOps(plainTarget().block),
    );
  });

  test('editableOps on an unsupported block surfaces UnsupportedBlockException',
      () {
    expect(
      () => service.editableOps(const GridBlock()),
      throwsA(isA<UnsupportedBlockException>()),
    );
  });
}
