<!-- markdownlint-disable no-duplicate-heading -->
# VizCE Changelog

All notable changes to VizCE will be documented in this file.

The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [UNRELEASED]

### Changed

- Centralize temporary-directory creation and XCTest cleanup registration for
  history persistence failure tests.
- Share the overlapping webcam startup setup between stale-success and
  stale-failure tests while preserving their separate assertions.
- Split recognition orchestration from asynchronous language resolution and
  recognition work to keep capture scheduling concise without changing delivery.
- Align SwiftLint attribute placement, multiline collection commas, and the
  100-column limit with Google's Swift style guidance; wrap application and
  test source while preserving existing behavior and indentation.

### Fixed

- Replace "capture" with "history" in the window dimensions dialog.

## [3.0.1] - 2026-10-14

### Added

- Regression tests for updater version comparisons, cached redirects,
  request failures, retry recovery, and overlapping release checks.
- A GitHub Actions workflow for CodeQL analysis of Swift code.

### Changed

- Simplify shell word scanning and consumption with documented escape,
  expansion-validation, quote-state, placeholder-rendering, and
  command-position helpers while preserving template behavior.
- Simplify webcam startup with focused duplicate-request, device-resolution,
  and generation-validation helpers while preserving cancellation and
  stale-session cleanup.
- Simplify icon-button styling with named hover and press feedback while
  preserving appearance, accessible labels, and Reduce Motion behavior.
- Use a patched local copy of the pinned AlinFoundation dependency and run
  its updater regression tests with `make test`.
- Refresh README badges, menu and history screenshots, and demo video
  links; organize fork details in a collapsible section.

### Fixed

- Bypass cached GitHub responses during release checks so obsolete
  redirects do not hide available updates. Show request failures in the
  Updates tab and clear them after a successful retry.
- Detect updates from GitHub release tags with a leading `v` or `V` and
  keep the update dialog available after manual refresh, including when
  no newer release exists.
- Recognize LF and CRLF shell-template boundaries explicitly, preserving
  line endings and quoted text while rejecting missing redirection targets
  before comments and line endings.

### Removed

- Remove the unused GitHub Actions workflow for automatically closing
  empty issues and incomplete issue templates.

## [3.0.0] - 2026-10-12

### Added

- Improved comments throughout the codebase.
- Focused macOS regression tests for shell processing, recognition
  snapshots, preview expiry, webcam lifecycle, and crop mapping.
- Development signing configuration files and a local signing override
  example.

### Changed

- Rename the application, source resources, Xcode projects, test target,
  and maintained repository to VizCE. Use fresh bundle identities and
  history storage without migrating existing data, and expose
  post-processing text through `VIZCE_OCR_TEXT`.
- Organize source by capture, recognition, history, preview, settings, and
  menu features; split composition, recognition/acquisition, and utility
  responsibilities into named files.
- Use a payload-free capture sound helper and remove dummy history-item
  construction for sound playback.
- Name the shared unavailable-language predicate while keeping the
  explanatory message conditional on loading completion.
- Share the unchanged close-button header between text and color previews.
- Name the coordinated capture/history/clipboard reset explicitly and give
  it a dedicated orchestration file.
- Extract queue-confined webcam session configuration and PNG frame
  encoding, with deferred configuration commit before startup or teardown.
- Extract shell word scanning, name accepted placeholder forms, and make
  parser cursor advancement explicit.
- Separate screen-capture temporary files, launch orchestration, result
  classification, and shared cleanup while preserving queue confinement.
- Consolidate menu action tiles into a shared view and keep action ordering
  in named parent methods.
- Share the image-recognition and success-only preview entry point across
  screen and webcam extraction.
- Pass preview-duration and post-processing command bindings from the
  settings tab into their toggle styles.
- Put reusable button/toggle/text-field styles and shapes in a Styles
  group; give shortcut/info controls, the text-view extension, and window
  accessor focused files without changing behavior.
- Organize recognized content, recognition quality, history entries, and
  text/color models into individual files while preserving actor isolation,
  identity, and history encoding.
- Separate camera preview, captured-image selection, text/color previews,
  and preview presentation into focused files while preserving capture and
  crop behavior.
- Use typed Settings tab identities with unchanged saved values, modern
  tabs on macOS 15 and later, and a shared-content macOS 14 fallback.
- Project history filters and newest-first ordering once per parent view
  evaluation; keep copy feedback in the installed list so copying does not
  repeat filtering.
- Use modern SwiftUI foreground, overlay, background, and clipping APIs
  without changing styling; discover external cameras using the macOS 14
  device type.
- Cache Vision language discovery by quality and request revision, preserve
  saved language codes, and give recognition and preview-duration pickers
  accessible, localizable labels.
- Load and atomically save local history off the UI actor, serialize
  pending snapshots, and flush pending writes before quitting. Report
  persistence failures with retry actions.
- Snapshot recognition settings and captured text before asynchronous work,
  isolate shared UI state on the main actor, and run Vision recognition and
  shell processing off the UI thread.
- Pass captured text to post-processing commands as data through the
  process environment. Support `[ocr]`, `"[ocr]"`, and `'[ocr]'` as whole
  arguments; document unsupported embedded placeholders, substitutions,
  heredocs, compound statements, and braced parameter expressions.
  Templates without placeholders continue to run unchanged.
- Point the About dialog's GitHub link to this fork and update its
  attribution to Pierow2k and the VizCE Community.

### Fixed

- Use one Debug signing configuration under Config, align local override
  keys, and document local builds; honor overrides at the documented
  location.
- Measure the webcam image viewport after reserved controls and title-bar
  space, avoiding duplicate safe-area subtraction and extra image gaps;
  enforce the minimum size in the hosted content so capture controls cannot
  collapse below it.
- Resolve history defaults inside main-actor entry points to avoid
  concurrency warnings in signed development builds.
- Honor Reduce Motion for webcam window resizing and custom-button
  scale/rotation feedback while retaining immediate pressed and hover
  feedback.
- Adapt webcam capture/extraction controls to narrow windows, reserve
  safe-area space for controls and camera selection, and map crops using
  the remaining visible image viewport.
- Show explicit camera authorization, startup, capture, and failure states
  with Retry and refreshed camera choices, preserving disconnected saved
  selections until the user chooses a replacement.
- Keep every Settings tab scrollable at short heights, adapt
  recognition/dimension rows, and size release notes from the tab viewport
  with an explicit minimum window size.
- Reflect the actual launch-at-login service status after requests, report
  failures, explain approval requirements, and refresh external changes
  without unnecessary registration.
- Expose separate keyboard-accessible history copy, link, delete, and clear
  actions; keep Delete available during Copied feedback and use stable
  filter identifiers with localizable labels.
- Preserve semantic Close/Clear button labels in custom styles and give
  processing output a flexible width instead of an infinite fixed width.
- Preserve accessible switch labels, expose shortcut badges as
  keyboard-operable buttons, and explicitly name Settings, Updates, and
  Quit controls.
- Read screen selections only from operation-owned temporary files, clean
  up canceled captures, and report capture or recognition failures
  separately from recognized text even with previews disabled.
- Dismiss an open menu panel through its installed view when Webcam or
  History is opened with a global shortcut.
- Fixed Settings failing to open or come to the front when clicking the
  menu-bar gear or a shortcut badge, including reopening an existing
  Settings window. Settings actions now use the calling view's environment
  and activate VizCE before presenting the window.
- Prevent older post-processing completions from overwriting output after a
  newer capture or Clear.
- Scope preview expiry to its window so an older timer cannot close a
  replacement preview. Cancel expiry when replacing or manually closing a
  preview, or clearing captures.
- Serialize webcam session configuration, frame access, conversion, and
  teardown; reuse the Core Image context across captures, release the
  delegate relationship and reject stale startup or capture results.
- Bind webcam startup, stopping, closing, and resizing to the owning
  window; cancel superseded operations and restart the preview when
  returning with Back.
- Map webcam crop selections through the displayed aspect-fill transform to
  image pixels. Clamp selections, reject invalid crops, clear selection and
  drag state after image or viewport changes, and disable Extract until a
  valid crop exists.

### Removed

- Remove unused upstream iCloud container metadata while keeping iCloud
  disabled.
- Keep one canonical app icon package and the root release announcements
  file; remove duplicate resources and the title-only nested README.
- Remove unused capture views, styles, legacy utility helpers, preview
  globals, and menu dependencies.
- Remove the unused legacy relaunch helper; remaining subprocess launches
  use throwing APIs.
- Remove the unused image-snipping view and its dormant, incorrect crop
  conversion.

[unreleased]: https://github.com/pierow2k/VizCE/compare/v3.0.1...HEAD
[3.0.1]: https://github.com/pierow2k/VizCE/releases/tag/v3.0.1
[3.0.0]: https://github.com/pierow2k/VizCE/releases/tag/v3.0.0
