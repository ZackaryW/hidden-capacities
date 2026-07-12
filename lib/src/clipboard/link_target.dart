import 'package:unofficial_capacities/unofficial_capacities.dart';

/// How a clipboard string relates to a Capacities deeplink target.
enum LinkTargetKind {
  /// Not a `capacities://` link at all — ignore it.
  notADeeplink,

  /// A `capacities://` link that fails to parse (missing space/object).
  malformed,

  /// A valid link but without a `?bid=` — the app needs a specific block.
  needsBlock,

  /// A valid, block-specific link ready to act on.
  ready,
}

/// The classification of a clipboard string against the deeplink target rules.
///
/// Only [LinkTargetKind.ready] carries a parsed [link]; the caller acts only on
/// block-specific links (see the `clipboard-deeplink` spec).
class LinkTarget {
  final LinkTargetKind kind;
  final CapacitiesLink? link;

  const LinkTarget._(this.kind, [this.link]);

  static LinkTarget resolve(String clipboard) {
    final text = clipboard.trim();
    if (!text.startsWith('capacities://')) {
      return const LinkTarget._(LinkTargetKind.notADeeplink);
    }
    final link = CapacitiesLink.tryParse(text);
    if (link == null) {
      return const LinkTarget._(LinkTargetKind.malformed);
    }
    if (link.blockId == null) {
      return const LinkTarget._(LinkTargetKind.needsBlock);
    }
    return LinkTarget._(LinkTargetKind.ready, link);
  }
}
