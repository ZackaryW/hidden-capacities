## ADDED Requirements

### Requirement: TextBlock to Quill delta
The system SHALL convert a Capacities `TextBlock` (its `TextToken` list with inline styles) into a Quill delta document, preserving the common inline styles (bold, italic, strikethrough, underline).

#### Scenario: Styled tokens converted
- **WHEN** a `TextBlock` with styled tokens is converted
- **THEN** the resulting Quill delta contains the same text runs with the corresponding inline attributes

#### Scenario: Unmapped style degrades to plain text
- **WHEN** a token carries a style Quill cannot represent
- **THEN** the run is emitted as plain text rather than failing the conversion

### Requirement: Quill delta as encrypt payload
The system SHALL serialize the Quill delta document to JSON as the plaintext payload handed to encryption, and SHALL render a decrypted delta back into a read-only Quill view.

#### Scenario: Round trip through delta JSON
- **WHEN** a block's content is captured as Quill delta, serialized to JSON, encrypted, then later decrypted and deserialized
- **THEN** the rendered Quill content matches the originally captured rich content for supported styles

### Requirement: In-place block transform to HIDDEN-CAP
The system SHALL, on encryption, replace the target block's content with the single-line `HIDDEN-CAP:` code block form, keeping the same block identity (updated in place, not deleted and recreated).

#### Scenario: Encrypt updates the same block
- **WHEN** encryption completes for a target block
- **THEN** that block is updated in place to a single-line code block containing the `HIDDEN-CAP:` blob, and its block id is unchanged
