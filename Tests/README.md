# Focused macOS regression tests

This unhosted test target compiles the production helpers directly and does not launch VizCE or access its saved history/preferences.

Run from the repository root:

```sh
make test
```

The target uses Debug configuration, the current Mac architecture, and disables
signing by default. Derived data is stored under the ignored `build/tests`
directory; result bundles are in `build/tests/Logs/Test`.

For a different output directory or destination:

```sh
make test BUILD_DIR="/tmp/VizCE Tests"
make test DESTINATION="platform=macOS,arch=arm64"
```

`XCODEBUILD` can select a different executable path, and
`CODE_SIGNING_ALLOWED=YES` enables the project's signing settings.

Tests use disposable fixtures and controlled shell commands; they do not run saved user templates.
