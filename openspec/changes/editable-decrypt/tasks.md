## 0. BDD (fail-first journeys)

- [x] 0.1 Add behave journey scenarios bound to Flutter widget proofs: `@proof_edit_reencrypt` (decrypt → Edit → Save → re-encrypt) and `@proof_edit_after_encrypt` (post-encrypt Edit reopens the editor); declare both tags in `dart_test.yaml`
- [x] 0.2 Write the bound widget proofs that mount the real controller + service + widgets (gateway faked) and drive the journey through the UI, rendering the editable editor and asserting the outcome; confirm they fail RED before implementation

## 1. State model (`editable-decrypt`)

- [x] 1.1 `HomeDecrypted` carries the source target (`LoadedBlock`) alongside `deltaOps` (needed to re-encrypt)
- [x] 1.2 Add a `HomeEditingDecrypted(target, deltaOps)` state for the editable editor
- [x] 1.3 `editCurrent()`: `HomeDecrypted` → `HomeEditingDecrypted` (loads the decrypted ops into the editable editor)
- [x] 1.4 `saveEdit(editedOps)`: re-encrypt via `HiddenCapService.encrypt(target, editedOps, passphrase, spaceId)` → `HomeEncrypted(newLink)`; missing passphrase → `HomeWrongPassword`/error; `CapacitiesApiException` → `HomeError`
- [x] 1.5 `editEncrypted()`: from `HomeEncrypted`, load the block and decrypt with the stored passphrase, then go straight to `HomeEditingDecrypted` (no/again-wrong passphrase → `HomeWrongPassword`)
- [x] 1.6 Unit tests (mocked service): decrypted→edit→save yields a new deeplink; save reuses `encrypt` with the edited ops; missing-passphrase and API-error branches; `editEncrypted` decrypts to the editing state

## 2. UI (`editable-decrypt`)

- [x] 2.1 Decrypted read-only view (`_DecryptedView`) gains an **Edit** action
- [x] 2.2 Editing-decrypted view reuses the editable Quill editor with a **Save** action that calls `saveEdit(currentOps)`
- [x] 2.3 Post-encrypt success screen adds an **Edit** button below "Open in Capacities" that calls `editEncrypted()`
- [x] 2.4 `HomeController.hasOpenEditor` also returns true for `HomeEditingDecrypted` (so focus-triggered clipboard checks don't clobber an active edit)
- [x] 2.5 The editor (`_PlainEditor`, both encrypt and save modes) has a Back control that returns to the idle Home state without saving (`HomeController.backToHome`); distinct `ValueKey`s prevent Flutter reusing the editor `State` across the plain/edit surfaces

## 3. Security invariant

- [x] 3.1 Confirm (test) that decrypt→edit→save issues only re-encrypted writes — no plaintext write call — reusing the read-only `decrypt` (no persistence) and `encrypt` (ciphertext) paths

## 4. Validation

- [x] 4.1 `flutter analyze` clean; `flutter test` green (76 tests, incl. the two editor-rendering widget proofs); `uvx behave` green (4/4); `uvx behave --dry-run` exit 0 + proof-tag bijection verified (Gate C)
- [ ] 4.2 Manual end-to-end: decrypt a block → Edit → change content → Save → verify a new `HIDDEN-CAP` code block at the same slot with a new deeplink, and the old block removed; then use the post-encrypt Edit shortcut and confirm it opens the editor
- [x] 4.3 `openspec validate editable-decrypt --strict`
