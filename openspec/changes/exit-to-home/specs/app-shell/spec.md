## MODIFIED Requirements

### Requirement: Exit action
The system SHALL provide an **Exit** control in the shell that returns to the idle Home surface without terminating or dismissing the application, without saving the current content, and while keeping clipboard-focus detection available for new links.

#### Scenario: Exit from another destination or content state
- **WHEN** the user activates the Exit control while another destination or non-idle content state is displayed
- **THEN** the system selects Home and resets its content to the idle Home surface without saving

#### Scenario: Application remains available for new clipboard links
- **WHEN** the user activates the Exit control
- **THEN** the application remains running and its existing clipboard-focus detection can process a newly copied Capacities link

#### Scenario: Exit while already idle on Home
- **WHEN** the user activates the Exit control while the idle Home surface is already displayed
- **THEN** the visible state and persisted data remain unchanged
