import 'package:unofficial_capacities/unofficial_capacities.dart';

import '../crypto/hidden_cap_cipher.dart';
import '../integration/capacities_gateway.dart';
import '../transform/block_quill_transform.dart';

/// Orchestrates the encrypt/decrypt operations over a deeplinked block,
/// composing the gateway (Capacities I/O), cipher (AES-GCM), and transform
/// (Block ↔ Quill delta). Headless — the UI drives this.
class HiddenCapService {
  final CapacitiesGateway gateway;
  final HiddenCapCipher cipher;
  final BlockQuillTransform transform;

  HiddenCapService({
    required this.gateway,
    required this.cipher,
    required this.transform,
  });

  /// Encrypts [target]'s content and stores it as a HIDDEN-CAP code block,
  /// returning the deeplink to the new block.
  ///
  /// Throws [UnsupportedBlockException] if the block type has no clean Quill
  /// conversion (e.g. tables, images).
  Future<CapacitiesLink> encrypt({
    required LoadedBlock target,
    required String passphrase,
    required String spaceId,
  }) async {
    final payload = transform.opsToJson(transform.blockToDeltaOps(target.block));
    final blob = cipher.encrypt(payload, passphrase);
    return gateway.encryptBlock(
      spaceId: spaceId,
      objectId: target.objectId,
      originalBlockId: target.blockId,
      blob: blob,
    );
  }

  /// Decrypts [target]'s HIDDEN-CAP blob into Quill delta ops for read-only
  /// display. Throws [WrongPasswordException] or [MalformedBlobException].
  List<Map<String, dynamic>> decrypt({
    required LoadedBlock target,
    required String passphrase,
  }) {
    final payload = cipher.decrypt(target.plainText, passphrase);
    return transform.jsonToOps(payload);
  }
}
