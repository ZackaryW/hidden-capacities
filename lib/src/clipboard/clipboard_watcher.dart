import 'package:flutter/services.dart';

/// Reads the current plain-text clipboard contents.
typedef ClipboardReader = Future<String?> Function();

/// Reads the clipboard on demand and reports a candidate once per change.
///
/// There is no background polling: the app checks the clipboard when its
/// window gains focus (and on an explicit "check" action), so a copied
/// `capacities://` deeplink is picked up without a running timer. The reader
/// is injectable for tests; the default uses the platform clipboard.
class ClipboardWatcher {
  final ClipboardReader _read;
  String? _last;

  ClipboardWatcher({ClipboardReader? read}) : _read = read ?? _platformRead;

  static Future<String?> _platformRead() async =>
      (await Clipboard.getData(Clipboard.kTextPlain))?.text;

  /// Reads the clipboard once; [onChanged] fires only when the text differs
  /// from the last value seen, so re-focusing with an unchanged clipboard is
  /// a no-op.
  Future<void> checkNow(void Function(String) onChanged) async {
    final text = await _read();
    if (text != null && text != _last) {
      _last = text;
      onChanged(text);
    }
  }
}
