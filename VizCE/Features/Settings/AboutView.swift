import AlinFoundation
import SwiftUI

/// Application identity, version information, and a link to the maintained repository.
struct AboutView: View {
    var body: some View {
        VStack(spacing: 0) {
            Image(nsImage: NSApp.applicationIconImage ?? NSImage())
                .padding()
                .accessibilityHidden(true)

            Text(Bundle.main.name)
                .font(.title)
                .bold()
                .foregroundStyle(
                    LinearGradient(
                        colors: [.red, .purple, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text("Version \(Bundle.main.version) (Build \(Bundle.main.buildVersion))")
                .padding(.vertical, 4)

            Button {
                guard let url = URL(string: "https://github.com/pierow2k/VizCE") else { return }
                NSWorkspace.shared.open(url)
            } label: {
                Label("GitHub", systemImage: "paperplane")
                    .padding(5)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)

            Spacer()

            HStack(spacing: 0) {
                Spacer()
                Text("Made with ❤️ by ")
                Text("Pierow2k and the VizCE Community")
                    .bold()
                Spacer()
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("bg"))
        .environment(\.colorScheme, .dark)
        .preferredColorScheme(.dark)
    }
}
