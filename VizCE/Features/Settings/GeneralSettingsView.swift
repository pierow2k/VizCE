import AlinFoundation
import SwiftUI

/// Capture preferences, recognition choices, and preview sizing controls.
struct GeneralSettingsView: View {
    @Binding var appendRecognizedText: Bool
    @Binding var keepLineBreaks: Bool
    @Binding var showPreview: Bool
    /// The automatic preview dismissal delay in seconds.
    @Binding var seconds: Double
    @Binding var processingIsEnabled: Bool
    /// The post-processing shell template; `[ocr]` must occupy a whole argument.
    @Binding var postCommands: String
    @Binding var mute: Bool
    /// The capture preview width in points.
    @Binding var viewWidth: Double
    /// The base capture preview height in points, before the extra processing-output space.
    @Binding var viewHeight: Double
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .center) {
                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        AdaptiveSettingsRow("OCR Language") {
                            LanguagePickerView().frame(width: 200)
                        }
                        AdaptiveSettingsRow("OCR Quality") {
                            QualityPickerView().frame(width: 200)
                        }

                        Toggle("Append consecutive captures", isOn: $appendRecognizedText)
                            .toggleStyle(SpacedToggle())
                            .help(
                                "When enabled, consecutive captures will be added on to the previous capture"
                            )

                        Toggle("Keep line breaks in captures", isOn: $keepLineBreaks)
                            .toggleStyle(SpacedToggle())
                            .help("New lines will be kept from scanned text")

                        Toggle("Show capture window for", isOn: $showPreview)
                            .toggleStyle(SpacedToggleSeconds(seconds: $seconds))
                            .help(
                                """
                                When enabled, captured content preview will show and close \
                                after \(Int(seconds)) seconds. Otherwise it's not shown at all.
                                """
                            )

                        Toggle("Post-processing", isOn: $processingIsEnabled)
                            .toggleStyle(SpacedProcessingToggle(postCommands: $postCommands))
                            .help("When enabled, you can execute shell functions after capture")

                        Toggle("Mute capture sound", isOn: $mute)
                            .toggleStyle(SpacedToggle())
                            .help("Mute the screen capture notification sound")

                        LaunchAtLoginView(controller: appState.launchAtLogin)

                        AdaptiveSettingsRow("Capture Window Dimensions") {
                            HStack {
                                HStack {
                                    Text("W:")
                                    Stepper(
                                        "\(Int(viewWidth))",
                                        value: $viewWidth,
                                        in: 200...1_000,
                                        step: 10
                                    )
                                    .frame(width: 60, alignment: .trailing)
                                    Text("H:")
                                    Stepper(
                                        "\(Int(viewHeight))",
                                        value: $viewHeight,
                                        in: 100...1_000,
                                        step: 10
                                    )
                                    .frame(width: 60, alignment: .trailing)
                                }

                                Button {
                                    viewWidth = 300.0
                                    viewHeight = 200.0
                                } label: {
                                    Image(systemName: "arrow.counterclockwise")
                                        .accessibilityLabel("Reset capture window dimensions")
                                        .font(.system(size: 12))
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(.secondary)
                                .help("Reset dimensions to default")

                                Button {
                                    PreviewWindowController.shared.show(PreviewContentView())
                                } label: {
                                    Image(systemName: "macwindow")
                                        .accessibilityLabel("Show example capture preview")
                                        .font(.system(size: 12))
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(.secondary)
                                .help("Show example window")
                            }
                        }
                    }
                    .padding()
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
