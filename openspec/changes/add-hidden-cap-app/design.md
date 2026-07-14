## Context

`hidden-capacities` is a greenfield Flutter app (empty repo, fresh git init + LICENSE). It consumes the `unofficial_capacities` pure-Dart client (sibling folder), which exposes `CapacitiesClient` (space/object/blocks/search over the Capacities REST API), `CapacitiesLink` (parse/build `capacities://` deeplinks), and typed DTOs (`ApiObject`, `Block`, token/property/block helpers). The Capacities API is Bearer-token, space-scoped, versioned via `X-Capacities-Api-Version`, and its live wire shapes (e.g. `TextBlock`/`TextToken`, property discriminated unions) were verified during that package's build.

The goal is content that is **encrypted at rest inside a normal Capacities object** yet viewable through this companion app. The unit of operation is a single **block** identified by a `capacities://<space>/<object>?bid=<block>` deeplink.

## Goals / Non-Goals

**Goals:**
- One cross-platform Flutter app (desktop + mobile), LocalSend-styled and deliberately simple.
- Round-trip a linked block between plain rich content and an AES-GCM `HIDDEN-CAP:` code block.
- Passphrase-based crypto with clear wrong-password feedback; passphrase and token in secure storage.
- Clipboard `capacities://` watching that autoparses and jumps to the target.

**Non-Goals:**
- No brand-new Capacities object creation — the app only acts on objects handed to it via a deeplink.
- No writing decrypted plaintext back into Capacities — decryption is display-only in-app.
- No general Capacities-block ↔ Quill converter beyond a single `TextBlock`; complex block trees, media, and non-text blocks are out of scope for this change.
- No key exchange transport, no server, no multi-user sharing beyond "both sides know the passphrase".
- No changes to the `unofficial_capacities` package (any gap found is raised separately).

## Decisions

- **One unified app, not two.** Writer and viewer are the same Flutter binary with a LocalSend-style bottom nav; the "companion" is this app used to decrypt on another device. Rationale: matches LocalSend being a single app, halves the surface, and the encrypt/decrypt paths share almost all state. Alternative (two apps + shared core package) considered and rejected for scope.
- **Encrypted form is a code block placed at the original's slot (append `after_block` + delete).** The encrypted content is stored as a `CodeBlock` (`HIDDEN-CAP:<blob>`). The Capacities update API cannot change a block's **type**, so producing a code block from a `TextBlock` source requires creating a new block; a plain `updateBlock` can't. Encrypt therefore: (1) `appendBlock` the `CodeBlock` with `position: {type: "after_block", after_block: {id: <original>}}` (shape confirmed live) so it lands immediately after the original rather than at the bottom of the list; (2) `deleteBlock` the original — leaving the code block in the original's slot. Decrypt reads that block, decrypts, and renders in Quill without persisting. Trade-off accepted: the block **id changes**, so the post-encrypt `?bid=` deeplink differs from the original (the app returns the new deeplink). Rationale: the owner wants the encrypted content to be a proper code block sitting where the original was; position matters more than a stable id. (`position` is a typed union `end | start | after_block`; `after_block` is the anchor we use.)
- **Payload is Quill delta JSON, from an editable editor.** On a plain block, its content is converted to a Quill delta and loaded into an **editable** `flutter_quill` editor; the plaintext that gets encrypted is the editor's **live** delta (the user may review/edit first), so formatting survives the round trip and the viewer renders it natively. Requires a `TextBlock`/`CodeBlock` → Quill delta conversion (one direction is enough: we never write delta back as Capacities blocks). Unsupported block types are rejected at load, before the editor opens.
- **Crypto: pointycastle AES-256-GCM, PBKDF2-derived key.** Key = PBKDF2-HMAC-SHA256(passphrase, random 16-byte salt, high iteration count) → 32-byte key. GCM uses a random 12-byte nonce and 128-bit tag. Blob = `HIDDEN-CAP:` + base64(`salt || nonce || ciphertext || tag`). Rationale: PBKDF2-HMAC-SHA256 is standard, pure-pointycastle, and simplest to get right; Argon2 (also in pointycastle) is a possible later upgrade. All parameters are self-contained in the blob so any device with the passphrase can decrypt.
- **Wrong password is a first-class outcome.** A GCM tag mismatch on decrypt surfaces as a distinct "incorrect password" state, separate from network/API errors (`CapacitiesApiException`) and malformed-blob errors.
- **Auto-decrypt setting (Off / Ask / On).** Mirrors LocalSend's "Quick Save" tri-state. Off = never auto-decrypt; Ask = prompt before decrypting a detected blob; On = decrypt immediately using the stored passphrase.
- **Secure storage for secrets.** API token and passphrase live in `flutter_secure_storage`, edited in Settings. Rationale: avoids plaintext-on-disk; acceptable given the threat model (content is hidden from casual Capacities viewers, not from a fully-compromised device).
- **Path dependency on `unofficial_capacities`.** Sibling folder, unpublished, so `path: ../unofficial-capacities`. Rationale: both are actively co-developed; publish-to-pub later if needed.
- **Deeplink detection of HIDDEN-CAP.** A block is "encrypted" iff it is a code block whose single line starts with the `HIDDEN-CAP:` marker. Detection scans the target block's content for that prefix.

## Risks / Trade-offs

- [~~The exact Capacities **code-block type string** and single-line wire shape were unconfirmed~~ — **RESOLVED 2026-07-14** via live wire logging] A code block is `{"id": …, "type": "CodeBlock", "lang": "Text", "text": "HIDDEN-CAP:<base64>"}`; the blob lives in `text` as a single line. The update API does not permit a type change, so encryption keeps the original block's type in place (see the in-place decision above) rather than converting to a code block.
- [Secrets in `flutter_secure_storage` are only as safe as the device] → documented in the threat model; the feature hides content from Capacities/casual viewers, not from a compromised device. Passphrase is never stored in Capacities or transmitted.
- [`TextBlock` → Quill delta may lose fidelity for token styles Quill can't represent, or vice versa] → scope limited to the common inline styles (bold/italic/strikethrough/underline) already modeled in `unofficial_capacities` tokens; anything unmapped degrades to plain text with a note.
- [**Block-level `hierarchy` is dropped** — confirmed live 2026-07-14] Headings arrive as `TextBlock`s with `"hierarchy": {"key": "H2"/"H3"/"Base", …}`; the transform routes all `TextBlock`s through token→delta and ignores `hierarchy`, so an encrypted heading loses its level (renders as a normal paragraph on decrypt). Accepted degradation for this change; mapping `hierarchy` → Quill header attribute is a possible follow-up.
- [Clipboard watching differs across platforms (desktop polling vs mobile lifecycle)] → abstract behind a small platform-agnostic watcher; poll on an interval where no change event exists.
- [A wrong-but-valid-length blob or corrupted base64 could throw obscurely] → decode is defensive: malformed blob → explicit error state, distinct from wrong-password.

## Migration Plan

Greenfield app; no migration. Rollout is simply shipping the app. The only external dependency is a user-provided Capacities token; without it the app runs but every Capacities call fails with a surfaced `CapacitiesApiException`.

## Open Questions

- None blocking. The code-block wire shape is an implementation-time verification (noted above), not a design fork. KDF may later upgrade PBKDF2 → Argon2 without changing the blob's self-describing structure.
