## Why

Encryption is currently a one-way interaction: the decrypted view is read-only, so to change a `HIDDEN-CAP` block's content the user must decrypt it, edit the source elsewhere, and re-encrypt by hand. Users want to edit a decrypted block in place — and, right after encrypting, keep editing without re-copying the deeplink.

## What Changes

- **Decrypted view becomes view-only-by-default with an Edit action.** Decrypting a `HIDDEN-CAP` block shows the existing read-only Quill view plus an **Edit** button that switches it into the editable Quill editor (the same editor used before a first encryption).
- **Re-encrypt on save.** Saving from the editable editor re-encrypts the edited Quill delta, appending a new `HIDDEN-CAP` `CodeBlock` at the same slot (`position: after_block`) and deleting the old one — so the block's `?bid=` deeplink changes on each edit, exactly like a first-time encryption.
- **Edit shortcut on the post-encrypt success screen.** Below "Open in Capacities", add a button that loads the just-encrypted block and decrypts it into the read-only-then-editable view, so the user can edit immediately without re-copying the deeplink.
- **Security wording updated.** Plaintext still exists only in-memory in the editor and only ciphertext is ever written to Capacities; the "decryption is display-only" stance becomes "view-only by default; edits are persisted only re-encrypted."

## Capabilities

### New Capabilities
- `editable-decrypt`: view-only-by-default decrypted view with an Edit action, re-encrypt-on-save (new code block at the same slot, deeplink changes), and the post-encrypt Edit entry point.

### Modified Capabilities
(none at the main-spec level — `openspec/specs/` is still empty because `add-hidden-cap-app` is not yet archived. This change builds on that one; its `capacities-integration` "Decryption is read-only" requirement is superseded by `editable-decrypt` and reconciled when both changes sync.)

## Impact

- **Depends on `add-hidden-cap-app`** (implement that first): reuses its editable Quill editor, `HiddenCapService.encrypt`/`decrypt`/`editableOps`, and the `encryptBlock` (append-`after_block` + delete) flow.
- UI: new decrypted/editing states and transitions in `HomeController` and `HomePage`; a new action on the post-encrypt success screen.
- No new dependencies; no change to the crypto, the `HIDDEN-CAP:` blob format, or the wire shapes.
