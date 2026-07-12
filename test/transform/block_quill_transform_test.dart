import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hidden_capacities/src/transform/block_quill_transform.dart';

void main() {
  final transform = BlockQuillTransform();

  group('tokensToDeltaOps', () {
    test('maps supported inline styles to Quill attributes', () {
      final ops = transform.tokensToDeltaOps([
        {
          'type': 'TextToken',
          'text': 'Hello ',
          'style': {'bold': true},
        },
        {
          'type': 'TextToken',
          'text': 'world',
          'style': {'italic': true, 'strikethrough': true, 'underline': true},
        },
      ]);

      expect(ops, [
        {
          'insert': 'Hello ',
          'attributes': {'bold': true},
        },
        {
          'insert': 'world',
          'attributes': {'italic': true, 'strike': true, 'underline': true},
        },
        {'insert': '\n'},
      ]);
    });

    test('omits attributes for false flags and unmapped styles (degrade to plain)', () {
      final ops = transform.tokensToDeltaOps([
        {
          'type': 'TextToken',
          'text': 'plain',
          'style': {'bold': false, 'color': 'red'},
        },
      ]);

      expect(ops, [
        {'insert': 'plain'},
        {'insert': '\n'},
      ]);
    });

    test('handles a token with no style key', () {
      final ops = transform.tokensToDeltaOps([
        {'type': 'TextToken', 'text': 'bare'},
      ]);

      expect(ops, [
        {'insert': 'bare'},
        {'insert': '\n'},
      ]);
    });

    test('empty token list yields an empty Quill document', () {
      expect(transform.tokensToDeltaOps([]), [
        {'insert': '\n'},
      ]);
    });

    test('always terminates with a newline insert (valid Quill document)', () {
      final ops = transform.tokensToDeltaOps([
        {'type': 'TextToken', 'text': 'no trailing newline in source'},
      ]);

      expect((ops.last)['insert'], '\n');
    });
  });

  group('flutter_quill compatibility', () {
    test('ops load as a valid Quill Document with matching plain text', () {
      final ops = transform.tokensToDeltaOps([
        {
          'type': 'TextToken',
          'text': 'Hello ',
          'style': {'bold': true},
        },
        {'type': 'TextToken', 'text': 'world'},
      ]);

      final doc = Document.fromJson(ops);
      expect(doc.toPlainText(), 'Hello world\n');
    });
  });

  group('payload JSON round trip', () {
    test('opsToJson then jsonToOps recovers the ops', () {
      final ops = transform.tokensToDeltaOps([
        {
          'type': 'TextToken',
          'text': 'round trip',
          'style': {'bold': true},
        },
      ]);

      final json = transform.opsToJson(ops);
      expect(transform.jsonToOps(json), ops);
    });
  });
}
