## Why

The shell's upper-right **Exit** action currently closes or dismisses the application, which stops the app from receiving newly copied Capacities links. It should instead leave the app running and return the user to a clipboard-ready Home surface.

## What Changes

- Change the upper-right **Exit** action from application termination to in-app navigation.
- When activated from any shell destination or content state, select Home and reset its content to the idle state without saving.
- Keep the application and clipboard-focus listener running so later Capacities links can still be detected.
- Make the action a no-op when the app is already idle on Home.
- Remove the shell's explicit application-termination behavior from this control.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `app-shell`: Redefine the existing Exit action as a return-to-idle-Home action that keeps the application running and clipboard-ready.

## Impact

- Affects the Home shell action and Home controller state transition in `lib/src/ui/app.dart` and `lib/src/ui/home_controller.dart`.
- Requires widget/controller coverage for navigation, state reset, no-save behavior, and the already-idle no-op.
- Removes the Exit action's dependency on desktop/mobile termination calls; no new dependencies or external API changes.
