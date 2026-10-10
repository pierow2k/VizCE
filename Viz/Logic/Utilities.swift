//
//  Utilities.swift
//  Grabber
//
//  Created by Alin Lupascu on 4/5/24.
//

import Foundation
import SwiftUI
import AppKit

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
