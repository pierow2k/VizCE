## Align SwiftLint configuration with Google's Swift style guide

Completed on 2026-10-14 using SwiftLint 0.63.2.

The fresh starting inventory contained 227 findings across 66 Swift files:
27 attribute-placement warnings, 10 trailing-comma warnings, and 190
line-length errors. All findings in `VizCE` and `Tests` are resolved.

### Changes

- Preserve the existing configuration edits and explicitly require parameterized
  attributes on the line above their declarations.
- Require trailing commas in multiline array and dictionary literals.
- Enforce 100 columns while allowing URL and import exceptions. Ordinary
  comments, declarations, and strings remain checked.
- Wrap source and documentation without changing public APIs, persistence,
  localization, shell fixture values, or existing indentation.
- Keep generated build output and vendored code outside the `make lint` inputs.

This is targeted alignment with Google's
[attributes](https://google.github.io/swift/#attributes),
[trailing commas](https://google.github.io/swift/#trailing-commas), and
[column limit](https://google.github.io/swift/#column-limit) guidance.
Other style policies are unchanged. SwiftLint does not enforce lexicographic
attribute ordering; touched declarations were reviewed manually.

### Validation

- `make lint`: zero violations across 117 Swift files.
- `swiftlint lint --config .swiftlint.yml --force-exclude --no-cache --strict VizCE Tests`: zero warnings, errors, or configuration diagnostics.
- `make test`: 13 updater dependency tests and 79 application tests passed.
- `make debug`: Debug app built successfully.
- Configuration fixtures verified the 100/101-column boundary, import and URL
  exceptions, parameterized attributes, and multiline trailing commas.
- Swift compiler parse comparison confirmed identical string literal values and
  interpolation metadata in all 66 touched files. Parsed structure matched in
  63 files; the remaining differences were reviewed and limited to naming
  closure parameters and listing enum cases separately.
- Existing comment wording is unchanged, including documentation tags.
- Settings help and post-processing text were inspected in the installed app
  and matched the preserved values. Native UI automation could not select the
  separately running Debug instance, so its visual layout was not verified.
- `git diff --check`: clean.

The build emits existing warnings in the unchanged `Vendor/AlinFoundation`
dependency and an App Intents metadata extraction warning. These are compiler
warnings outside this SwiftLint cleanup.

### Commits

1. `style(lint): align attributes and trailing commas with Google guidance`
2. `style(app): wrap Swift source and documentation to 100 columns`
3. `style(tests): wrap fixtures and complete lint cleanup`

### Original warning inventory

The entries below are retained as historical context. Their line numbers and
coverage predate the fresh inventory and do not describe remaining work.

### Attributes Violations

- Refer to [attributes.md](https://realm.github.io/SwiftLint/attributes.html) for rule details

VizCE/VizCEApp.swift:14:53: Attributes Violation
VizCE/Features/Settings/GeneralSettingsTab.swift:5:41: Attributes Violation
VizCE/Features/Settings/GeneralSettingsTab.swift:6:35: Attributes Violation
VizCE/Features/Settings/GeneralSettingsTab.swift:7:32: Attributes Violation
VizCE/Features/Settings/GeneralSettingsTab.swift:9:35: Attributes Violation
VizCE/Features/Settings/GeneralSettingsTab.swift:10:31: Attributes Violation
VizCE/Features/Settings/GeneralSettingsTab.swift:12:33: Attributes Violation
VizCE/Features/Settings/GeneralSettingsTab.swift:13:25: Attributes Violation
VizCE/Features/Settings/GeneralSettingsTab.swift:15:30: Attributes Violation
VizCE/Features/Settings/GeneralSettingsTab.swift:17:31: Attributes Violation
VizCE/Features/Capture/CaptureSound.swift:7:25: Attributes Violation
VizCE/Features/Capture/Webcam/WebcamCaptureView.swift:18:45: Attributes Violation
VizCE/Features/Menu/ContentView.swift:16:37: Attributes Violation
VizCE/Features/Menu/ContentView.swift:17:42: Attributes Violation
VizCE/Features/Menu/ShortcutEditorView.swift:8:37: Attributes Violation
VizCE/Features/Menu/ShortcutEditorView.swift:9:42: Attributes Violation
VizCE/Features/Preview/PreviewWindowController.swift:23:39: Attributes Violation
VizCE/Features/Preview/PreviewWindowController.swift:24:35: Attributes Violation
VizCE/Features/Preview/PreviewWindowController.swift:25:36: Attributes Violation
VizCE/Features/Preview/PreviewWindowController.swift:26:34: Attributes Violation
VizCE/Features/Preview/PreviewWindowController.swift:27:35: Attributes Violation
VizCE/Shared/AppState.swift:43:49: Attributes Violation
VizCE/Shared/AppState.swift:44:44: Attributes Violation
VizCE/Shared/Styles/RoundedRectangleButtonStyle.swift:6:55: Attributes Violation
VizCE/Shared/Styles/SimpleButtonStyle.swift:5:55: Attributes Violation

### Trailing Comma Violations

- refer to [trailing_comma.md](https://realm.github.io/SwiftLint/trailing_comma.html) for rule details

VizCE/Features/Recognition/PostProcessing/ShellTemplate.swift:135:72: Trailing Comma Violation
VizCE/Features/Recognition/PostProcessing/ShellTemplate.swift:222:74: Trailing Comma Violation
Tests/CaptureOutcomeTests.swift:29:51: Trailing Comma Violation
Tests/PostProcessingTests.swift:36:77: Trailing Comma Violation
Tests/PostProcessingTests.swift:51:61: Trailing Comma Violation
Tests/PostProcessingTests.swift:138:63: Trailing Comma Violation
Tests/PostProcessingTests.swift:147:76: Trailing Comma Violation
Tests/PostProcessingTests.swift:157:65: Trailing Comma Violation
Tests/PostProcessingTests.swift:179:75: Trailing Comma Violation
Tests/ImageCropTests.swift:91:68: Trailing Comma Violation

### Line lengths Greater Than 100 Characters

- refer to [line_length.md](https://realm.github.io/SwiftLint/line_length.html) for rule details

VizCE/Features/Settings/SettingsView.swift:22:1: 117 characters
VizCE/Features/Settings/LaunchAtLogin/LaunchAtLoginController.swift:20:1: 115 characters
VizCE/Features/Settings/LaunchAtLogin/LaunchAtLoginController.swift:41:1: 104 characters
VizCE/Features/Settings/LaunchAtLogin/LaunchAtLoginController.swift:52:1: 105 characters
VizCE/Features/Settings/LaunchAtLogin/LaunchAtLoginController.swift:57:1: 110 characters
VizCE/Features/Settings/UpdaterSettingsView.swift:35:1: 109 characters
VizCE/Features/Settings/UpdaterSettingsView.swift:62:1: 116 characters
VizCE/Features/Settings/LaunchAtLogin/LaunchAtLoginView.swift:4:1: 106 characters
VizCE/Features/Settings/LaunchAtLogin/LaunchAtLoginView.swift:17:1: 112 characters
VizCE/Features/Settings/LaunchAtLogin/LaunchAtLoginView.swift:21:1: 111 characters
VizCE/Features/Capture/CaptureFailure.swift:21:1: 101 characters
VizCE/Features/Capture/Color/ColorCapture.swift:27:1: 107 characters
VizCE/Features/Capture/CaptureNoticePresenter.swift:29:1: 101 characters
VizCE/Features/Settings/LanguagePickerView.swift:21:1: 116 characters
VizCE/Features/Settings/LanguagePickerView.swift:36:1: 113 characters
VizCE/Features/Settings/GeneralSettingsView.swift:36:1: 109 characters
VizCE/Features/Capture/Webcam/WebcamCaptureWorker.swift:6:1: 108 characters
VizCE/Features/Capture/Webcam/WebcamCaptureWorker.swift:20:1: 108 characters
VizCE/Features/Capture/Screen/ScreenCaptureWorker.swift:15:1: 115 characters
VizCE/Features/Capture/Screen/ScreenCaptureWorker.swift:26:1: 102 characters
VizCE/Features/Capture/Screen/ScreenCaptureWorker.swift:44:1: 103 characters
VizCE/Features/Capture/Screen/ScreenCaptureWorker.swift:84:1: 119 characters
VizCE/Features/Capture/Screen/ScreenCaptureWorker.swift:100:1: 105 characters
VizCE/Features/Capture/Screen/ScreenCaptureWorker.swift:104:1: 113 characters
VizCE/Features/Capture/Webcam/WebcamCaptureWorker.swift:133:1: 104 characters
VizCE/Features/Capture/Webcam/WebcamCaptureWorker.swift:137:1: 110 characters
VizCE/Features/Capture/Webcam/WebcamCaptureError.swift:5:1: 110 characters
VizCE/Features/Capture/Webcam/WebcamCaptureError.swift:22:1: 101 characters
VizCE/Features/Capture/Webcam/WebcamCaptureBackend.swift:15:1: 108 characters
VizCE/Features/Capture/Webcam/WebcamCaptureCoordinator.swift:5:1: 102 characters
VizCE/Features/Capture/Webcam/WebcamCaptureCoordinator.swift:15:1: 110 characters
VizCE/Features/Capture/Webcam/WebcamCaptureCoordinator.swift:24:1: 105 characters
VizCE/Features/Capture/Webcam/WebcamCaptureCoordinator.swift:45:1: 102 characters
VizCE/Features/Capture/Webcam/WebcamCaptureCoordinator.swift:50:1: 115 characters
VizCE/Features/Capture/Webcam/WebcamCaptureCoordinator.swift:88:1: 104 characters
VizCE/Features/Capture/Webcam/WebcamCaptureCoordinator.swift:96:1: 107 characters
VizCE/Features/Capture/Webcam/WebcamCaptureCoordinator.swift:121:1: 110 characters
VizCE/Features/Capture/Webcam/WebcamCaptureCoordinator.swift:156:1: 107 characters
VizCE/Features/Capture/Webcam/WebcamCaptureCoordinator.swift:169:1: 111 characters
VizCE/Features/Capture/Webcam/WebcamCaptureView.swift:22:1: 103 characters
VizCE/Features/Capture/Webcam/WebcamCaptureView.swift:112:1: 105 characters
VizCE/Features/Capture/Webcam/WebcamCaptureView.swift:124:1: 105 characters
VizCE/Features/Capture/Webcam/WebcamCaptureView.swift:136:1: 101 characters
VizCE/Features/Capture/Webcam/WebcamWindowController.swift:20:1: 112 characters
VizCE/Features/Capture/Webcam/WebcamWindowController.swift:34:1: 102 characters
VizCE/Features/Capture/Webcam/WebcamWindowController.swift:41:1: 102 characters
VizCE/Features/Capture/Webcam/WebcamWindowController.swift:51:1: 105 characters
VizCE/Features/Capture/Webcam/ImageSelectionState.swift:7:1: 101 characters
VizCE/Features/Capture/Webcam/ImageCropTransform.swift:8:1: 113 characters
VizCE/Features/Capture/Webcam/ImageCropTransform.swift:11:1: 116 characters
VizCE/Features/Capture/Webcam/ImageCropTransform.swift:14:1: 110 characters
VizCE/Features/Capture/Webcam/ImageCropTransform.swift:30:1: 107 characters
VizCE/Features/Capture/CaptureReset.swift:1:1: 102 characters
VizCE/Features/Capture/Webcam/WebcamPreviewSource.swift:8:1: 104 characters
VizCE/Features/Capture/Webcam/WebcamPreviewSource.swift:11:1: 107 characters
VizCE/Features/Capture/Webcam/SystemWebcamDeviceCatalog.swift:14:1: 101 characters
VizCE/Features/Capture/Webcam/SystemWebcamDeviceCatalog.swift:15:1: 102 characters
VizCE/Features/Menu/KeyboardShortcuts.Name.swift:5:1: 109 characters
VizCE/Features/Menu/KeyboardShortcuts.Name.swift:10:1: 107 characters
VizCE/Features/Menu/KeyboardShortcuts.Name.swift:15:1: 103 characters
VizCE/Features/Menu/ContentView.swift:124:1: 102 characters
VizCE/Features/Menu/ContentView.swift:129:1: 115 characters
VizCE/Features/History/HistoryState.swift:15:1: 110 characters
VizCE/Features/History/HistoryState.swift:17:1: 101 characters
VizCE/Features/History/HistoryRow.swift:77:1: 103 characters
VizCE/Features/History/StoredHistoryEntry.swift:3:1: 102 characters
VizCE/Features/History/HistoryFileStore.swift:23:1: 119 characters
VizCE/Features/Preview/PreviewWindowController.swift:18:1: 104 characters
VizCE/Features/History/CopyFeedbackController.swift:15:1: 107 characters
VizCE/Features/History/HistoryFilter.swift:5:1: 119 characters
VizCE/Features/Recognition/TextRecognition.swift:12:1: 106 characters
VizCE/Features/Recognition/TextRecognition.swift:46:1: 102 characters
VizCE/Features/Recognition/TextRecognition.swift:64:1: 104 characters
VizCE/Features/Recognition/TextRecognition.swift:78:1: 120 characters
VizCE/Features/Recognition/TextRecognition.swift:92:1: 116 characters
VizCE/Features/Recognition/TextRecognition.swift:95:1: 108 characters
VizCE/Features/Recognition/TextRecognition.swift:102:1: 108 characters
VizCE/Features/Recognition/RecognitionWorker.swift:30:1: 112 characters
VizCE/Features/Recognition/RecognitionWorker.swift:43:1: 101 characters
VizCE/Features/Recognition/RecognitionWorker.swift:54:1: 103 characters
VizCE/Features/Recognition/RecognitionWorker.swift:56:1: 102 characters
VizCE/Features/Recognition/RecognitionWorker.swift:57:1: 116 characters
VizCE/Features/Recognition/RecognitionWorker.swift:60:1: 102 characters
VizCE/Features/Recognition/PostProcessing/ShellTemplate.swift:10:1: 112 characters
VizCE/Features/Recognition/PostProcessing/ShellTemplate.swift:11:1: 110 characters
VizCE/Features/Recognition/PostProcessing/ShellTemplate.swift:13:1: 101 characters
VizCE/Features/Recognition/PostProcessing/ShellTemplate.swift:25:1: 110 characters
VizCE/Features/Recognition/PostProcessing/ShellTemplate.swift:27:1: 115 characters
VizCE/Features/Recognition/PostProcessing/ShellTemplate.swift:101:1: 109 characters
VizCE/Features/Recognition/PostProcessing/ShellTemplate.swift:104:1: 112 characters
VizCE/Features/Recognition/PostProcessing/ShellTemplate.swift:117:1: 112 characters
VizCE/Features/Recognition/PostProcessing/ShellTemplate.swift:126:1: 114 characters
VizCE/Features/Recognition/PostProcessing/ShellTemplate.swift:134:1: 110 characters
VizCE/Features/Recognition/PostProcessing/ShellTemplate.swift:140:1: 108 characters
VizCE/Features/Recognition/PostProcessing/ShellTemplate.swift:148:1: 102 characters
VizCE/Features/Recognition/PostProcessing/ShellTemplate.swift:196:1: 103 characters
VizCE/Features/Recognition/PostProcessing/ShellTemplate.swift:203:1: 101 characters
VizCE/Features/Recognition/PostProcessing/PostProcessingRunner.swift:8:1: 102 characters
VizCE/Features/Recognition/PostProcessing/PostProcessingRunner.swift:16:1: 103 characters
VizCE/Features/Recognition/PostProcessing/PostProcessingRunner.swift:38:1: 101 characters
VizCE/Features/Recognition/PostProcessing/PostProcessingRunner.swift:42:1: 115 characters
VizCE/Features/Recognition/PostProcessing/PostProcessingRunner.swift:47:1: 112 characters
VizCE/Features/Recognition/RecognitionLanguageCatalog.swift:4:1: 101 characters
VizCE/Features/Recognition/RecognitionLanguageCatalog.swift:11:1: 103 characters
VizCE/Features/Recognition/RecognitionLanguageCatalog.swift:25:1: 106 characters
VizCE/Features/Recognition/RecognitionLanguageCatalog.swift:42:1: 103 characters
VizCE/Features/Recognition/RecognitionLanguageCatalog.swift:44:1: 114 characters
VizCE/Features/Recognition/RecognitionLanguageCatalog.swift:49:1: 103 characters
VizCE/Features/Recognition/RecognitionLanguageCatalog.swift:52:1: 120 characters
VizCE/Shared/Controls/MovableWindowAccessor.swift:5:1: 101 characters
VizCE/Shared/Models/ColorItem.swift:10:1: 112 characters
VizCE/Shared/Styles/RoundedRectangleButtonStyle.swift:21:1: 111 characters
VizCE/Shared/Styles/RoundedRectangleButtonStyle.swift:28:1: 104 characters
VizCE/Shared/Styles/SimpleButtonStyle.swift:17:1: 110 characters
Tests/SettingsTabTests.swift:20:1: 111 characters
Tests/SettingsTabTests.swift:32:1: 106 characters
Tests/SettingsTabTests.swift:36:1: 111 characters
Tests/LaunchAtLoginTests.swift:6:1: 110 characters
Tests/HistoryActionTests.swift:34:1: 104 characters
VizCE/Shared/Styles/SpacedProcessingToggle.swift:27:1: 113 characters
VizCE/Shared/Styles/SpacedProcessingToggle.swift:28:1: 101 characters
Tests/WebcamTests.swift:59:1: 101 characters
Tests/WebcamTests.swift:108:1: 107 characters
Tests/WebcamTests.swift:128:1: 107 characters
Tests/WebcamTests.swift:148:1: 107 characters
Tests/WebcamTests.swift:167:1: 101 characters
Tests/WebcamTests.swift:274:1: 101 characters
VizCE/AppDelegate.swift:12:1: 104 characters
VizCE/AppDelegate.swift:47:1: 101 characters
VizCE/AppDelegate.swift:64:1: 119 characters
Tests/PostProcessingTests.swift:69:1: 105 characters
Tests/PostProcessingTests.swift:71:1: 102 characters
Tests/PostProcessingTests.swift:75:1: 105 characters
Tests/PostProcessingTests.swift:102:1: 111 characters
Tests/PostProcessingTests.swift:114:1: 103 characters
Tests/PostProcessingTests.swift:122:1: 112 characters
Tests/PostProcessingTests.swift:154:1: 103 characters
Tests/PostProcessingTests.swift:161:1: 116 characters
Tests/PostProcessingTests.swift:176:1: 118 characters
Tests/PostProcessingTests.swift:177:1: 108 characters
Tests/PostProcessingTests.swift:178:1: 107 characters
Tests/PostProcessingTests.swift:197:1: 112 characters
Tests/PostProcessingTests.swift:205:1: 109 characters
Tests/PostProcessingTests.swift:207:1: 111 characters
Tests/PostProcessingTests.swift:214:1: 111 characters
Tests/ImageCropTests.swift:95:1: 116 characters
