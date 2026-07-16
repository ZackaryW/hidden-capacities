## Context

`HomeShell` currently binds the app-bar **Exit** button to `_exit()`, which calls `windowManager.close()` on desktop and `SystemNavigator.pop()` elsewhere. The same shell owns the selected bottom-navigation index and clipboard-focus observer, while `HomeController.backToHome()` already resets content to `HomeIdle` without saving.

## Goals / Non-Goals

**Goals:**

- Reuse the existing Home reset transition and shell navigation state.
- Keep the shell mounted so its clipboard-focus observer remains active.
- Make the action deterministic from Home, Settings, editors, and content states.

**Non-Goals:**

- Add a replacement application-quit control.
- Add background clipboard polling or change existing focus-triggered clipboard semantics.
- Save or discard through a new confirmation flow.
- Rename or relocate the **Exit** control.

## Decisions

- **Handle Exit as one synchronous shell transition.** Set the selected destination to Home and call `HomeController.backToHome()` when a controller exists. This uses the state transition already proven to return content to `HomeIdle` without saving. Alternative: rebuild the controller; rejected because it performs unnecessary settings/service work and could lose unrelated controller configuration.
- **Leave the shell and listener mounted.** Remove termination calls from this action rather than closing and relaunching/minimizing. This directly preserves the existing lifecycle/window-focus listeners. Alternative: hide or minimize the window; rejected because that does not satisfy returning visibly to Home and complicates cross-platform behavior.
- **Treat idle Home as an idempotent no-op.** Reapplying the Home index and idle state has no visible or persisted effect. No special abstraction is needed.
- **Cover behavior at shell and controller boundaries.** A widget test proves the app stays mounted and navigates to idle Home; existing controller tests establish that `backToHome()` does not invoke persistence. Add focused coverage where a missing assertion remains.

## Risks / Trade-offs

- [The label and power icon conventionally imply application termination] → Preserve them because the owner explicitly requires the control to remain named **Exit**; encode the actual behavior in tests and specification.
- [Resetting an editor discards unsaved in-memory edits] → This is intentional and must remain a no-save transition; test it explicitly.
- [A clipboard value already consumed by `ClipboardWatcher` will not be re-emitted merely by pressing Exit] → Keep current changed-value semantics; the requirement concerns continued detection of new links.
