## ADDED Requirements

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
