import SwiftUI

/// Camera startup progress and recovery actions for permission or capture failures.
struct WebcamRecoveryView: View {
    let state: WebcamState
    let devices: [WebcamDevice]
    let retry: @MainActor () -> Void
    let refresh: @MainActor () -> Void
    let choose: @MainActor (String) -> Void

    var body: some View {
        VStack(spacing: 12) {
            switch state {
            case .authorizing: ProgressView("Requesting camera access")
            case .starting: ProgressView("Starting camera")

            case .permissionDenied:
                Text("Camera access denied").font(.headline)
                Button("Open Camera Privacy Settings") {
                    if let url = URL(
                        string:
                            "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera"
                    ) {
                        NSWorkspace.shared.open(url)
                    }
                }
                Button("Retry", action: retry)

            case .failed(let message):
                Text("Camera unavailable").font(.headline)
                Text(message).multilineTextAlignment(.center)
                Button("Retry", action: retry)
                Menu("Choose Camera") {
                    Button("Refresh cameras", action: refresh)
                    ForEach(devices) { device in Button(device.name) { choose(device.id) } }
                    if devices.isEmpty { Text("No cameras connected") }
                }
                .onAppear(perform: refresh)

            default: Text("Camera stopped")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
        .foregroundStyle(.white)
    }
}
