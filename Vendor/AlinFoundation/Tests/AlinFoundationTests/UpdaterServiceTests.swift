import Combine
import XCTest
@testable import AlinFoundation

final class UpdaterServiceTests: XCTestCase {
    @MainActor
    func testManualCheckPresentsSheetWhenAlreadyUpToDate() async {
        XCTAssertTrue(URLProtocol.registerClass(ReleaseURLProtocol.self))
        defer { URLProtocol.unregisterClass(ReleaseURLProtocol.self) }
        let service = UpdaterService(owner: "VizCEUpdaterTests", repo: "current-\(UUID().uuidString)", token: "")
        let presented = expectation(description: "Manual check presents the no-update sheet")
        let presentation = service.$sheet.dropFirst().filter { $0 }.sink { _ in presented.fulfill() }
        service.loadGithubReleases(sheet: true, force: true)
        await fulfillment(of: [presented], timeout: 5)
        XCTAssertEqual(service.releases.first?.tagName, "v0.0.0")
        XCTAssertFalse(service.updateAvailable)
        XCTAssertTrue(service.force)
        presentation.cancel()
    }

    @MainActor
    func testPrefixedReleasePublishesAvailabilityAndManualSheet() async {
        XCTAssertTrue(URLProtocol.registerClass(ReleaseURLProtocol.self))
        defer { URLProtocol.unregisterClass(ReleaseURLProtocol.self) }
        let service = UpdaterService(owner: "VizCEUpdaterTests", repo: UUID().uuidString, token: "")
        let presented = expectation(description: "Manual check presents the update sheet")
        let presentation = service.$sheet.dropFirst().filter { $0 }.sink { _ in presented.fulfill() }
        service.loadGithubReleases(sheet: true, force: true)
        await fulfillment(of: [presented], timeout: 5)
        XCTAssertEqual(service.releases.first?.tagName, "v3.0.0")
        XCTAssertTrue(service.updateAvailable)
        XCTAssertFalse(service.force)
        presentation.cancel()

        let checked = expectation(description: "Automatic check updates the badge without presenting a sheet")
        let automatic = service.$sheet.dropFirst().filter { !$0 }.sink { _ in checked.fulfill() }
        service.loadGithubReleases(sheet: false)
        await fulfillment(of: [checked], timeout: 5)
        XCTAssertTrue(service.updateAvailable)
        XCTAssertFalse(service.sheet)
        automatic.cancel()
    }
}
