## Context

This change extends `add-hidden-cap-app` (still unarchived). That app already has: an editable Quill editor for encrypting a plain block, `HiddenCapService.encrypt(target, deltaOps, passphrase, spaceId)`, `decrypt(target, passphrase) -> deltaOps`, `editableOps(block)`, and `CapacitiesGateway.encryptBlock` which appends a `HIDDEN-CAP` `CodeBlock` at the original's slot (`position: {type: "after_block", after_block: {id}}`) and deletes the original. Decryption today renders **read-only** and is documented as "display-only". This change makes decrypted content editable and re-encryptable, reusing those existing pieces.

## Goals / Non-Goals

**Goals:**
- Any decrypted `HIDDEN-CAP` block can be edited and re-encrypted, not only one just created.
- Decrypted content is view-only by default; an explicit **Edit** action opens the editable editor.
- An **Edit** entry point on the post-encrypt success screen opens the just-encrypted block for editing without re-copying the deeplink.
- Preserve the security invariant: plaintext is in-memory only; only ciphertext is written back.

**Non-Goals:**
- No change to the crypto, the `HIDDEN-CAP:` blob format, KDF, or the `after_block` write mechanism.
- No stable block id across edits (re-encrypt intentionally produces a new block — see Decisions).
- No offline queue / conflict handling beyond surfacing `CapacitiesApiException` as today.

## Decisions

- **Read-only-by-default decrypted view + Edit toggle.** The decrypted state carries both the delta ops and the source target, and renders the existing read-only `QuillEditor` plus an **Edit** button. Edit transitions to an editing state that reuses the existing editable editor widget. Rationale: prevents accidental edits, keeps a safe view mode (owner's choice), and reuses both existing Quill widgets.
- **Re-encrypt on save reuses the encrypt path.** Saving serializes the live editor delta and calls the existing `HiddenCapService.encrypt` against the current block target — appending a new `HIDDEN-CAP` code block at the same slot and deleting the prior one. Rationale: one write path for first-encrypt and re-encrypt; no new gateway code.
- **New block/deeplink per edit (accepted).** Because re-encrypt goes through append-`after_block` + delete, the block id and `?bid=` deeplink change on every save. Accepted by the owner; consistent with first-time encryption and keeps a single write mechanism.
- **Post-encrypt Edit opens editable directly.** On the success screen, an **Edit** action (below "Open in Capacities") loads the just-encrypted block, decrypts it with the stored passphrase, and opens the editable editor directly (the button's intent is to edit). Passive decryption from a clipboard link stays read-only-first. Rationale: matches "open the editor right on" while keeping accidental-edit protection for the passive path.
- **State model.** Extend `HomeController`: the decrypted state gains the source target; add an editing-decrypted state; add `editCurrent()` (decrypted → editing), `saveEdit(ops)` (editing → re-encrypt → encrypted-success), and an `editEncrypted()` entry from the success state. Missing passphrase reuses the existing `HomeWrongPassword`/error handling.

## Risks / Trade-offs

- [Deeplink churn on every edit] → accepted; the app always surfaces the new deeplink, and edits are expected to be occasional. A stable-id strategy is out of scope (the update API cannot change block type).
- [Editing then re-encrypting briefly holds plaintext in the editor] → same exposure as the existing read-only decrypted view; never persisted unencrypted. Documented in the security wording update.
- [Repeated edit→save cycles accumulate deleted blocks] → each save deletes the prior block, so no accumulation of live blocks; deleted-block history is Capacities' concern.

## Migration Plan

Additive UI/state change on top of `add-hidden-cap-app`; no data migration. The "decryption is display-only" wording in `add-hidden-cap-app` is superseded by "view-only by default; edits persisted only re-encrypted" and reconciled when both changes sync.

## Open Questions

- None blocking. Button labels ("Edit", "Save"/"Encrypt") are UI-copy details settled during implementation.
