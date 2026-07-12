import 'dart:convert';

/// Converts a Capacities `TextBlock`'s tokens to Quill delta ops and back to
/// the JSON payload that gets encrypted.
///
/// Only the inline styles common to both systems are mapped; anything else
/// degrades to plain text (see `block-content-transform` spec). The ops list
/// always ends with a `\n` insert so it forms a valid Quill document.
class BlockQuillTransform {
  /// Capacities token style flag → Quill inline attribute key.
  static const Map<String, String> _styleToAttribute = {
    'bold': 'bold',
    'italic': 'italic',
    'strikethrough': 'strike',
    'underline': 'underline',
  };

  /// Converts a Capacities block's [tokens] (each `{type, text, style}`) into
  /// Quill delta ops (`{insert, attributes?}`), terminated by a newline insert.
  List<Map<String, dynamic>> tokensToDeltaOps(List<dynamic> tokens) {
    final ops = <Map<String, dynamic>>[];
    for (final token in tokens) {
      final map = token as Map<String, dynamic>;
      final text = map['text'] as String? ?? '';
      final attributes = _attributesFrom(map['style'] as Map<String, dynamic>?);
      ops.add({
        'insert': text,
        if (attributes.isNotEmpty) 'attributes': attributes,
      });
    }
    ops.add({'insert': '\n'});
    return ops;
  }

  /// Serializes delta [ops] to the JSON string used as the encryption payload.
  String opsToJson(List<Map<String, dynamic>> ops) => jsonEncode(ops);

  /// Parses a payload JSON string back into delta ops.
  List<Map<String, dynamic>> jsonToOps(String json) =>
      (jsonDecode(json) as List).cast<Map<String, dynamic>>();

  Map<String, dynamic> _attributesFrom(Map<String, dynamic>? style) {
    if (style == null) return const {};
    final attributes = <String, dynamic>{};
    _styleToAttribute.forEach((capacitiesKey, quillKey) {
      if (style[capacitiesKey] == true) attributes[quillKey] = true;
    });
    return attributes;
  }
}
