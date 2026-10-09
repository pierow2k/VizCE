import SwiftUI
import ServiceManagement

struct LaunchAtLoginView: View {
    @ObservedObject var controller: LaunchAtLoginController

    var body: some View {
        VStack(alignment: .leading) {
            Toggle("Launch at login", isOn: $controller.isEnabled)
                .toggleStyle(SpacedToggle())
                .disabled(controller.isPending)
            if controller.status == .requiresApproval {
                Text("Launch at login needs approval in System Settings.").font(.caption)
                Button("Open Login Items") { SMAppService.openSystemSettingsLoginItems() }
            } else if controller.status == .notFound {
                Text("The login service is unavailable. Try a signed, installed build of Viz.").font(.caption)
            }
        }
        .task { controller.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in controller.refresh() }
        .alert("Launch at login failed", isPresented: Binding(
            get: { controller.errorMessage != nil }, set: { if !$0 { controller.errorMessage = nil } }
        )) {
            Button("OK") { controller.errorMessage = nil }
        } message: { Text(controller.errorMessage ?? "") }
    }
}
