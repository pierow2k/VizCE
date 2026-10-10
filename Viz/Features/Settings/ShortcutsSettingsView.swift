import AlinFoundation
import KeyboardShortcuts
import SwiftUI

struct ShortcutsSettingsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .center) {
                GroupBox {
                    VStack(spacing: 10) {
                        HStack {
                            Text("Capture Content")
                            Spacer()
                            KeyboardShortcuts.Recorder(for: .captureContent)
                        }
                        HStack {
                            Text("Capture Webcam")
                            Spacer()
                            KeyboardShortcuts.Recorder(for: .captureWebcam)
                        }
                        HStack {
                            Text("Color Picker")
                            Spacer()
                            KeyboardShortcuts.Recorder(for: .eyedropper)
                        }
                        HStack {
                            Text("History Window")
                            Spacer()
                            KeyboardShortcuts.Recorder(for: .history)
                        }
                        HStack {
                            Text("Clear Clipboard")
                            Spacer()
                            KeyboardShortcuts.Recorder(for: .clear)
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
