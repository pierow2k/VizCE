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

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()
    let launchAtLogin = LaunchAtLoginController()
    @Published var cmdOutput: String = ""
    let captureIdentity = OperationIdentity()
    private(set) var clearGeneration: UInt64 = 0

    @discardableResult
    func beginCapture() -> UInt64 {
        cmdOutput = ""
        return captureIdentity.advance()
    }

    func invalidateCaptures() {
        clearGeneration &+= 1
        beginCapture()
    }
    @Published var colorSample: ColorItem = ColorItem(hex: "", rgb: "")
    @AppStorage("selectedLanguageCode") private var storedLanguageCode: String = "All"
    @AppStorage("selectedQuality") private var selectedQualityRaw: String = TextRecognitionQuality.accurate.rawValue

    let languages = RecognitionLanguageSelection()
    private var languageSubscription: AnyCancellable?

    var selectedLanguageCode: String {
        get { storedLanguageCode }
        set {
            objectWillChange.send()
            storedLanguageCode = newValue
        }
    }

    func refreshLanguages() {
        languages.load(RecognitionConfiguration(fast: selectedQuality == .fast))
    }

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

    init() {
        languageSubscription = languages.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }
        refreshLanguages()
    }


}
