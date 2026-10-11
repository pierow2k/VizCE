//
//  ContentView.swift
//  VizCE
//
//  Created by Alin Lupascu on 4/9/24.
//

import AlinFoundation
import AppKit
import Foundation
import KeyboardShortcuts
import SwiftUI

/// The menu bar controls for capture, history, settings, and application termination.
struct ContentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openSettings) private var openSettings
    @EnvironmentObject var updater: Updater
    /// The registration token that allows this menu view to remove only its own dismissal action.
    @State private var menuRegistration: UUID?

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            HStack(alignment: .center, spacing: 10) {
                Text("V I Z C E")
                    .font(.system(size: 18, design: .rounded))
                    .bold()
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.red, .purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: .black, radius: 2, x: 0, y: 0)
                    .padding(.leading, 5)

                Spacer()

                HStack {
                    Button(action: showSettings) {
                        Group {
                            if updater.updateAvailable { Label("Updates", systemImage: "arrow.down.circle") } else { Label("Settings", systemImage: "gear") }
                        }
                        .labelStyle(.iconOnly)
                        .font(.system(size: 17))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(updater.updateAvailable ? .green : .secondary)
                    .help(updater.updateAvailable ? Text("Open Updates") : Text("Open Settings"))

                    Button(action: quit) {
                        Label("Quit VizCE", systemImage: "x.circle.fill")
                            .labelStyle(.iconOnly)
                            .font(.system(size: 18))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .help("Quit VizCE")
                }
                .padding(4)
                .padding(.horizontal, 2)
                .background {
                    Capsule()
                        .fill(Color.secondary.opacity(0.2))
                }
            }
            .padding(6)

            HStack(spacing: 5) {
                MenuActionTile(
                    title: "Capture", icon: "viewfinder",
                    help: "Capture section of screen to extract text and barcodes",
                    shortcut: .captureContent, shortcutLabel: "Edit Capture shortcut", action: capture)
                MenuActionTile(
                    title: "Webcam", icon: "camera",
                    help: "Open webcam capture window for OCR",
                    shortcut: .captureWebcam, shortcutLabel: "Edit Webcam shortcut", action: captureWebcam)
                MenuActionTile(
                    title: "Color", icon: "eyedropper",
                    help: "Capture hex/rgb value from click location",
                    shortcut: .eyedropper, shortcutLabel: "Edit Color shortcut", action: captureColor)
                MenuActionTile(
                    title: "History", icon: "clock",
                    help: "Show history of captures from this session",
                    shortcut: .history, shortcutLabel: "Edit History shortcut", action: showHistory)
                MenuActionTile(
                    title: "Clear", icon: "delete.left",
                    help: "Clear clipboard contents and stored captures",
                    shortcut: .clear, shortcutLabel: "Edit Clear shortcut", action: clearCaptures)
            }
            .padding([.horizontal, .bottom, .top])
        }
        .background(Color("bg"))
        .frame(width: 600)
        .onAppear {
            menuRegistration = MenuPresentationController.shared.register { dismiss() }
        }
        .onDisappear {
            if let menuRegistration { MenuPresentationController.shared.unregister(menuRegistration) }
            menuRegistration = nil
        }
    }

    /// Selects Updates when an update is available, otherwise General, then opens settings and dismisses the menu.
    private func showSettings() {
        UserDefaults.standard.set(
            updater.updateAvailable ? SettingsTab.updates.rawValue : SettingsTab.general.rawValue,
            forKey: "settingsSelectedTab")
        NSApp.activate()
        openSettings()
        dismiss()
    }

    /// Requests application termination, allowing the delegate to flush history first.
    private func quit() { NSApp.terminate(nil) }

    /// Starts screen acquisition and dismisses the menu.
    private func capture() {
        CaptureService.shared.captureContent()
        dismiss()
    }

    /// Dismisses the menu and shows the webcam capture window.
    private func captureWebcam() {
        dismiss()
        openWebcamCapture()
    }

    /// Dismisses the menu and starts the system color sampler.
    private func captureColor() {
        dismiss()
        processColor()
    }

    /// Opens the history window and dismisses the menu.
    private func showHistory() {
        openHistory()
        dismiss()
    }

    /// Clears capture history and the clipboard while invalidating pending capture delivery.
    private func clearCaptures() { clearCaptureHistoryAndClipboard() }
}
