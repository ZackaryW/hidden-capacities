## ADDED Requirements

### Requirement: Secure secret storage
The system SHALL store the Capacities API token and the encryption passphrase in `flutter_secure_storage`, editable from the Settings surface, and SHALL never persist either in plaintext on disk or in Capacities.

#### Scenario: Save token and passphrase
- **WHEN** the user enters an API token and passphrase in Settings and saves
- **THEN** both are written to secure storage and used for subsequent Capacities and crypto operations

#### Scenario: Secrets survive restart
- **WHEN** the app is relaunched after secrets were saved
- **THEN** the stored token and passphrase are loaded from secure storage without re-entry

### Requirement: Auto-decrypt preference
The system SHALL provide an auto-decrypt preference with three values — Off, Ask, On — governing what happens when a linked block is detected as a `HIDDEN-CAP:` blob.

#### Scenario: Off
- **WHEN** auto-decrypt is Off and an encrypted block is linked
- **THEN** the app does not decrypt automatically and offers a manual decrypt action

#### Scenario: Ask
- **WHEN** auto-decrypt is Ask and an encrypted block is linked
- **THEN** the app prompts the user before decrypting

#### Scenario: On
- **WHEN** auto-decrypt is On and an encrypted block is linked
- **THEN** the app decrypts immediately using the stored passphrase and shows the result (or an incorrect-password state)
