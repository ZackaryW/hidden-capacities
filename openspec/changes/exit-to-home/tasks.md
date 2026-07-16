## 1. Behavior Proofs

- [x] 1.1 Add fail-first Flutter BDD scenarios and bound widget proofs for Exit returning from Settings/content to idle Home, keeping the app mounted and clipboard-ready, and doing nothing when already idle on Home
- [x] 1.2 Run the BDD dry-run and binding-integrity checks required by the configured `dart-flutter` governance stack

## 2. Shell Behavior

- [x] 2.1 Replace the platform termination callback with a synchronous shell transition that selects the Home destination and calls the existing no-save `HomeController.backToHome()` transition when available
- [x] 2.2 Remove now-unused application-termination imports and desktop detection used only by Exit while retaining desktop focus-listener behavior

## 3. Verification

- [x] 3.1 Complete fail-first widget/controller TDD for non-idle reset, mounted listener behavior, unsaved-content discard, and the idle-Home no-op
- [x] 3.2 Run formatting, `flutter analyze`, the governed test reconciliation/coverage gate, the full Flutter test suite, and the full Behave suite
