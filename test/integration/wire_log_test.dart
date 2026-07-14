import 'package:flutter_test/flutter_test.dart';
import 'package:hidden_capacities/src/integration/wire_log.dart';

void main() {
  group('formatWireLog', () {
    test('pretty-prints the raw JSON body under an endpoint header', () {
      final out = formatWireLog('GET https://api.capacities.io/object?id=o1', {
        'id': 'o1',
        'blocks': {
          'notes': [
            {'id': 'b1', 'type': 'CodeBlock', 'text': 'HIDDEN-CAP:abc'},
          ],
        },
      });

      expect(out, contains('── capacities wire ── GET https://api.capacities.io/object?id=o1'));
      // Pretty-printed (indented) so nested block shapes are readable per type.
      expect(out, contains('"type": "CodeBlock"'));
      expect(out, contains('"text": "HIDDEN-CAP:abc"'));
      expect(out, contains('\n'));
    });

    test('marks an empty response body', () {
      expect(
        formatWireLog('POST https://api.capacities.io/blocks/daily-note/append', null),
        contains('(no body)'),
      );
    });
  });
}
