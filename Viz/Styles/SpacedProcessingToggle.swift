import SwiftUI

struct SpacedProcessingToggle: ToggleStyle {
    @AppStorage("postcommands") var postCommands: String = "say [ocr];"
    @State private var showPopover = false

    func makeBody(configuration: Configuration) -> some View {
        HStack() {

            configuration.label

            Button("Edit") {
                showPopover.toggle()
            }
            .buttonStyle(.borderedProminent)
            .popover(isPresented: $showPopover) {
                VStack(alignment: .leading, spacing: 10) {
                    TextEditor(text: $postCommands)
                        .monospaced()
                        .frame(width: 350, height: 100)
                        .scrollContentBackground(.hidden)
                    Divider()
                    Text("Execute any shell commands after capture is completed. Use [ocr], \"[ocr]\", or '[ocr]' as a whole argument. Embedded placeholders, substitutions, and heredocs are unsupported.\nExample: say [ocr]; echo [ocr] > capture.txt")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .textSelection(.disabled)
                }
                .background { Color("bg").padding(-80) }
                .padding()
            }

            Spacer()

            Toggle(isOn: configuration.$isOn) { configuration.label }
                .toggleStyle(.switch)
                .labelsHidden()
        }
    }
}