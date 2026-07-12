## ADDED Requirements

### Requirement: Passphrase-derived AES-GCM key
The system SHALL derive a 256-bit AES key from a user passphrase using PBKDF2-HMAC-SHA256 with a random per-blob salt, via pointycastle.

#### Scenario: Deterministic key for same inputs
- **WHEN** the same passphrase and salt are supplied
- **THEN** the derived key is identical, so a blob encrypted on one device decrypts on another with the same passphrase

### Requirement: HIDDEN-CAP encrypt
The system SHALL encrypt a plaintext payload with AES-256-GCM (random 12-byte nonce, 128-bit tag) and produce the single-line string `HIDDEN-CAP:<base64(salt || nonce || ciphertext || tag)>`.

#### Scenario: Encrypt produces a self-contained blob
- **WHEN** a plaintext payload is encrypted with a passphrase
- **THEN** the output begins with the `HIDDEN-CAP:` marker and its base64 body carries the salt, nonce, ciphertext, and tag needed to decrypt with only the passphrase

### Requirement: HIDDEN-CAP decrypt with wrong-password detection
The system SHALL decrypt a `HIDDEN-CAP:` blob with the passphrase, and SHALL distinguish three outcomes: success (plaintext recovered), wrong passphrase (GCM authentication failure), and malformed blob (marker/base64/length invalid).

#### Scenario: Correct passphrase
- **WHEN** a `HIDDEN-CAP:` blob is decrypted with the passphrase used to create it
- **THEN** the original plaintext payload is recovered

#### Scenario: Wrong passphrase
- **WHEN** a `HIDDEN-CAP:` blob is decrypted with a different passphrase
- **THEN** the operation reports an "incorrect password" outcome distinct from other errors

#### Scenario: Malformed blob
- **WHEN** a string is missing the `HIDDEN-CAP:` marker, is not valid base64, or is too short to contain salt+nonce+tag
- **THEN** the operation reports a "malformed blob" outcome distinct from a wrong-password outcome

### Requirement: HIDDEN-CAP detection
The system SHALL determine whether a given block's content is a HIDDEN-CAP blob by testing for the `HIDDEN-CAP:` marker.

#### Scenario: Encrypted block detected
- **WHEN** a block's single-line content starts with `HIDDEN-CAP:`
- **THEN** the block is classified as encrypted

#### Scenario: Plain block detected
- **WHEN** a block's content does not start with `HIDDEN-CAP:`
- **THEN** the block is classified as plain (eligible for encryption)
