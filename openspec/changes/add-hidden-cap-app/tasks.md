## 1. Project Scaffold (`app-shell`)

- [ ] 1.1 Create the Flutter app `hidden_capacities` (desktop + mobile platforms enabled) with `pubspec.yaml`
- [ ] 1.2 Add dependencies: `unofficial_capacities` (`path: ../unofficial-capacities`), `pointycastle`, `flutter_quill`, `flutter_secure_storage`, and a clipboard mechanism; `dart pub get` clean
- [ ] 1.3 Add `analysis_options.yaml` (flutter_lints) and confirm `flutter analyze` is clean on the scaffold
- [ ] 1.4 Build the LocalSend-styled shell: bottom nav (Home / Settings), theming, and an idle Home empty-state

## 2. Live Wire Verification (blocks encrypt path)

- [ ] 2.1 Against a real test workspace, confirm the Capacities **code-block** type string and the wire shape of a single-line code block (mirror how `TextBlock`/`TextToken` were discovered); record the confirmed shape in design notes before finalizing the transform

## 3. Crypto (`hidden-cap-crypto`)

- [ ] 3.1 Implement PBKDF2-HMAC-SHA256 key derivation (random 16-byte salt, fixed high iteration count) via pointycastle
- [ ] 3.2 Implement AES-256-GCM encrypt → `HIDDEN-CAP:<base64(salt||nonce||ciphertext||tag)>`
- [ ] 3.3 Implement decrypt with three distinct outcomes: success, wrong-password (GCM auth fail), malformed-blob
- [ ] 3.4 Implement `HIDDEN-CAP:` detection (marker test) on a content string
- [ ] 3.5 Unit tests: encrypt→decrypt round trip, wrong-password, malformed-blob, cross-instance decrypt (same passphrase/salt → same key), detection

## 4. Block ↔ Quill Transform (`block-content-transform`)

- [ ] 4.1 Implement `TextBlock` tokens → Quill delta (bold/italic/strikethrough/underline; unmapped → plain text)
- [ ] 4.2 Serialize Quill delta → JSON payload for encryption; deserialize decrypted delta → read-only Quill render
- [ ] 4.3 Build the single-line `HIDDEN-CAP:` code block payload for in-place update (using the type confirmed in 2.1)
- [ ] 4.4 Unit tests: token→delta fidelity for supported styles, delta JSON round trip, unmapped-style degradation

## 5. Capacities Integration (`capacities-integration`)

- [ ] 5.1 Wire a `CapacitiesClient` from the stored token; fetch the deeplinked object and locate the target block by `bid`
- [ ] 5.2 Handle "block not found" and `CapacitiesApiException` (auth/not-found/transport) as distinct error states
- [ ] 5.3 Implement in-place `updateBlock` to persist the `HIDDEN-CAP:` code block; ensure decryption never issues a write
- [ ] 5.4 Unit tests (mocked client) for fetch-and-locate, update-in-place, and error-state mapping

## 6. Clipboard Deeplink (`clipboard-deeplink`)

- [ ] 6.1 Implement a platform-agnostic clipboard watcher (event-based where available, polling otherwise)
- [ ] 6.2 Autoparse captured strings with `CapacitiesLink`; ignore non-deeplinks; surface "invalid link" for malformed `capacities://`
- [ ] 6.3 Jump-to-target: resolve space/object/block and load it on Home
- [ ] 6.4 Unit tests: capture valid deeplink, ignore non-deeplink, malformed-link handling, object-only vs object+block

## 7. Settings (`app-settings`)

- [ ] 7.1 Settings surface: API token field, passphrase field, auto-decrypt tri-state (Off / Ask / On), all backed by `flutter_secure_storage`
- [ ] 7.2 Load secrets on launch; verify they survive restart
- [ ] 7.3 Unit tests (mocked secure storage) for save/load and auto-decrypt preference persistence

## 8. Detect-then-offer Flow (ties capabilities together)

- [ ] 8.1 On target load: detect plain vs `HIDDEN-CAP:`; for plain, offer encryption (load content into Quill → encrypt → update-in-place); for encrypted, apply the auto-decrypt setting (Off/Ask/On) → decrypt → read-only Quill, or "incorrect password"
- [ ] 8.2 Wire the Home surface actions and states (idle, loaded-plain, loaded-encrypted, decrypted, error variants)

## 9. Validation

- [ ] 9.1 `flutter analyze` clean; `flutter test` (all unit tests above) green
- [ ] 9.2 Manual end-to-end against a real workspace: copy a deeplink → encrypt a block in place → re-open → decrypt to Quill; verify wrong-password and API-error paths
- [ ] 9.3 `openspec validate add-hidden-cap-app --strict`
