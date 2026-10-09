<!-- markdownlint-disable no-duplicate-heading -->
# Viz Changelog

All notable changes to Viz will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Focused macOS regression tests for shell processing, recognition snapshots,
  preview expiry, webcam lifecycle, and crop mapping.
- Development signing configuration files and a local signing override example.

### Changed

- Cache Vision language discovery by quality and request revision, preserve saved language codes, and give recognition and preview-duration pickers accessible, localizable labels.
- Load and atomically save local history off the UI actor, serialize pending snapshots, and flush pending writes before quitting. Report persistence failures with retry actions.
- Snapshot recognition settings and captured text before asynchronous work,
  isolate shared UI state on the main actor, and run Vision recognition and shell
  processing off the UI thread.
- Pass captured text to post-processing commands as data through the process
  environment. Support `[ocr]`, `"[ocr]"`, and `'[ocr]'` as whole arguments;
  document unsupported embedded placeholders, substitutions, heredocs, compound
  statements, and braced parameter expressions. Templates without placeholders
  continue to run unchanged.
- Point the About dialog's GitHub link to this fork and update its attribution
  to Pierow2k and the Viz Community.

### Fixed

- Preserve accessible switch labels, expose shortcut badges as keyboard-operable buttons, and explicitly name Settings, Updates, and Quit controls.
- Read screen selections only from operation-owned temporary files, clean up canceled captures, and report capture or recognition failures separately from recognized text even with previews disabled.
- Dismiss an open menu panel through its installed view when Webcam or History is opened with a global shortcut.
- Fixed Settings failing to open or come to the front when clicking the menu-bar
  gear or a shortcut badge, including reopening an existing Settings window.
  Settings actions now use the calling view's environment and activate Viz
  before presenting the window.
- Prevent older post-processing completions from overwriting output after a
  newer capture or Clear.
- Scope preview expiry to its window so an older timer cannot close a replacement
  preview. Cancel expiry when replacing or manually closing a preview, or clearing
  captures.
- Serialize webcam session configuration, frame access, conversion, and teardown;
  release the delegate relationship and reject stale startup or capture results.
- Bind webcam startup, stopping, closing, and resizing to the owning window;
  cancel superseded operations and restart the preview when returning with Back.
- Map webcam crop selections through the displayed aspect-fill transform to image
  pixels. Clamp selections, reject invalid crops, clear selection and drag state
  after image or viewport changes, and disable Extract until a valid crop exists.

### Removed

- N/A

[unreleased]: https://github.com/pierow2k/Viz/compare/cde5a8e24a8b0379436d551b752ecc755e93b1b9...HEAD
