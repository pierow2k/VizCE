//
//  AppState.swift
//  Grabber
//
//  Created by Alin Lupascu on 4/8/24.
//

import Foundation
import Combine
import SwiftUI
import AlinFoundation
import Vision

/// Main-actor preferences and capture generations shared by menu actions and recognition.
@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()
    let launchAtLogin = LaunchAtLoginController()
    /// Post-processing output for the current capture, including progress or failure text.
    @Published var cmdOutput: String = ""
    /// The generation used to reject superseded screen captures and post-processing output.
    let captureIdentity = OperationIdentity()
    /// The reset generation that invalidates recognition and color results after history is cleared.
    private(set) var clearGeneration: UInt64 = 0

    /// Clears processing output and advances the current capture generation.
    ///
    /// - Returns: The token used to check whether this capture is still current.
    @discardableResult
    func beginCapture() -> UInt64 {
        cmdOutput = ""
        return captureIdentity.advance()
    }

    /// Invalidates results from all earlier captures and clears processing output.
    func invalidateCaptures() {
        clearGeneration &+= 1
        beginCapture()
    }
    /// The last published color; empty representations indicate that no color has been captured.
    @Published var colorSample: ColorItem = ColorItem(hex: "", rgb: "")
    /// The persisted Vision language code, with `"All"` selecting automatic language handling.
    @AppStorage("selectedLanguageCode") private var storedLanguageCode: String = "All"
    @AppStorage("selectedQuality") private var selectedQualityRaw: String = TextRecognitionQuality.accurate.rawValue

    let languages = RecognitionLanguageSelection()
    private var languageSubscription: AnyCancellable?

    /// The persisted language selection, which is retained even when unavailable at the selected quality.
    var selectedLanguageCode: String {
        get { storedLanguageCode }
        set {
            objectWillChange.send()
            storedLanguageCode = newValue
        }
    }

    /// Starts language discovery for the selected recognition quality.
    func refreshLanguages() {
        languages.load(RecognitionConfiguration(fast: selectedQuality == .fast))
    }

    /// The persisted recognition level, falling back to accurate for unknown values; setting it reloads languages.
    var selectedQuality: TextRecognitionQuality {
        get {
            TextRecognitionQuality(rawValue: selectedQualityRaw) ?? .accurate
        }
        set {
            objectWillChange.send()
            selectedQualityRaw = newValue.rawValue
            refreshLanguages()
        }
    }

    /// Forwards language state changes to observers and starts initial language discovery.
    init() {
        languageSubscription = languages.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }
        refreshLanguages()
    }


}
