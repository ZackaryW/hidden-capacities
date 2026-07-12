import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hidden_capacities/src/transform/block_quill_transform.dart';
import 'package:unofficial_capacities/unofficial_capacities.dart';

void main() {
  final transform = BlockQuillTransform();

  group('blockToDeltaOps — TextBlock', () {
    test('maps supported inline styles to Quill attributes', () {
      final ops = transform.blockToDeltaOps(TextBlock(tokens: [
        const TextToken('Hello ', style: TokenStyle(bold: true)),
        const TextToken('world',
            style: TokenStyle(italic: true, strikethrough: true, underline: true)),
      ]));

      expect(ops, [
        {'insert': 'Hello ', 'attributes': {'bold': true}},
        {'insert': 'world', 'attributes': {'italic': true, 'strike': true, 'underline': true}},
        {'insert': '\n'},
      ]);
    });

    test('LinkToken becomes a link attribute; math/code tokens are plain text', () {
      final ops = transform.blockToDeltaOps(TextBlock(tokens: [
        const LinkToken('site', url: 'https://x.io'),
        const MathToken('E=mc^2'),
      ]));

      expect(ops, [
        {'insert': 'site', 'attributes': {'link': 'https://x.io'}},
        {'insert': 'E=mc^2'},
        {'insert': '\n'},
      ]);
    });

    test('empty TextBlock yields an empty Quill document', () {
      expect(transform.blockToDeltaOps(TextBlock()), [
        {'insert': '\n'},
      ]);
    });
  });

  group('blockToDeltaOps — CodeBlock', () {
    test('renders lines with the code-block attribute', () {
      final ops = transform.blockToDeltaOps(
          const CodeBlock(lang: 'Text', text: 'line1\nline2'));

      expect(ops, [
        {'insert': 'line1'},
        {'insert': '\n', 'attributes': {'code-block': true}},
        {'insert': 'line2'},
        {'insert': '\n', 'attributes': {'code-block': true}},
      ]);
    });
  });

  group('blockToDeltaOps — unsupported', () {
    test('GridBlock (table) throws UnsupportedBlockException for now', () {
      expect(
        () => transform.blockToDeltaOps(const GridBlock()),
        throwsA(isA<UnsupportedBlockException>()),
      );
    });

    test('EntityBlock (image/media) throws UnsupportedBlockException', () {
      expect(
        () => transform.blockToDeltaOps(const EntityBlock(entityId: 'e')),
        throwsA(isA<UnsupportedBlockException>()),
      );
    });
  });

  group('flutter_quill compatibility', () {
    test('TextBlock ops load as a valid Quill Document', () {
      final ops = transform.blockToDeltaOps(TextBlock(tokens: [
        const TextToken('Hello '),
        const TextToken('world'),
      ]));

      expect(Document.fromJson(ops).toPlainText(), 'Hello world\n');
    });
  });

  group('payload JSON round trip', () {
    test('opsToJson then jsonToOps recovers the ops', () {
      final ops = transform
          .blockToDeltaOps(TextBlock(tokens: [const TextToken('round trip')]));

      expect(transform.jsonToOps(transform.opsToJson(ops)), ops);
    });
  });
}
