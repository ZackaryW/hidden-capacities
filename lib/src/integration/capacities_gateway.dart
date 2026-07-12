import 'package:unofficial_capacities/unofficial_capacities.dart';

import '../crypto/hidden_cap_cipher.dart';

/// Thrown when the object exists but has no block matching the deeplink's bid.
class BlockNotFoundException implements Exception {
  final String blockId;
  BlockNotFoundException(this.blockId);
  @override
  String toString() => 'BlockNotFoundException: $blockId';
}

/// A block resolved from a deeplink, with its plain text extracted and its
/// encrypted/plain classification.
class LoadedBlock {
  final String objectId;
  final String blockId;
  final Block block;
  final String plainText;

  LoadedBlock({
    required this.objectId,
    required this.blockId,
    required this.block,
    required this.plainText,
  });

  bool get isEncrypted => HiddenCapCipher.isHiddenCap(plainText);
}

/// Thin wrapper over `CapacitiesClient` for the operations hidden-capacities
/// needs: resolve the deeplinked block and (later) write it back in place.
class CapacitiesGateway {
  final CapacitiesClient _client;

  CapacitiesGateway(this._client);

  /// Fetches the object referenced by [link] and locates the block named by
  /// its bid. Requires a block-specific link (see `clipboard-deeplink`).
  Future<LoadedBlock> loadBlock(CapacitiesLink link) async {
    final blockId = link.blockId;
    if (blockId == null) {
      throw ArgumentError('deeplink must target a specific block (bid)');
    }
    final object = await _client.getObject(id: link.objectId);
    final block = _locate(object, blockId);
    if (block == null) throw BlockNotFoundException(blockId);
    return LoadedBlock(
      objectId: link.objectId,
      blockId: blockId,
      block: block,
      plainText: _plainText(block),
    );
  }

  Block? _locate(ApiObject object, String blockId) {
    for (final propertyId in (object.blocks ?? const {}).keys) {
      final found = _search(object.blocksIn(propertyId), blockId);
      if (found != null) return found;
    }
    return null;
  }

  Block? _search(List<Block> blocks, String blockId) {
    for (final block in blocks) {
      if (block.id == blockId) return block;
      final nested = _search(_childrenOf(block), blockId);
      if (nested != null) return nested;
    }
    return null;
  }

  /// Child blocks live on different arms of the union.
  List<Block> _childrenOf(Block block) => switch (block) {
        TextBlock(:final blocks) => blocks,
        GroupBlock(:final blocks) => blocks,
        GridBlock(:final columns) => columns.expand((c) => c).toList(),
        _ => const [],
      };

  /// The block's plain single-line content for HIDDEN-CAP detection:
  /// a `CodeBlock`'s `text`, or a `TextBlock`'s concatenated token text.
  String _plainText(Block block) => switch (block) {
        CodeBlock(:final text) => text,
        TextBlock(:final tokens) => tokens
            .map((t) => switch (t) {
                  TextToken(:final text) => text,
                  LinkToken(:final text) => text,
                  MathToken(:final text) => text,
                  CodeToken(:final text) => text,
                  UnsupportedToken() => '',
                })
            .join(),
        _ => '',
      };
}
