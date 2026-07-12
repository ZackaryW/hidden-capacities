import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hidden_capacities/src/crypto/hidden_cap_cipher.dart';

void main() {
  final cipher = HiddenCapCipher();

  group('encrypt', () {
    test('produces a HIDDEN-CAP: single-line blob', () {
      final blob = cipher.encrypt('secret text', 'pass');

      expect(blob.startsWith('HIDDEN-CAP:'), isTrue);
      expect(blob.contains('\n'), isFalse);
      // Body after the marker is valid base64.
      final body = blob.substring('HIDDEN-CAP:'.length);
      expect(() => base64.decode(body), returnsNormally);
    });

    test('two encryptions of the same input differ (random salt+nonce)', () {
      final a = cipher.encrypt('secret', 'pass');
      final b = cipher.encrypt('secret', 'pass');

      expect(a, isNot(equals(b)));
    });
  });

  group('decrypt', () {
    test('round-trips the plaintext with the correct passphrase', () {
      const plaintext = 'the quick brown fox — δ ✓ 🦊';
      final blob = cipher.encrypt(plaintext, 'correct horse');

      expect(cipher.decrypt(blob, 'correct horse'), plaintext);
    });

    test('throws WrongPasswordException for a wrong passphrase', () {
      final blob = cipher.encrypt('secret', 'right');

      expect(
        () => cipher.decrypt(blob, 'wrong'),
        throwsA(isA<WrongPasswordException>()),
      );
    });

    test('throws MalformedBlobException when the marker is missing', () {
      expect(
        () => cipher.decrypt('not a hidden-cap blob', 'pass'),
        throwsA(isA<MalformedBlobException>()),
      );
    });

    test('throws MalformedBlobException for non-base64 body', () {
      expect(
        () => cipher.decrypt('HIDDEN-CAP:@@@not-base64@@@', 'pass'),
        throwsA(isA<MalformedBlobException>()),
      );
    });

    test('throws MalformedBlobException when body is too short for salt+nonce+tag', () {
      final tooShort = 'HIDDEN-CAP:${base64.encode(List<int>.filled(8, 0))}';

      expect(
        () => cipher.decrypt(tooShort, 'pass'),
        throwsA(isA<MalformedBlobException>()),
      );
    });
  });

  group('cross-instance', () {
    test('a blob encrypted by one instance decrypts on another with same passphrase', () {
      final blob = HiddenCapCipher().encrypt('shared', 'k');

      expect(HiddenCapCipher().decrypt(blob, 'k'), 'shared');
    });
  });

  group('isHiddenCap', () {
    test('true for a HIDDEN-CAP: string', () {
      expect(HiddenCapCipher.isHiddenCap('HIDDEN-CAP:abc'), isTrue);
    });

    test('false for plain content', () {
      expect(HiddenCapCipher.isHiddenCap('just some text'), isFalse);
    });

    test('false for leading whitespace before the marker', () {
      expect(HiddenCapCipher.isHiddenCap('  HIDDEN-CAP:abc'), isFalse);
    });
  });
}
