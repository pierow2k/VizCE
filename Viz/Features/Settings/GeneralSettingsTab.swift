import SwiftUI

struct GeneralSettingsTab: View {
    @AppStorage("appendRecognizedText") var appendRecognizedText: Bool = false
    @AppStorage("keepLineBreaks") var keepLineBreaks: Bool = true
    @AppStorage("showPreview") var showPreview: Bool = true
    @AppStorage("previewSeconds") var seconds: Double = 5.0
    @AppStorage("processing") var processingIsEnabled: Bool = false
    @AppStorage("postcommands") var postCommands: String = "say [ocr];"
    @AppStorage("mute") var mute: Bool = false
    @AppStorage("viewWidth") var viewWidth: Double = 300.0
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
