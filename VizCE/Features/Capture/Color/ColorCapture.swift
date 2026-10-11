import AppKit
import SwiftUI

/// Shows the system color sampler and formats the selected device-RGB color.
///
/// - Returns: Hexadecimal and RGB representations, or empty strings on cancellation or failed color conversion.
@MainActor
func pickColor() async -> ColorItem {
    await withCheckedContinuation { continuation in
        NSColorSampler()
            .show { selectedColor in
                if let selectedColor,
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

/// Starts color sampling and publishes the clipboard, history, sound, and preview after a valid selection.
///
/// A history clear while sampling prevents the result from being published.
@MainActor
func processColor() {
    let state = AppState.shared
    state.beginCapture()
    let clearToken = state.clearGeneration
    Task {
        let result = await pickColor()

        guard state.clearGeneration == clearToken, !result.hex.isEmpty else { return }

        copyColorsToClipboard(color: result)
        playCaptureSound()
        AppState.shared.colorSample = result
        let colorItem = ColorItem(hex: result.hex, rgb: result.rgb)
        let entry = HistoryEntry.color(colorItem)
        HistoryState.shared.append(entry)
        await MainActor.run {
            PreviewWindowController.shared.show(ColorPreviewView())
        }
    }
}
