## ADDED Requirements

### Requirement: Cross-platform Flutter app scaffold
The system SHALL be a single Flutter application (`hidden_capacities`) that builds for desktop (Windows) and mobile (Android), depending on the `unofficial_capacities` package via a local path dependency.

#### Scenario: App builds and launches
- **WHEN** the project is built for a supported platform
- **THEN** a single `hidden_capacities` app launches with the navigation shell visible

#### Scenario: Consumes unofficial_capacities via path dependency
- **WHEN** dependencies are resolved
- **THEN** `unofficial_capacities` is resolved from `path: ../unofficial-capacities` and its public API (`CapacitiesClient`, `CapacitiesLink`, DTOs) is importable

### Requirement: LocalSend-styled navigation shell
The system SHALL present a simple LocalSend-inspired shell with bottom navigation between a Home surface (the current linked target and its encrypt/decrypt actions) and a Settings surface.

#### Scenario: Navigate between Home and Settings
- **WHEN** the user selects a bottom-navigation destination
- **THEN** the app switches to that destination (Home or Settings) without losing app state

#### Scenario: Home with no linked target
- **WHEN** the app is on Home and no `capacities://` deeplink has been captured
- **THEN** the Home surface shows an idle/empty state prompting the user to copy a Capacities deeplink
