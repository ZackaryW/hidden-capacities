## ADDED Requirements

### Requirement: Decrypted view is view-only by default with an Edit action
The system SHALL render a decrypted `HIDDEN-CAP` block read-only by default and SHALL provide an Edit action that switches it into the editable Quill editor.

#### Scenario: Decrypt shows a read-only view with an Edit action
- **WHEN** a `HIDDEN-CAP` block is decrypted successfully
- **THEN** the app shows the content read-only in Quill and offers an Edit action

#### Scenario: Entering edit mode
- **WHEN** the user activates Edit on a decrypted block
- **THEN** the app loads the decrypted content into the editable Quill editor (the same editor used to encrypt a plain block)

### Requirement: Re-encrypt edited content on save
The system SHALL re-encrypt the edited Quill delta and persist it as a new `HIDDEN-CAP` code block at the original block's slot, deleting the prior block. Editing applies to any decrypted `HIDDEN-CAP` block, not only one just encrypted.

#### Scenario: Save re-encrypts in place
- **WHEN** the user saves from the editable editor
- **THEN** the app encrypts the current editor delta and appends a `HIDDEN-CAP` code block at the same slot (`position: after_block`), deletes the prior block, and surfaces the new deeplink

#### Scenario: Deeplink changes on re-encrypt
- **WHEN** a block is re-encrypted after editing
- **THEN** the resulting block has a new id, so its `capacities://` deeplink differs from the pre-edit block

#### Scenario: Leave the editor without saving
- **WHEN** the user activates Back in the editor
- **THEN** the app returns to the idle Home surface and no change is written to Capacities

### Requirement: Edit entry point after encrypting
The system SHALL offer, on the post-encrypt success screen, an action to open the just-encrypted block for editing without re-copying its deeplink.

#### Scenario: Edit right after encrypting
- **WHEN** encryption completes and the success screen is shown
- **THEN** an Edit action below "Open in Capacities" loads the just-encrypted block, decrypts it, and presents the read-only-then-editable view

#### Scenario: Missing passphrase on edit entry
- **WHEN** the user activates the post-encrypt Edit action but no passphrase is available to decrypt
- **THEN** the app surfaces the same "incorrect password"/passphrase-required state used elsewhere, rather than opening an empty editor

### Requirement: Only ciphertext is persisted
The system SHALL keep decrypted plaintext in-memory only; every write back to Capacities SHALL be re-encrypted ciphertext.

#### Scenario: Editing never persists plaintext
- **WHEN** a block is decrypted, edited, and saved
- **THEN** no plaintext is written to Capacities — only the re-encrypted `HIDDEN-CAP` code block is persisted
