# Building VizCE

Pre-compiled versions are available from the
[releases](https://github.com/pierow2k/VizCE/releases) page.

## Prerequisites

- macOS 14.0 or later.
- A full Xcode installation with the macOS SDK. The builds below are verified
  with Xcode 27.0.
- SwiftLint if you want to run `make lint`.

Ensure `xcode-select -p` points to your Xcode installation's
`Contents/Developer` directory. Xcode resolves the AlinFoundation and
KeyboardShortcuts dependencies through Swift Package Manager; you need network
access when those packages are not already cached.

## Build from the command line

From the repository root, run:

```sh
make debug
make release
```

### Application version and build number

The Makefile defines the default version and build number near the top:

```makefile
APP_VERSION ?= 1.2.0
BUILD_NUMBER ?= 1
```

Edit these values in the Makefile to change the defaults, or override them for
an individual build without opening Xcode:

```sh
make debug APP_VERSION=1.2.0 BUILD_NUMBER=42
make release APP_VERSION=1.2.0 BUILD_NUMBER=42
```

Both build targets pass `APP_VERSION` to Xcode as `MARKETING_VERSION` and
`BUILD_NUMBER` as `CURRENT_PROJECT_VERSION`. These supply the app's
`CFBundleShortVersionString` (display version) and `CFBundleVersion` (build
number), respectively, when the Xcode project uses those build settings for its
Info.plist. The built app is signed as part of the build, so no post-build
Info.plist editing is necessary.

After a Release build, inspect the version, build number, and bundle identifier
in `dist/Release/VizCE.app` with:

```sh
make inspect
```

`inspect` reads the existing Release app; it does not rebuild it. Run
`make release` first if the app is not already present.

Plain `make` and `make build` both run the Debug target. Debug builds target
the current Mac's architecture for faster local iteration. Release builds are
universal and contain both `arm64` and `x86_64` code, so an Apple silicon Mac
can produce a single app that runs natively on both Apple silicon and Intel
Macs. An Intel build host is not required.

Both targets use their matching shared Xcode scheme and configuration and copy
the signed app into `dist`:

| Target | Xcode scheme | Architecture | Build product | App copy |
| --- | --- | --- | --- | --- |
| `debug` / `build` | `VizCE Debug` | Current Mac (`$(uname -m)`) | `build/debug/Build/Products/Debug/VizCE.app` | `dist/Debug/VizCE.app` |
| `release` | `VizCE Release` | Universal (`arm64`, `x86_64`) | `build/release/Build/Products/Release/VizCE.app` | `dist/Release/VizCE.app` |

The Release target uses a generic macOS destination with `ARCHS="arm64 x86_64"`
and `ONLY_ACTIVE_ARCH=NO`. Verify the resulting executable with:

```sh
lipo -archs dist/Release/VizCE.app/Contents/MacOS/VizCE
```

The output should list both architectures, for example:

```text
arm64 x86_64
```

The copy step replaces the previous app for that configuration. It preserves
the signature using `ditto`. `make release` builds and copies the universal app;
it does not create an archive, notarize the app, or publish a release.

### Package a Release build

Use `make package` to build the universal Release app and create a versioned ZIP
and SHA-256 checksum in `dist`:

```sh
make package APP_VERSION=1.2.0 BUILD_NUMBER=42
```

For these values, the output files are:

```text
dist/Release/VizCE.app
dist/VizCE-1.2.0-macOS-universal.zip
dist/VizCE-1.2.0-macOS-universal.zip.sha256
```

The ZIP contains `VizCE.app` (without a version in the app bundle name). Its
filename uses `APP_VERSION`, not `BUILD_NUMBER`; the build number is stored in
the app's Info.plist. The package target runs `release` first, then creates a
temporary ZIP and moves it into place after successful creation. It generates
the checksum alongside the ZIP. Earlier ZIPs with different version numbers
remain in `dist` until removed explicitly or by `make clean`; packaging the
same version again replaces that version's ZIP and checksum.

To check the checksum from the repository root:

```sh
cd dist && shasum -a 256 -c VizCE-1.2.0-macOS-universal.zip.sha256
```

Packaging does not notarize the app, submit it to Apple, or publish a release.

The default `build` and `dist` directories are ignored by Git. Override
`BUILD_DIR` for derived data and `DIST_DIR` for the app copies:

```sh
make debug BUILD_DIR="/tmp/VizCE Build" DIST_DIR="/tmp/VizCE Dist"
```

You can also override `XCODEBUILD` with an executable path. Debug and Release
use separate Xcode destinations: Debug defaults to the current Mac's
architecture, while Release uses the generic macOS destination so Xcode can
build both supported architectures.

Use `make clean` to remove both `BUILD_DIR` and `DIST_DIR`, including test
products. If you override these directories when building, supply the same
overrides when cleaning.

## Build in Xcode

Open `VizCE.xcodeproj` and choose **VizCE Debug** for development or
**VizCE Release** for a Release build. Both schemes build the `VizCE` app target.
Xcode manages its own derived-data location; the copies under `dist` are created
only by the Makefile.

For a distribution-style Release build, prefer `make release`: the Makefile
explicitly requests both `arm64` and `x86_64` slices and verifies a consistent
output location under `dist/Release`.

## Code signing

Debug and Release builds use manual ad-hoc signing (`CODE_SIGN_IDENTITY = -`)
with no development team by default. You do not need an Apple signing
certificate for these builds. Signing is enabled in the Makefile.

Debug uses `Config/DebugSigning.xcconfig` and
`VizCE/VizCEDebug.entitlements`. Release defines its signing settings directly
in the Xcode project and uses `VizCE/VizCE.entitlements`. Both entitlements files
are currently empty, and both configurations enable the hardened runtime.
Ad-hoc signing does not provide a Developer ID signature or notarization.

### Optional Apple Development signing

An Apple Development identity can help preserve macOS Privacy & Security
permissions, such as Screen Recording, across rebuilds. To configure one, copy
the example file and replace `YOUR_TEAM_ID` with your development team ID:

```sh
cp Config/LocalSigning.xcconfig.example Config/LocalSigning.xcconfig
```

You also need a matching Apple Development signing identity and its private key
in your keychain. The local file is ignored by Git.

`DebugSigning.xcconfig` includes this file, but the current project and app target
also explicitly set manual signing, an ad-hoc identity, and an empty team.
Those settings take precedence over the included file. To apply your local
settings without editing the project, pass the file explicitly to `xcodebuild`:

```sh
xcodebuild -project VizCE.xcodeproj -scheme "VizCE Debug" \
  -configuration Debug -destination "platform=macOS,arch=$(uname -m)" \
  -derivedDataPath build/debug \
  -xcconfig Config/LocalSigning.xcconfig build
```

This produces `build/debug/Build/Products/Debug/VizCE.app` without copying it
to `dist`. For development signing in Xcode, select the app target's Debug
configuration, enable automatic signing, and choose your team and Apple
Development identity in **Signing & Capabilities** / **Build Settings**.
The local Debug configuration file does not configure Release signing.

## Tests and lint

```sh
make test
make lint
```

`make test` uses the separate `Tests/VizCETests.xcodeproj` project and
`VizCETests` scheme with Debug configuration and the current Mac architecture.
The test target uses an ad-hoc signing identity; the Makefile no longer disables
signing. Test products and results are under `build/tests`, with result bundles
in `build/tests/Logs/Test`. These unhosted tests compile selected production
helpers directly and do not launch VizCE or access its saved history/preferences.
See [Tests/README.md](Tests/README.md) for test coverage details.

`make lint` requires SwiftLint to be installed. It uses `.swiftlint.yml` to check
application and test sources under `VizCE` and `Tests`, excluding generated build
files and dependencies. Errors fail the target; warnings are reported. Override
the executable path when needed:

```sh
make lint SWIFTLINT="/path/to/swiftlint"
```

## Source layout

- `VizCE/Features/Capture`: screen, webcam, and color acquisition, notices, and reset/sound actions.
- `VizCE/Features/Recognition`: text/barcode recognition, language discovery, and post-processing.
- `VizCE/Features/History`: history models, persistence, filtering, and UI.
- `VizCE/Features/Preview`: preview content, window presentation, and expiry.
- `VizCE/Features/Settings`: settings tabs and launch-at-login integration.
- `VizCE/Features/Menu`: menu composition, shortcut controls, and menu dismissal.
- `VizCE/Shared`: shared state, models, clipboard/bundle helpers, controls, and styles.

`VizCEApp.swift` and `AppDelegate.swift` compose the application. The isolated
project under `Tests` compiles selected production helpers directly; update
both Xcode projects when moving those files.

## Repository resources

`VizCE/VizCE.icon` is the canonical icon package used by the app target.
`VizCE/Icon` retains the separate source artwork and export images.

The updater fetches `announcements.json` from the repository root through the
GitHub contents API. Keep release announcements there; the app does not bundle
this file. [README.md](README.md) is the project documentation entry point.
