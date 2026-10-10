import SwiftUI
import XCTest

final class SettingsTabTests: XCTestCase {
    func testPersistedValuesRemainCompatible() {
        XCTAssertEqual(SettingsTab.allCases.map(\.rawValue), [0, 1, 2, 3])
        XCTAssertEqual(SettingsTab(rawValue: 0), .general)
        XCTAssertEqual(SettingsTab(rawValue: 1), .shortcuts)
        XCTAssertEqual(SettingsTab(rawValue: 2), .updates)
        XCTAssertEqual(SettingsTab(rawValue: 3), .about)
    }

    @MainActor
    func testAppStorageReadsAndWritesExistingIntegerPreference() throws {
        let suite = "Viz.SettingsTabTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        for tab in SettingsTab.allCases {
            defaults.set(tab.rawValue, forKey: "settingsSelectedTab")
            let storage = AppStorage(wrappedValue: SettingsTab.general, "settingsSelectedTab", store: defaults)
            XCTAssertEqual(storage.wrappedValue, tab)
            storage.wrappedValue = .updates
            XCTAssertEqual(defaults.integer(forKey: "settingsSelectedTab"), 2)
        }
    }

    @MainActor
    func testAbsentAndUnsupportedPreferencesFallBackToGeneral() throws {
        let suite = "Viz.SettingsTabTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let absent = AppStorage(wrappedValue: SettingsTab.general, "settingsSelectedTab", store: defaults)
        XCTAssertEqual(absent.wrappedValue, .general)
        for raw in [-1, 4, 999] {
            defaults.set(raw, forKey: "settingsSelectedTab")
            let storage = AppStorage(wrappedValue: SettingsTab.general, "settingsSelectedTab", store: defaults)
            XCTAssertEqual(storage.wrappedValue, .general)
            XCTAssertEqual(defaults.integer(forKey: "settingsSelectedTab"), raw)
        }
    }
}
