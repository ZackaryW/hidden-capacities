# Hidden Capacities

[![Desktop builds](https://github.com/ZackaryW/hidden-capacities/actions/workflows/desktop-build.yml/badge.svg)](https://github.com/ZackaryW/hidden-capacities/actions/workflows/desktop-build.yml)

Hidden Capacities is a Flutter companion app for encrypting and decrypting Capacities blocks. It reads `capacities://` block links from the clipboard, stores encrypted content as `HIDDEN-CAP` blobs, and opens the resulting block back in Capacities.

## What it does

- Detects newly copied Capacities links when the app starts or regains focus.
- Lets you review and edit a supported plain-text block before encrypting it.
- Encrypts locally with AES-GCM using a passphrase stored in platform secure storage.
- Decrypts `HIDDEN-CAP` blocks for reading or editing, then re-encrypts changes in place.
- Keeps running when **Exit** is selected: Exit returns to the idle Home screen so the app can continue detecting new clipboard links.
- Stores the Capacities API token in platform secure storage.

> [!IMPORTANT]
> Keep your passphrase backed up independently. Content encrypted with a lost passphrase cannot be recovered. This project is not affiliated with Capacities.

## Supported builds

The repository contains desktop runners for Windows, macOS, and Linux. GitHub Actions creates a release bundle for each platform on pushes to `main`, pull requests, and manual runs.

Build artifacts are unsigned development builds. Windows and macOS may display operating-system security warnings until release signing is configured.

## Use

1. Open **Settings** and enter your Capacities API token and encryption passphrase.
2. Copy a link to a specific Capacities block. The link must include its block identifier (`bid`).
3. Return focus to Hidden Capacities, or select **Check clipboard**.
4. Encrypt a plain supported block, or decrypt an existing `HIDDEN-CAP` block.
5. Use **Open in Capacities** after a successful write.

The app intentionally checks the clipboard on launch, window focus, and explicit request instead of continuously polling in the background. Clipboard checks are suppressed while an editor or content view is open so active work is not replaced.

## Build locally

The app currently uses [`unofficial_capacities`](https://github.com/ZackaryW/unofficial-capacities) as a sibling path dependency. Clone both repositories into the same parent directory:

```text
workplace/
├── hidden-capacities/
└── unofficial-capacities/
```

Install the [Flutter desktop prerequisites](https://docs.flutter.dev/platform-integration/desktop) for your operating system, then run:

```sh
cd hidden-capacities
flutter pub get
flutter run -d windows  # or macos / linux
```

Create release builds with the matching host operating system:

```sh
flutter build windows --release
flutter build macos --release
flutter build linux --release
```

Flutter requires Windows builds to run on Windows, macOS builds on macOS, and Linux builds on Linux.

## Development

Run the static checks and Flutter test suite:

```sh
flutter analyze
flutter test
```

The behavior-level suite uses [Behave](https://behave.readthedocs.io/) through `uvx` and executes its bound Flutter widget proofs:

```sh
uvx behave
```

## Continuous integration

The [desktop build workflow](.github/workflows/desktop-build.yml):

- checks out this repository and `unofficial-capacities` as siblings;
- installs Flutter 3.44.6 and required Linux native packages;
- builds release applications on `windows-latest`, `macos-latest`, and `ubuntu-latest`;
- packages each native bundle without losing executable metadata; and
- uploads uniquely named artifacts for 14 days.
