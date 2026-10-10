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

                    Button {
                        UserDefaults.standard.set(updater.updateAvailable ? SettingsTab.updates.rawValue : SettingsTab.general.rawValue, forKey: "settingsSelectedTab")
                        NSApp.activate()
                        openSettings()
                        dismiss()
                    } label: {
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

                    Button {
                        NSApp.terminate(nil)
                    } label: {
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
                VStack {
                    Button("Capture") {
                        CaptureService.shared.captureContent()
                        dismiss()
                    }
                    .help("Capture section of screen to extract text and barcodes")
                    .buttonStyle(RoundedRectangleButtonStyle(image: "viewfinder", size: 15))

                    ShortcutEditorView(name: .captureContent, actionLabel: "Edit Capture shortcut")

                }


                VStack {
                    Button("Webcam") {
                        dismiss()
                        openWebcamCapture()
                    }
                    .help("Open webcam capture window for OCR")
                    .buttonStyle(RoundedRectangleButtonStyle(image: "camera", size: 15))

                    ShortcutEditorView(name: .captureWebcam, actionLabel: "Edit Webcam shortcut")

                }

                VStack {
                    Button("Color") {
                        dismiss()
                        processColor()
                    }
                    .help("Capture hex/rgb value from click location")
                    .buttonStyle(RoundedRectangleButtonStyle(image: "eyedropper", size: 15))

                    ShortcutEditorView(name: .eyedropper, actionLabel: "Edit Color shortcut")
                }

                VStack {
                    Button("History") {
                        openHistory()
                        dismiss()
                    }
                    .help("Show history of captures from this session")
                    .buttonStyle(RoundedRectangleButtonStyle(image: "clock", size: 15))

                    ShortcutEditorView(name: .history, actionLabel: "Edit History shortcut")

                }

                VStack {
                    Button("Clear") {
                        clearClipboard()
                    }
                    .help("Clear clipboard contents and stored captures")
                    .buttonStyle(RoundedRectangleButtonStyle(image: "delete.left", size: 15))

                    ShortcutEditorView(name: .clear, actionLabel: "Edit Clear shortcut")
                }

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
}
