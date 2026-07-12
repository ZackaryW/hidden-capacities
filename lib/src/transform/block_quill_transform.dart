import 'dart:convert';

import 'package:unofficial_capacities/unofficial_capacities.dart';

/// Thrown when a block type has no clean, self-contained conversion to a Quill
/// delta (e.g. tables, images) — see the `block-content-transform` scope.
class UnsupportedBlockException implements Exception {
  final String blockType;
  UnsupportedBlockException(this.blockType);
  @override
  String toString() => 'UnsupportedBlockException: $blockType';
}

/// Converts a supported Capacities [Block] to Quill delta ops (the plaintext
/// payload that gets encrypted) and back to/from the JSON payload string.
///
/// Supported source blocks: `TextBlock` (inline styles + links) and
/// `CodeBlock`. Headings (heading-level mapping) and tables (`GridBlock`) are
/// not yet mapped and raise [UnsupportedBlockException]; image/media
/// (`EntityBlock`) and others are intentionally excluded.
class BlockQuillTransform {
  /// Converts [block] to Quill delta ops, always terminated by a newline
  /// insert so the ops form a valid Quill document.
  List<Map<String, dynamic>> blockToDeltaOps(Block block) => switch (block) {
        TextBlock(:final tokens) => _textOps(tokens),
        CodeBlock(:final text) => _codeOps(text),
        _ => throw UnsupportedBlockException(_typeName(block)),
      };

  String opsToJson(List<Map<String, dynamic>> ops) => jsonEncode(ops);

  List<Map<String, dynamic>> jsonToOps(String json) =>
      (jsonDecode(json) as List).cast<Map<String, dynamic>>();

  List<Map<String, dynamic>> _textOps(List<Token> tokens) {
    final ops = <Map<String, dynamic>>[];
    for (final token in tokens) {
      final (text, attributes) = _tokenInsert(token);
      ops.add({
        'insert': text,
        if (attributes.isNotEmpty) 'attributes': attributes,
      });
    }
    ops.add({'insert': '\n'});
    return ops;
  }

  (String, Map<String, dynamic>) _tokenInsert(Token token) => switch (token) {
        TextToken(:final text, :final style) => (text, _styleAttributes(style)),
        LinkToken(:final text, :final url) => (text, {'link': ?url}),
        MathToken(:final text) => (text, const {}),
        CodeToken(:final text) => (text, const {}),
        UnsupportedToken() => ('', const {}),
      };

  Map<String, dynamic> _styleAttributes(TokenStyle style) => {
        if (style.bold) 'bold': true,
        if (style.italic) 'italic': true,
        if (style.strikethrough) 'strike': true,
        if (style.underline) 'underline': true,
      };

  List<Map<String, dynamic>> _codeOps(String text) {
    final ops = <Map<String, dynamic>>[];
    for (final line in text.split('\n')) {
      if (line.isNotEmpty) ops.add({'insert': line});
      ops.add({
        'insert': '\n',
        'attributes': {'code-block': true},
      });
    }
    return ops;
  }

  String _typeName(Block block) => switch (block) {
        GridBlock() => 'GridBlock',
        GroupBlock() => 'GroupBlock',
        MathBlock() => 'MathBlock',
        EntityBlock() => 'EntityBlock',
        HorizontalLineBlock() => 'HorizontalLineBlock',
        UnsupportedBlock(:final blockType) => blockType,
        _ => 'unknown',
      };
}
