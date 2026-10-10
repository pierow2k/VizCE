//
//  Utilities.swift
//  Grabber
//
//  Created by Alin Lupascu on 4/5/24.
//

import Foundation
import SwiftUI
import AppKit
import ServiceManagement






@MainActor
func copyTextItemsToClipboard(textItems: [TextItem]) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()

    let combinedText = textItems.map { $0.text }.joined(separator: "\n")
    pasteboard.setString(combinedText, forType: .string)
}

@MainActor
func copyColorsToClipboard(color: ColorItem) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(color.hex, forType: .string)
}


@MainActor
func clearClipboard(historyState: HistoryState? = nil) {
    AppState.shared.invalidateCaptures()
    CaptureService.shared.cancelCapture()
    CaptureNoticePresenter.shared.close()
    CaptureService.shared.recognizedContent.items.removeAll()
    CaptureService.shared.pasteboard.clearContents()
    (historyState ?? .shared).clear()
    PreviewWindowController.shared.close()
}


@MainActor
func pickColor() async -> ColorItem {
    await withCheckedContinuation { continuation in
        NSColorSampler().show { selectedColor in
            if let selectedColor = selectedColor,
               let color = selectedColor.usingColorSpace(.deviceRGB) {
                let red = Int(color.redComponent * 255)
                let green = Int(color.greenComponent * 255)
                let blue = Int(color.blueComponent * 255)
                let hex = String(format: "#%02X%02X%02X", red, green, blue)
                let rgb = "(\(red),\(green),\(blue))"
                continuation.resume(returning: ColorItem(hex: hex, rgb: rgb))
            } else {
                continuation.resume(returning: ColorItem(hex: "", rgb: ""))
            }
        }
    }
}

@MainActor
func processColor() {
    let state = AppState.shared
    state.beginCapture()
    let clearToken = state.clearGeneration
    Task {
        let result = await pickColor()

        guard state.clearGeneration == clearToken, !result.hex.isEmpty else { return }

        copyColorsToClipboard(color: result)
        playSound(for: .color(ColorItem(hex: "", rgb: "")))
        AppState.shared.colorSample = result
        let colorItem = ColorItem(hex: result.hex, rgb: result.rgb)
        let entry = HistoryEntry.color(colorItem)
        HistoryState.shared.append(entry)
        await MainActor.run {
            showPreviewWindow(contentView: ColorPreviewView())
        }
    }
}

extension NSColor {
    var hex: String {
        guard let rgbColor = usingColorSpace(.deviceRGB) else { return "N/A" }
        let red = Int(rgbColor.redComponent * 255)
        let green = Int(rgbColor.greenComponent * 255)
        let blue = Int(rgbColor.blueComponent * 255)
        return String(format: "#%02X%02X%02X", red, green, blue)
    }

    var rgb: String {
        guard let rgbColor = usingColorSpace(.deviceRGB) else { return "N/A" }
        let red = Int(rgbColor.redComponent * 255)
        let green = Int(rgbColor.greenComponent * 255)
        let blue = Int(rgbColor.blueComponent * 255)
        return "(\(red), \(green), \(blue))"
    }

    var swiftColor: Color {
        return Color(nsColor: self)
    }
}

extension View {
    // Helper function to apply the movable background window
    func movableByWindowBackground() -> some View {
        self.background { MovableWindowAccessor() }
    }
}

// Custom NSWindow accessor to modify window properties
struct MovableWindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let nsView = NSView()

        DispatchQueue.main.async {
            if let window = nsView.window {
                // Enable dragging by the window's background
                window.isMovableByWindowBackground = true
            }
        }

        return nsView
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}


@MainActor
func playSound(for entry: HistoryEntry) {
    @AppStorage("mute") var mute: Bool = false

    guard mute == false else { return }

    let soundName: String

    switch entry {
    case .text:
        soundName = "water"
    case .color:
        soundName = "water"
    }

    if let sound = NSSound(named: soundName) {
        sound.play()
    }
}


// Check app directory based on user permission
func checkAppDirectoryAndUserRole(completion: @escaping @Sendable ((isInCorrectDirectory: Bool, isAdmin: Bool)) -> Void) {
    isCurrentUserAdmin { isAdmin in
        let bundlePath = Bundle.main.bundlePath as NSString
        let applicationsDir = "/Applications"
        let userApplicationsDir = "\(NSHomeDirectory())/Applications"

        var isInCorrectDirectory = false

        if isAdmin {
            // Admins can have the app in either /Applications or ~/Applications
            isInCorrectDirectory = bundlePath.deletingLastPathComponent == applicationsDir ||
            bundlePath.deletingLastPathComponent == userApplicationsDir
        } else {
            // Standard users should only have the app in ~/Applications
            isInCorrectDirectory = bundlePath.deletingLastPathComponent == userApplicationsDir
        }

        // Return both conditions: if the app is in the correct directory and if the user is an admin
        completion((isInCorrectDirectory, isAdmin))
    }
}


// Check if user is admin or standard user
func isCurrentUserAdmin(completion: @escaping @Sendable (Bool) -> Void) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/zsh") // Using zsh, macOS default shell
    process.arguments = ["-c", "groups $(whoami) | grep -q ' admin '"]

    process.terminationHandler = { process in
        // On macOS, a process's exit status of 0 indicates success (admin group found in this context)
        completion(process.terminationStatus == 0)
    }

    do {
        try process.run()
    } catch {
        print("Failed to execute command: \(error)")
        completion(false)
    }
}

@MainActor
func updateOnMain(after delay: Double? = nil, _ updates: @escaping @MainActor () -> Void) {
    Task { @MainActor in
        if let delay {
            do { try await Task.sleep(for: .seconds(delay)) }
            catch { return }
        }
        updates()
    }
}


extension Bundle {

    var name: String {
        func string(for key: String) -> String? {
            object(forInfoDictionaryKey: key) as? String
        }
        return string(for: "CFBundleDisplayName")
        ?? string(for: "CFBundleName")
        ?? "N/A"
    }
}

extension Bundle {

    var version: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "N/A"
    }

    var buildVersion: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "N/A"
    }
}
