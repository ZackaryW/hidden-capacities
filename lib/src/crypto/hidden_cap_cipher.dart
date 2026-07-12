import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// Thrown when a HIDDEN-CAP blob fails to authenticate — i.e. the passphrase
/// is wrong (GCM tag mismatch).
class WrongPasswordException implements Exception {
  @override
  String toString() => 'WrongPasswordException';
}

/// Thrown when a string is not a well-formed HIDDEN-CAP blob (missing marker,
/// invalid base64, or too short to contain salt + nonce + tag).
class MalformedBlobException implements Exception {
  final String message;
  MalformedBlobException(this.message);
  @override
  String toString() => 'MalformedBlobException: $message';
}

/// Encrypts/decrypts the `HIDDEN-CAP:<base64(salt||nonce||ciphertext||tag)>`
/// blob format with AES-256-GCM under a PBKDF2-derived key.
///
/// All parameters needed to decrypt (salt, nonce, tag) travel inside the blob,
/// so any device with the passphrase can decrypt it.
class HiddenCapCipher {
  static const String marker = 'HIDDEN-CAP:';

  static const int _saltLen = 16;
  static const int _nonceLen = 12;
  static const int _tagBytes = 16; // 128-bit GCM tag
  static const int _keyLen = 32; // AES-256
  static const int _iterations = 100000;

  final Random _random;

  HiddenCapCipher({Random? random}) : _random = random ?? Random.secure();

  /// True iff [content] is a HIDDEN-CAP blob (starts with the marker).
  static bool isHiddenCap(String content) => content.startsWith(marker);

  /// Encrypts [plaintext] under [passphrase] into a single-line HIDDEN-CAP blob.
  String encrypt(String plaintext, String passphrase) {
    final salt = _randomBytes(_saltLen);
    final nonce = _randomBytes(_nonceLen);
    final key = _deriveKey(passphrase, salt);

    final cipherWithTag = _gcm(forEncryption: true, key: key, nonce: nonce)
        .process(Uint8List.fromList(utf8.encode(plaintext)));

    final body = Uint8List.fromList([...salt, ...nonce, ...cipherWithTag]);
    return '$marker${base64.encode(body)}';
  }

  /// Decrypts a HIDDEN-CAP [blob] under [passphrase].
  ///
  /// Throws [MalformedBlobException] if [blob] is not a well-formed blob, or
  /// [WrongPasswordException] if the passphrase does not authenticate.
  String decrypt(String blob, String passphrase) {
    if (!isHiddenCap(blob)) {
      throw MalformedBlobException('missing "$marker" marker');
    }
    Uint8List bytes;
    try {
      bytes = base64.decode(blob.substring(marker.length));
    } on FormatException {
      throw MalformedBlobException('body is not valid base64');
    }
    if (bytes.length < _saltLen + _nonceLen + _tagBytes) {
      throw MalformedBlobException('blob too short for salt + nonce + tag');
    }

    final salt = bytes.sublist(0, _saltLen);
    final nonce = bytes.sublist(_saltLen, _saltLen + _nonceLen);
    final cipherWithTag = bytes.sublist(_saltLen + _nonceLen);
    final key = _deriveKey(passphrase, salt);

    try {
      final plain =
          _gcm(forEncryption: false, key: key, nonce: nonce).process(cipherWithTag);
      return utf8.decode(plain);
    } on InvalidCipherTextException {
      throw WrongPasswordException();
    }
  }

  Uint8List _deriveKey(String passphrase, Uint8List salt) {
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, _iterations, _keyLen));
    return derivator.process(Uint8List.fromList(utf8.encode(passphrase)));
  }

  GCMBlockCipher _gcm({
    required bool forEncryption,
    required Uint8List key,
    required Uint8List nonce,
  }) {
    return GCMBlockCipher(AESEngine())
      ..init(
        forEncryption,
        AEADParameters(KeyParameter(key), _tagBytes * 8, nonce, Uint8List(0)),
      );
  }

  Uint8List _randomBytes(int n) =>
      Uint8List.fromList(List<int>.generate(n, (_) => _random.nextInt(256)));
}
