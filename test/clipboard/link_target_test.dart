import 'package:flutter_test/flutter_test.dart';
import 'package:hidden_capacities/src/clipboard/link_target.dart';

void main() {
  group('LinkTarget.resolve', () {
    test('non-deeplink content is ignored', () {
      expect(LinkTarget.resolve('just some text').kind, LinkTargetKind.notADeeplink);
      expect(LinkTarget.resolve('https://example.com').kind, LinkTargetKind.notADeeplink);
    });

    test('a block-specific deeplink is ready with a parsed link', () {
      final target = LinkTarget.resolve('capacities://sp/obj?bid=b1');

      expect(target.kind, LinkTargetKind.ready);
      expect(target.link!.spaceId, 'sp');
      expect(target.link!.objectId, 'obj');
      expect(target.link!.blockId, 'b1');
    });

    test('an object-only deeplink needs a specific block', () {
      final target = LinkTarget.resolve('capacities://sp/obj');

      expect(target.kind, LinkTargetKind.needsBlock);
      expect(target.link, isNull);
    });

    test('a capacities:// link missing its object id is malformed', () {
      expect(LinkTarget.resolve('capacities://sp').kind, LinkTargetKind.malformed);
    });

    test('surrounding whitespace is tolerated', () {
      final target = LinkTarget.resolve('  capacities://sp/obj?bid=b1\n');

      expect(target.kind, LinkTargetKind.ready);
      expect(target.link!.blockId, 'b1');
    });
  });
}
