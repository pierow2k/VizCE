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
final class RecognizedContent: ObservableObject {
    static let shared = RecognizedContent()
    @Published var items = [TextItem]()
}

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


enum TextRecognitionQuality: String, CaseIterable, Identifiable {
    case fast = "Fast"
    case accurate = "Accurate"

    var id: String { self.rawValue }
}

enum HistoryEntry: Identifiable, Codable {
    case text(TextItem)
    case color(ColorItem)

    var id: String {
        switch self {
        case .text(let item): return item.id
        case .color(let item): return item.id
        }
    }
}

class TextItem: Identifiable, Codable {
    let id: String
    var text: String

    init(id: String = UUID().uuidString, text: String) {
        self.id = id
        self.text = text
    }
}

struct ColorItem: Identifiable, Codable {
    let id: String
    let hex: String
    let rgb: String
    var color: Color { Color(hex: hex) ?? Color.white }

    init(hex: String, rgb: String, id: String = UUID().uuidString) {
        self.id = id
        self.hex = hex
        self.rgb = rgb
    }
}
