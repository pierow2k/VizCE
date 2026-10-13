import AlinFoundation
import SwiftUI

/// Update frequency, recent releases, and manual refresh controls for the shared updater.
struct UpdaterSettingsView: View {
    @EnvironmentObject private var updater: Updater

    var body: some View {
        GeometryReader { viewport in
            ScrollView {
                VStack(alignment: .center) {
                    GroupBox {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                FrequencyView(updater: updater)
                                if updater.updateAvailable {
                                    Divider()
                                        .padding(.trailing, 8)
                                    Button("Update Available", systemImage: "arrow.down.app") {
                                        updater.sheet = true
                                    }
                                    .labelStyle(.iconOnly)
                                    .foregroundStyle(.green)
                                    .help("Show Available Update")
                                }
                            }
                            .padding()
                            .background {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.primary.opacity(0.05))
                            }

                            RecentReleasesView(updater: updater)
                                .frame(height: max(120, viewport.size.height * 0.6))
                                .frame(maxWidth: .infinity)

                            HStack(alignment: .center, spacing: 20) {
                                Spacer()
                                Button {
                                    updater.checkForUpdates(sheet: true, force: true)
                                } label: {
                                    Label("Refresh", systemImage: "arrow.uturn.left.circle")
                                }

                                Button {
                                    guard let url = URL(string: "https://github.com/pierow2k/VizCE/releases") else {
                                        return
                                    }
                                    NSWorkspace.shared.open(url)
                                } label: {
                                    Label("Releases", systemImage: "link")
                                }
                                Spacer()
                            }
                        }
                        .padding()
                    }
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        // Keep the presenter installed even when Refresh finds no update.
        // The framework badge starts another check on appearance, which can dismiss this sheet.
        .sheet(isPresented: $updater.sheet) {
            updater.getUpdateView()
        }
    }
}
