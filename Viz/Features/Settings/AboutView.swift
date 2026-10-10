import SwiftUI
import AlinFoundation

/// Application identity, version information, and a link to the maintained repository.
struct AboutView: View {

    var body: some View {

        VStack(spacing: 0) {

            Image(nsImage: NSApp.applicationIconImage ?? NSImage())
                .padding()

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
                NSWorkspace.shared.open(URL(string: "https://github.com/pierow2k/Viz")!)
            } label: {
                Label("GitHub", systemImage: "paperplane")
                    .padding(5)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)


            Spacer()

            HStack(spacing: 0){
                Spacer()
                Text("Made with ❤️ by ")
                Text("Pierow2k and the Viz Community")
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
