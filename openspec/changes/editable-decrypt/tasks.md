## 1. State model (`editable-decrypt`)

- [ ] 1.1 `HomeDecrypted` carries the source target (`LoadedBlock`) alongside `deltaOps` (needed to re-encrypt)
- [ ] 1.2 Add a `HomeEditingDecrypted(target, deltaOps)` state for the editable editor
- [ ] 1.3 `editCurrent()`: `HomeDecrypted` → `HomeEditingDecrypted` (loads the decrypted ops into the editable editor)
- [ ] 1.4 `saveEdit(editedOps)`: re-encrypt via `HiddenCapService.encrypt(target, editedOps, passphrase, spaceId)` → `HomeEncrypted(newLink)`; missing passphrase → `HomeWrongPassword`/error; `CapacitiesApiException` → `HomeError`
- [ ] 1.5 `editEncrypted()`: from `HomeEncrypted`, load the block and decrypt with the stored passphrase, then go straight to `HomeEditingDecrypted` (no/again-wrong passphrase → `HomeWrongPassword`)
- [ ] 1.6 Unit tests (mocked service): decrypted→edit→save yields a new deeplink; save reuses `encrypt` with the edited ops; missing-passphrase and API-error branches; `editEncrypted` decrypts to the editing state

## 2. UI (`editable-decrypt`)

- [ ] 2.1 Decrypted read-only view (`_DecryptedView`) gains an **Edit** action
- [ ] 2.2 Editing-decrypted view reuses the editable Quill editor with a **Save** action that calls `saveEdit(currentOps)`
- [ ] 2.3 Post-encrypt success screen adds an **Edit** button below "Open in Capacities" that calls `editEncrypted()`
- [ ] 2.4 `HomeController.hasOpenEditor` also returns true for `HomeEditingDecrypted` (so focus-triggered clipboard checks don't clobber an active edit)

## 3. Security invariant

- [ ] 3.1 Confirm (test) that decrypt→edit→save issues only re-encrypted writes — no plaintext write call — reusing the read-only `decrypt` (no persistence) and `encrypt` (ciphertext) paths

## 4. Validation

- [ ] 4.1 `flutter analyze` clean; `flutter test` (all unit tests above) green
- [ ] 4.2 Manual end-to-end: decrypt a block → Edit → change content → Save → verify a new `HIDDEN-CAP` code block at the same slot with a new deeplink, and the old block removed; then use the post-encrypt Edit shortcut and confirm it opens the editor
- [ ] 4.3 `openspec validate editable-decrypt --strict`
