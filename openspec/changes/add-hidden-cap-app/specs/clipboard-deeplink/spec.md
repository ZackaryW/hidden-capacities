## ADDED Requirements

### Requirement: On-demand clipboard checking on focus
The system SHALL check the clipboard on demand — when the app window gains focus and on an explicit user action — rather than polling on a timer, and SHALL NOT perform a focus-triggered check while an editor or content view is open.

#### Scenario: Window regains focus while idle
- **WHEN** the app window gains focus and no editor or content view is open
- **THEN** the app checks the clipboard once and, if it holds a new `capacities://` deeplink, loads that target

#### Scenario: Focus while an editor is open is not disrupted
- **WHEN** the app window gains focus while the plain-block editor or the decrypted view is open
- **THEN** the app does not check the clipboard and does not change the current target

#### Scenario: Unchanged clipboard on repeated focus
- **WHEN** the app window gains focus and the clipboard is unchanged since the last check
- **THEN** the app does not reload or change the current target

### Requirement: Clipboard deeplink watching
The system SHALL monitor the clipboard for `capacities://` deeplinks and, when one appears, capture it as the current target without requiring manual paste.

#### Scenario: Capacities deeplink copied
- **WHEN** the clipboard contains a string that parses as a valid `capacities://` deeplink
- **THEN** the app captures it as the current target and reflects it on the Home surface

#### Scenario: Non-deeplink clipboard content ignored
- **WHEN** the clipboard contains content that is not a valid `capacities://` deeplink
- **THEN** the app does not change the current target and does not surface an error

### Requirement: Deeplink autoparse and jump-to-target
The system SHALL parse a captured deeplink with `CapacitiesLink` into its space, object, and optional block ids, and jump to (load) that target.

#### Scenario: Object-and-block deeplink
- **WHEN** a captured deeplink includes a `bid` block id
- **THEN** the app resolves `spaceId`, `objectId`, and `blockId` and loads that specific block as the target

#### Scenario: Object-only deeplink
- **WHEN** a captured deeplink has no `bid`
- **THEN** the app resolves `spaceId` and `objectId` and loads the object, leaving block selection to the detect step

#### Scenario: Malformed deeplink
- **WHEN** a captured string starts with `capacities://` but is missing a space or object id
- **THEN** the app surfaces an "invalid link" state rather than crashing or loading a partial target
