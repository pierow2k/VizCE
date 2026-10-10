import AlinFoundation
import SwiftUI

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
                                    UpdateBadge(updater: updater, hideLabel: true)
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

                            // === Buttons ==============================================================================================

                            HStack(alignment: .center, spacing: 20) {
                                Spacer()
                                Button {
                                    updater.checkForUpdates(sheet: true, force: true)
                                } label: {
                                    Label("Refresh", systemImage: "arrow.uturn.left.circle")
                                }

                                Button {
                                    NSWorkspace.shared.open(
                                        URL(string: "https://github.com/alienator88/Viz/releases")!)
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
    }
}
