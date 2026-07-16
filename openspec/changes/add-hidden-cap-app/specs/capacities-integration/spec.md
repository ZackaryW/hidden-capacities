## ADDED Requirements

### Requirement: Fetch the deeplinked target
The system SHALL use the `unofficial_capacities` `CapacitiesClient` to fetch the object referenced by the current deeplink and locate the target block within it.

#### Scenario: Fetch object and locate block
- **WHEN** a deeplink with a `bid` is the current target
- **THEN** the app calls `getObject` for the object and locates the block whose id matches `bid`

#### Scenario: Target block not found
- **WHEN** the object is fetched but no block matches the deeplink's `bid`
- **THEN** the app surfaces a "block not found" state rather than proceeding to encrypt/decrypt

### Requirement: Persist the encrypted block as a code block at the original's position
The system SHALL store the encrypted content as a `CodeBlock` (`HIDDEN-CAP:<blob>`) inserted at the original block's position, since the update API cannot change a block's type.

#### Scenario: Encrypted content persisted in the original's slot
- **WHEN** encryption produces a `HIDDEN-CAP:` blob for the target
- **THEN** the app calls `appendBlock` with a `CodeBlock` carrying the blob and `position` `after_block` anchored to the original block id, then `deleteBlock` on the original — so the code block occupies the original's slot rather than the bottom of the list

#### Scenario: Deeplink updates to the new block
- **WHEN** a block is encrypted
- **THEN** the app returns the `capacities://` deeplink to the newly created code block (its `bid` differs from the original's)

### Requirement: Decryption is read-only
The system SHALL NOT write decrypted plaintext back to Capacities; decryption results are shown only in the app.

#### Scenario: Decrypt does not persist plaintext
- **WHEN** a `HIDDEN-CAP:` block is decrypted successfully
- **THEN** the decrypted content is rendered in the app and no Capacities write call is made for that decryption

### Requirement: API errors surface distinctly
The system SHALL surface `CapacitiesApiException` from the client (auth, not-found, transport) as an error state distinct from crypto outcomes (wrong password, malformed blob).

#### Scenario: Missing or invalid token
- **WHEN** a Capacities call fails because no token is configured or the token is rejected
- **THEN** the app surfaces an API/auth error prompting the user to check the token in Settings, not a crypto error
