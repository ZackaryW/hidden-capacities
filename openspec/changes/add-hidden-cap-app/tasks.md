## 1. Project Scaffold (`app-shell`)

- [x] 1.1 Create the Flutter app `hidden_capacities` (desktop + mobile platforms enabled) with `pubspec.yaml`
- [x] 1.2 Add dependencies: `unofficial_capacities` (`path: ../unofficial-capacities`), `pointycastle`, `flutter_quill`, `flutter_secure_storage`, and a clipboard mechanism; `dart pub get` clean
- [x] 1.3 Add `analysis_options.yaml` (flutter_lints) and confirm `flutter analyze` is clean on the scaffold
- [x] 1.4 Build the LocalSend-styled shell: bottom nav (Home / Settings), theming, and an idle Home empty-state

## 2. Live Wire Verification (blocks encrypt path)

- [x] 2.1 Against a real test workspace, confirm the Capacities **code-block** type string and the wire shape of a single-line code block (mirror how `TextBlock`/`TextToken` were discovered); record the confirmed shape in design notes before finalizing the transform
  - Done (2026-07-14): built `lib/src/integration/wire_log.dart` — a debug-only (`kDebugMode`) Dio interceptor (injected via the client's `dio:` seam, no `unofficial_capacities` change) that prints each response's raw wire JSON. Ran live: confirmed a code block is `{"type": "CodeBlock", "lang": "Text", "text": "HIDDEN-CAP:<base64>"}` (single line in `text`) — matches the implementation. Also confirmed the update API forbids a type change (drives append+delete, see 5.3) and that headings arrive as `TextBlock`s with `hierarchy` that the transform drops. All recorded in design.md.

## 3. Crypto (`hidden-cap-crypto`)

- [x] 3.1 Implement PBKDF2-HMAC-SHA256 key derivation (random 16-byte salt, fixed high iteration count) via pointycastle
- [x] 3.2 Implement AES-256-GCM encrypt → `HIDDEN-CAP:<base64(salt||nonce||ciphertext||tag)>`
- [x] 3.3 Implement decrypt with three distinct outcomes: success, wrong-password (GCM auth fail), malformed-blob
- [x] 3.4 Implement `HIDDEN-CAP:` detection (marker test) on a content string
- [x] 3.5 Unit tests: encrypt→decrypt round trip, wrong-password, malformed-blob, cross-instance decrypt (same passphrase/salt → same key), detection

## 4. Block ↔ Quill Transform (`block-content-transform`)

- [x] 4.1 Implement `TextBlock` tokens → Quill delta (bold/italic/strikethrough/underline; unmapped → plain text)
- [x] 4.2 Serialize Quill delta → JSON payload for encryption; deserialize decrypted delta → read-only Quill render
- [x] 4.3 Build the single-line `HIDDEN-CAP:` code block payload for in-place update (using the type confirmed in 2.1)
  - Reconcile (2026-07-14): payload builder done and tested, but the "in-place update" premise is superseded — see 5.3 divergence. The 2.1 type confirmation is still outstanding.
- [x] 4.4 Unit tests: token→delta fidelity for supported styles, delta JSON round trip, unmapped-style degradation

## 5. Capacities Integration (`capacities-integration`)

- [x] 5.1 Wire a `CapacitiesClient` from the stored token; fetch the deeplinked object and locate the target block by `bid`
- [x] 5.2 Handle "block not found" and `CapacitiesApiException` (auth/not-found/transport) as distinct error states
- [x] 5.3 Implement in-place `updateBlock` to persist the `HIDDEN-CAP:` code block; ensure decryption never issues a write
  - Reconcile (2026-07-14): **DIVERGENCE.** The Capacities update API forbids changing a block's type, so encryption is implemented as **append a new `CodeBlock` + delete the original** (`encryptBlock`), not an in-place `updateBlock`. Consequence: the block id and `?bid=` deeplink **change** — contradicting design.md's stated rationale that identity/deeplink stay stable. Decryption never writes (holds). **design.md needs correcting.**
- [x] 5.4 Unit tests (mocked client) for fetch-and-locate, update-in-place, and error-state mapping

## 6. Clipboard Deeplink (`clipboard-deeplink`)

- [x] 6.1 Implement a platform-agnostic clipboard watcher (event-based where available, polling otherwise)
  - Reconcile (2026-07-14): implemented as interval polling on all platforms (no event path).
- [x] 6.2 Autoparse captured strings with `CapacitiesLink`; ignore non-deeplinks; surface "invalid link" for malformed `capacities://`
- [x] 6.3 Jump-to-target: resolve space/object/block and load it on Home
- [x] 6.4 Unit tests: capture valid deeplink, ignore non-deeplink, malformed-link handling, object-only vs object+block

## 7. Settings (`app-settings`)

- [x] 7.1 Settings surface: API token field, passphrase field, auto-decrypt tri-state (Off / Ask / On), all backed by `flutter_secure_storage`
- [x] 7.2 Load secrets on launch; verify they survive restart
- [x] 7.3 Unit tests (mocked secure storage) for save/load and auto-decrypt preference persistence

## 8. Detect-then-offer Flow (ties capabilities together)

- [x] 8.1 On target load: detect plain vs `HIDDEN-CAP:`; for plain, offer encryption (load content into Quill → encrypt → update-in-place); for encrypted, apply the auto-decrypt setting (Off/Ask/On) → decrypt → read-only Quill, or "incorrect password"
  - Reconcile (2026-07-14): detect + auto-decrypt (Off/Ask/On) + read-only Quill view + wrong-password state done and tested. **Gap:** the encrypt path does NOT load content into an *editable* Quill editor first — it transforms the block directly and encrypts. The editable pre-encryption editor is carved out to 8.3.
- [x] 8.2 Wire the Home surface actions and states (idle, loaded-plain, loaded-encrypted, decrypted, error variants)
- [ ] 8.3 Editable Quill editor on the encrypt path: load the plain block's content into an editable `flutter_quill` editor so the user can review/edit before encrypting, then serialize the edited delta → encrypt (proposal.md called for this; currently missing)

## 9. Validation

- [x] 9.1 `flutter analyze` clean; `flutter test` (all unit tests above) green
- [ ] 9.2 Manual end-to-end against a real workspace: copy a deeplink → encrypt a block in place → re-open → decrypt to Quill; verify wrong-password and API-error paths
- [x] 9.3 `openspec validate add-hidden-cap-app --strict`

## Reconciliation summary (2026-07-14)

Reconciled `tasks.md` against the actually-built `lib/` + `test/` (55 tests green, `flutter analyze` clean, `openspec validate --strict` valid). Status:

- **2.1** ✅ done — code-block wire shape confirmed live and recorded in design.md; `wire_log.dart` interceptor added.
- **5.3 / 4.3 divergence** ✅ resolved in design.md — encryption is append-new-`CodeBlock` + delete-original (the update API forbids a type change); the `?bid=` deeplink changes, accepted.
- **New finding** (design.md): block-level `hierarchy` (headings) is dropped by the transform — accepted degradation, possible follow-up.

Still outstanding before this change is truly done:

- **8.3** editable Quill editor on the encrypt path — proposal called for it; not built.
- **9.2** manual end-to-end against a real workspace (needs a live token).
