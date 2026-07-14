## ADDED Requirements

### Requirement: Fetch the deeplinked target
The system SHALL use the `unofficial_capacities` `CapacitiesClient` to fetch the object referenced by the current deeplink and locate the target block within it.

#### Scenario: Fetch object and locate block
- **WHEN** a deeplink with a `bid` is the current target
- **THEN** the app calls `getObject` for the object and locates the block whose id matches `bid`

#### Scenario: Target block not found
- **WHEN** the object is fetched but no block matches the deeplink's `bid`
- **THEN** the app surfaces a "block not found" state rather than proceeding to encrypt/decrypt

### Requirement: Update a block in place
The system SHALL use the client's `updateBlock` to write the `HIDDEN-CAP:` blob back to the same object and block id, preserving the block's position and type (the update API does not permit a type change).

#### Scenario: Encrypted content persisted in place
- **WHEN** encryption produces a `HIDDEN-CAP:` blob for the target
- **THEN** the app calls `updateBlock` with the target object id and the original block id, writing a same-type block whose single-line content is the blob (a `TextBlock` stays a `TextBlock`, a `CodeBlock` stays a `CodeBlock`)

#### Scenario: Position and deeplink preserved
- **WHEN** a block is encrypted in place
- **THEN** the block keeps its position in the object and its id, so the `capacities://` deeplink to it is unchanged

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
