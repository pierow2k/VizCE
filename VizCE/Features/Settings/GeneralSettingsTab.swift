import SwiftUI

/// Persisted capture preferences passed as bindings to the general settings controls.
struct GeneralSettingsTab: View {
    @AppStorage("appendRecognizedText") var appendRecognizedText: Bool = false
    @AppStorage("keepLineBreaks") var keepLineBreaks: Bool = true
    @AppStorage("showPreview") var showPreview: Bool = true
    /// The automatic preview dismissal delay in seconds.
    @AppStorage("previewSeconds") var seconds: Double = 5.0
    @AppStorage("processing") var processingIsEnabled: Bool = false
    /// The post-processing shell template; `[ocr]` must occupy a whole argument.
    @AppStorage("postcommands") var postCommands: String = "say [ocr];"
    @AppStorage("mute") var mute: Bool = false
    /// The capture preview width in points.
    @AppStorage("viewWidth") var viewWidth: Double = 300.0
    /// The base capture preview height in points, before the extra processing-output space.
    @AppStorage("viewHeight") var viewHeight: Double = 200.0

    var body: some View {
        GeneralSettingsView(
            appendRecognizedText: $appendRecognizedText,
            keepLineBreaks: $keepLineBreaks,
            showPreview: $showPreview,
            seconds: $seconds,
            processingIsEnabled: $processingIsEnabled,
            postCommands: $postCommands,
            mute: $mute,
            viewWidth: $viewWidth,
            viewHeight: $viewHeight
        )
    }
}
