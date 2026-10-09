//
//  SettingsView.swift
//  Viz
//
//  Created by Alin Lupascu on 3/27/25.
//

import Foundation
import SwiftUI
import AlinFoundation
import KeyboardShortcuts
import AVFoundation

struct SettingsView: View {
    @EnvironmentObject var updater: Updater
    @AppStorage("appendRecognizedText") var appendRecognizedText: Bool = false
    @AppStorage("keepLineBreaks") var keepLineBreaks: Bool = true
    @AppStorage("showPreview") var showPreview: Bool = true
    @AppStorage("previewSeconds") var seconds: Double = 5.0
    @AppStorage("processing") var processingIsEnabled: Bool = false
    @AppStorage("postcommands") var postCommands: String = "say [ocr];"
    @AppStorage("mute") var mute: Bool = false
    @AppStorage("viewWidth") var viewWidth: Double = 300.0
    @AppStorage("viewHeight") var viewHeight: Double = 200.0
    @EnvironmentObject var appState: AppState
    @AppStorage("settingsSelectedTab") private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsView(
                appendRecognizedText: $appendRecognizedText,
                keepLineBreaks: $keepLineBreaks,
                showPreview: $showPreview,
                seconds: $seconds,
                processingIsEnabled: $processingIsEnabled,
                postCommands: $postCommands,
                mute: $mute,
                viewWidth: $viewWidth,
                viewHeight: $viewHeight
            )
            .tabItem {
                Image(systemName: "gear")
                Text("General")
            }
            .tag(0)
            
            ShortcutsSettingsView()
            .tabItem {
                Image(systemName: "keyboard")
                Text("Shortcuts")
            }
            .tag(1)
            
            UpdaterSettingsView()
                .environmentObject(updater)
            .tabItem {
                Image(systemName: "arrow.down.circle")
                Text("Updates")
            }
            .tag(2)

            ScrollView { AboutView() }
                .tabItem {
                    Image(systemName: "info.circle")
                    Text("About")
                }
                .tag(3)
        }
        .frame(minWidth: 400, idealWidth: 500, maxWidth: 500, minHeight: 300, idealHeight: 600, maxHeight: .infinity)
        .background(Color("bg"))
        .environment(\.colorScheme, .dark)
        .preferredColorScheme(.dark)
    }
}
