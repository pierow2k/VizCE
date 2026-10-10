//
//  VizApp.swift
//  Viz
//
//  Created by Alin Lupascu on 4/5/24.
//

import SwiftUI
import AlinFoundation

/// The menu bar application and settings scene with shared capture, history, and updater state.
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
