# Focused macOS regression tests

This unhosted test target compiles the production helpers directly and does not launch VizCE or access its saved history/preferences.

```sh
xcodebuild -project Tests/VizCETests.xcodeproj -scheme VizCETests -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO test
```

Use a temporary `-derivedDataPath` when running locally. Tests use disposable fixtures and controlled shell commands; they do not run saved user templates.
