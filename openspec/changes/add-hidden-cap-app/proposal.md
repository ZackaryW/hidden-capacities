## Why

Capacities has no way to store content that is encrypted at rest yet still lives inside a normal object. `hidden-capacities` fills that gap: a companion app that turns a chosen Capacities block into an AES-GCM-encrypted `HIDDEN-CAP:` code block and, on the same or another device, decrypts it back to viewable rich content. It builds directly on the `unofficial_capacities` Dart client we just shipped, giving that package its first real consumer.

## What Changes

- Scaffold a new **cross-platform Flutter app** (`hidden_capacities`, desktop + mobile) in this repo, depending on the sibling `unofficial_capacities` package via a path dependency (`path: ../unofficial-capacities`).
- Add a **LocalSend-styled UI shell**: simple bottom-nav layout, theming, a home surface for the current linked target, and a Settings screen.
- **Clipboard deeplink watching**: monitor the clipboard for `capacities://` links, autoparse them with `CapacitiesLink`, and jump to the referenced object/block.
- **HIDDEN-CAP crypto** (pointycastle): AES-GCM encrypt/decrypt under a key derived from a user passphrase (KDF), with the blob format `HIDDEN-CAP:<base64(salt+nonce+ciphertext+tag)>`; distinguish a wrong passphrase (GCM auth failure) from other errors.
- **Detect-then-offer flow**: for a linked block, detect whether it is a `HIDDEN-CAP:` blob or plain content. If plain, offer **encryption** — load the block's existing content into a **Quill** editor, serialize as Quill delta JSON, encrypt, and **update that same block in place** into the single-line `HIDDEN-CAP:` code block. If already encrypted, offer **decryption** (governed by an auto-decrypt setting) and render the decrypted rich content read-only in Quill; decryption is display-only and never writes plaintext back to Capacities.
- **Block ↔ Quill conversion** sufficient for a single text block: Capacities `TextBlock` tokens → Quill delta (to capture plaintext) and rendering decrypted delta in Quill.
- **Settings** backed by `flutter_secure_storage`: Capacities API token, passphrase, and auto-decrypt preference (Off / Ask / On).

## Capabilities

### New Capabilities
- `app-shell`: cross-platform Flutter app scaffold and LocalSend-styled navigation/theming shell.
- `clipboard-deeplink`: clipboard monitoring, `capacities://` autoparse via `CapacitiesLink`, and jump-to-target.
- `hidden-cap-crypto`: pointycastle AES-GCM encrypt/decrypt, passphrase KDF, and `HIDDEN-CAP:` blob encode/decode with wrong-password detection.
- `block-content-transform`: Capacities `TextBlock` ↔ Quill delta conversion and `HIDDEN-CAP:` detection on a block.
- `capacities-integration`: wiring the `unofficial_capacities` client — fetch the deeplinked object/block and update a block in place.
- `app-settings`: secure storage of API token, passphrase, and auto-decrypt preference, surfaced in Settings.

### Modified Capabilities
(none — this is a greenfield app with no existing specs)

## Impact

- New Flutter project files (`pubspec.yaml`, `lib/`, `test/`, platform runners) in a currently-empty repo.
- New dependencies: `unofficial_capacities` (path), `pointycastle`, `flutter_quill`, `flutter_secure_storage`, plus a clipboard/deeplink mechanism.
- Depends on the `unofficial_capacities` public API (`CapacitiesClient`, `CapacitiesLink`, `ApiObject`, `Block`, block/token helpers); no changes required to that package are anticipated, but any gap found during implementation would be raised as a separate change against it.
- Requires a user-supplied Capacities API token (`api:read` + `api:write`) to function.
