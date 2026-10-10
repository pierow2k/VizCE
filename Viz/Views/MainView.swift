//
//  MainView.swift
//  Viz
//
//  Created by Alin Lupascu on 4/9/24.
//

import AppKit
import Foundation
import SwiftUI
import KeyboardShortcuts
import AlinFoundation

struct ContentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openSettings) private var openSettings
    @EnvironmentObject var updater: Updater
    @State private var menuRegistration: UUID?


    var body: some View {

        VStack(alignment: .center, spacing: 0) {

            HStack(alignment: .center, spacing: 10) {

                Text("V I Z")
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

                HStack() {

                    Button(action: showSettings) {
                        Group {
                            if updater.updateAvailable { Label("Updates", systemImage: "arrow.down.circle") }
                            else { Label("Settings", systemImage: "gear") }
                        }
                        .labelStyle(.iconOnly)
                        .font(.system(size: 17))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(updater.updateAvailable ? .green : .secondary)
                    .help(updater.updateAvailable ? Text("Open Updates") : Text("Open Settings"))

                    Button(action: quit) {
                        Label("Quit Viz", systemImage: "x.circle.fill")
                            .labelStyle(.iconOnly)
                            .font(.system(size: 18))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .help("Quit Viz")
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

    private func showSettings() {
        UserDefaults.standard.set(
            updater.updateAvailable ? SettingsTab.updates.rawValue : SettingsTab.general.rawValue,
            forKey: "settingsSelectedTab")
        NSApp.activate()
        openSettings()
        dismiss()
    }

    private func quit() { NSApp.terminate(nil) }

    private func capture() {
        CaptureService.shared.captureContent()
        dismiss()
    }

    private func captureWebcam() {
        dismiss()
        openWebcamCapture()
    }

    private func captureColor() {
        dismiss()
        processColor()
    }

    private func showHistory() {
        openHistory()
        dismiss()
    }

    private func clearCaptures() { clearCaptureHistoryAndClipboard() }

}
