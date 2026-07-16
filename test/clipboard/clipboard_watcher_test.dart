import 'package:flutter_test/flutter_test.dart';
import 'package:hidden_capacities/src/clipboard/clipboard_watcher.dart';

void main() {
  group('ClipboardWatcher.checkNow', () {
    test('fires onChanged with the current clipboard text', () async {
      final watcher = ClipboardWatcher(read: () async => 'capacities://sp/obj?bid=b');
      String? seen;
      await watcher.checkNow((raw) => seen = raw);
      expect(seen, 'capacities://sp/obj?bid=b');
    });

    test('does not fire when the clipboard is unchanged since last check', () async {
      final watcher = ClipboardWatcher(read: () async => 'same');
      var fires = 0;
      await watcher.checkNow((_) => fires++);
      await watcher.checkNow((_) => fires++);
      expect(fires, 1);
    });

    test('fires again when the clipboard changes', () async {
      var value = 'first';
      final watcher = ClipboardWatcher(read: () async => value);
      final seen = <String>[];
      await watcher.checkNow(seen.add);
      value = 'second';
      await watcher.checkNow(seen.add);
      expect(seen, ['first', 'second']);
    });

    test('does not fire on a null clipboard', () async {
      final watcher = ClipboardWatcher(read: () async => null);
      var fires = 0;
      await watcher.checkNow((_) => fires++);
      expect(fires, 0);
    });
  });
}
