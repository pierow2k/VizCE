import XCTest
import Foundation

final class RecognitionLanguageTests: XCTestCase {
    func testConcurrentRequestsShareDiscoveryAndCacheConfiguration() async throws {
        let probe = LanguageDiscoveryProbe()
        let catalog = RecognitionLanguageCatalog { configuration in await probe.discover(configuration) }
        let accurate = RecognitionConfiguration(fast: false, revision: 1)
        async let first = catalog.codes(for: accurate)
        async let second = catalog.codes(for: accurate)
        let values = try await [first, second]
        XCTAssertEqual(values, [["en-US"], ["en-US"]])
        _ = try await catalog.codes(for: accurate)
        _ = try await catalog.codes(for: RecognitionConfiguration(fast: true, revision: 1))
        _ = try await catalog.codes(for: RecognitionConfiguration(fast: false, revision: 2))
        let calls = await probe.calls
        XCTAssertEqual(calls.count, 3)
    }

    func testUnavailableAndAllCodesResolveWithoutChangingStoredChoice() async throws {
        let catalog = RecognitionLanguageCatalog { _ in ["en-US"] }
        let configuration = RecognitionConfiguration(fast: false)
        let supported = try await catalog.effectiveCode("en-US", for: configuration)
        let unavailable = try await catalog.effectiveCode("fr-FR", for: configuration)
        let all = try await catalog.effectiveCode("All", for: configuration)
        XCTAssertEqual(supported, "en-US")
        XCTAssertNil(unavailable)
        XCTAssertNil(all)
    }

    func testLocaleChangesOnlyDisplayNames() {
        let code = "vi-VT"
        let english = RecognitionLanguageName.displayName(for: code, locale: Locale(identifier: "en"))
        let french = RecognitionLanguageName.displayName(for: code, locale: Locale(identifier: "fr"))
        XCTAssertNotEqual(english, french)
        XCTAssertFalse(english.contains("VT"))
        XCTAssertEqual(code, "vi-VT")
    }

    @MainActor
    func testLateQualityResultCannotReplaceNewSelection() async {
        let probe = DelayedLanguageDiscovery()
        let catalog = RecognitionLanguageCatalog { config in await probe.discover(config) }
        let selection = RecognitionLanguageSelection(catalog: catalog)
        selection.load(RecognitionConfiguration(fast: false))
        await probe.waitFor(false)
        selection.load(RecognitionConfiguration(fast: true))
        await probe.waitFor(true)
        await probe.finish(true, codes: ["fast"])
        await selection.waitForLoad()
        await probe.finish(false, codes: ["accurate"])
        for _ in 0..<20 { await Task.yield() }
        XCTAssertEqual(selection.codes, ["fast"])
        XCTAssertFalse(selection.isLoading)
    }

    @MainActor
    func testDiscoveryFailureCanBeRetried() async {
        let probe = FailingLanguageDiscovery()
        let catalog = RecognitionLanguageCatalog { _ in try await probe.discover() }
        let selection = RecognitionLanguageSelection(catalog: catalog)
        let configuration = RecognitionConfiguration(fast: false)
        selection.load(configuration)
        await selection.waitForLoad()
        XCTAssertNotNil(selection.failure)
        selection.load(configuration)
        await selection.waitForLoad()
        XCTAssertNil(selection.failure)
        XCTAssertEqual(selection.codes, ["en-US"])
    }
}

/// A discovery fixture that records configuration queries before returning one language.
private actor LanguageDiscoveryProbe {
    var calls: [RecognitionConfiguration] = []
    func discover(_ configuration: RecognitionConfiguration) -> [String] {
        calls.append(configuration)
        return ["en-US"]
    }
}

/// A discovery fixture with independently held results keyed by recognition quality.
private actor DelayedLanguageDiscovery {
    private var continuations: [Bool: CheckedContinuation<[String], Never>] = [:]
    func discover(_ configuration: RecognitionConfiguration) async -> [String] {
        await withCheckedContinuation { continuations[configuration.fast] = $0 }
    }
    func waitFor(_ fast: Bool) async { while continuations[fast] == nil { await Task.yield() } }
    func finish(_ fast: Bool, codes: [String]) { continuations.removeValue(forKey: fast)?.resume(returning: codes) }
}

/// A discovery fixture that fails once so the catalog’s retry behavior can be exercised.
private actor FailingLanguageDiscovery {
    private var fail = true
    func discover() throws -> [String] {
        if fail { fail = false; throw CocoaError(.fileReadUnknown) }
        return ["en-US"]
    }
}
