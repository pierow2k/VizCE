//
//  GrabberApp.swift
//  Grabber
//
//  Created by Alin Lupascu on 4/5/24.
//

import SwiftUI
import KeyboardShortcuts
import AlinFoundation

@main
struct VizApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject var appState = AppState.shared
    @StateObject private var updater = Updater(owner: "pierow2k", repo: "Viz")

    var body: some Scene {
        MenuBarExtra("Viz", systemImage: updater.updateAvailable ? "arrow.down.circle" : "eye", content: {
            ContentView()
                .environment(\.colorScheme, .dark)
                .preferredColorScheme(.dark)
                .environmentObject(updater)
                .environmentObject(appState)
                .environmentObject(HistoryState.shared)
        })
        .menuBarExtraStyle(.window)
        
        Settings {
            SettingsView()
                .environmentObject(appState)
                .environmentObject(HistoryState.shared)
                .environmentObject(updater)
                .toolbarBackground(.clear)
                .movableByWindowBackground()
        }
        .defaultSize(width: 500, height: 600)
        .windowResizability(.contentMinSize)
    }
}


@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private let windowController = WindowManager.shared
    private var quitWithoutSaving = false

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard !quitWithoutSaving else { return .terminateNow }
        Task { @MainActor in
            do {
                try await HistoryState.shared.flush()
                sender.reply(toApplicationShouldTerminate: true)
            } catch {
                sender.reply(toApplicationShouldTerminate: false)
                NSApp.activate()
                let alert = NSAlert()
                alert.messageText = String(localized: "History could not be saved")
                alert.informativeText = error.localizedDescription
                alert.addButton(withTitle: String(localized: "Retry"))
                alert.addButton(withTitle: String(localized: "Cancel"))
                alert.addButton(withTitle: String(localized: "Quit Without Saving"))
                switch alert.runModal() {
                case .alertFirstButtonReturn:
                    HistoryState.shared.repository.retry()
                    sender.terminate(nil)
                case .alertThirdButtonReturn:
                    self.quitWithoutSaving = true
                    sender.terminate(nil)
                default: break
                }
            }
        }
        return .terminateLater
    }

    func applicationDidFinishLaunching(_ notification: Notification) {

        KeyboardShortcuts.onKeyUp(for: .captureContent) {
            CaptureService.shared.captureContent()
        }

        KeyboardShortcuts.onKeyUp(for: .captureWebcam) {
            MenuPresentationController.shared.dismiss()
            openWebcamCapture()
        }

        KeyboardShortcuts.onKeyUp(for: .eyedropper) {
            processColor()
        }

        KeyboardShortcuts.onKeyUp(for: .history) {
            MenuPresentationController.shared.dismiss()
            self.windowController.open(id: "history", with: HistoryView(), width: 500, height: 600, material: .sidebar)
        }

        KeyboardShortcuts.onKeyUp(for: .clear) {
            clearClipboard()
        }

#if !DEBUG
        ensureApplicationSupportFolderExists()
#endif

    }

}


extension KeyboardShortcuts.Name {
    static let captureContent = Self("captureContent", default: .init(.one, modifiers: [.command, .control]))
}

extension KeyboardShortcuts.Name {
    static let captureWebcam = Self("captureWebcam", default: .init(.two, modifiers: [.command, .control]))
}

extension KeyboardShortcuts.Name {
    static let eyedropper = Self("eyedropper", default: .init(.three, modifiers: [.command, .control]))
}

extension KeyboardShortcuts.Name {
    static let history = Self("history", default: .init(.four, modifiers: [.command, .control]))
}

extension KeyboardShortcuts.Name {
    static let clear = Self("clear", default: .init(.five, modifiers: [.command, .control]))
}
