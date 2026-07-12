import 'dart:async';

import 'package:flutter/services.dart';

/// Reads the current plain-text clipboard contents.
typedef ClipboardReader = Future<String?> Function();

/// Polls the clipboard and reports new content once per change, so a copied
/// `capacities://` deeplink is auto-detected. The reader is injectable for
/// tests; the default uses the platform clipboard.
class ClipboardWatcher {
  final ClipboardReader _read;
  final Duration interval;

  Timer? _timer;
  String? _last;

  ClipboardWatcher({
    ClipboardReader? read,
    this.interval = const Duration(seconds: 2),
  }) : _read = read ?? _platformRead;

  static Future<String?> _platformRead() async =>
      (await Clipboard.getData(Clipboard.kTextPlain))?.text;

  /// Starts polling; [onChanged] fires only when the clipboard text differs
  /// from the last seen value.
  void start(void Function(String) onChanged) {
    _timer ??= Timer.periodic(interval, (_) => _tick(onChanged));
  }

  Future<void> _tick(void Function(String) onChanged) async {
    final text = await _read();
    if (text != null && text != _last) {
      _last = text;
      onChanged(text);
    }
  }

  /// Reads the clipboard once immediately (e.g. a manual "check" action).
  Future<void> checkNow(void Function(String) onChanged) => _tick(onChanged);

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
