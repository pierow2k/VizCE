import SwiftUI

@MainActor
struct SimpleSearchStyle: @preconcurrency TextFieldStyle {
    @State private var isHovered = false
    @State var trash: Bool = false
    @AppStorage("postcommands") private var text: String = "say [ocr];"

    func _body(configuration: TextField<Self._Label>) -> some View {

        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(.clear)
                .allowsHitTesting(false)
                .frame(height: 30)

            ZStack {
                HStack {
                    configuration
                        .font(.title3)
                        .foregroundStyle(.clear)
                        .textFieldStyle(PlainTextFieldStyle())

                    Spacer()

                    if trash && text != "" {
                        Button {
                            text = ""
                        } label: {
                            Label("Clear text", systemImage: "xmark.circle.fill")
                        }
                        .buttonStyle(SimpleButtonStyle(help: "Clear text", size: 14, padding: 0))
                    }
                }

            }
            .padding(.horizontal, 8)

        }
        .onHover { hovering in
            withAnimation(Animation.easeInOut(duration: 0.15)) {
                self.isHovered = hovering
            }
        }
    }
}