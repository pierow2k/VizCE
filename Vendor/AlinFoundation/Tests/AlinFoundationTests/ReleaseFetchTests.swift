import Combine
import XCTest
@testable import AlinFoundation

final class ReleaseFetchTests: XCTestCase {
    /// Installs the protocol for test-owned URLs only.
    override func setUp() {
        super.setUp()
        XCTAssertTrue(URLProtocol.registerClass(ReleaseURLProtocol.self))
    }

    /// Removes the test protocol without touching unrelated cached responses.
    override func tearDown() {
        URLProtocol.unregisterClass(ReleaseURLProtocol.self)
        super.tearDown()
    }

    @MainActor
    func testFailuresPublishUsefulErrorsOnTheMainThread() async {
        let fixtures = [
            ("http404", ReleaseFetchError.httpStatus(404).localizedDescription),
            ("http403", ReleaseFetchError.httpStatus(403).localizedDescription),
            ("malformed", ReleaseFetchError.invalidReleaseData.localizedDescription),
            ("nonhttp", ReleaseFetchError.invalidResponse.localizedDescription),
            ("offline", URLError(.notConnectedToInternet).localizedDescription)
        ]
        for (prefix, expected) in fixtures {
            let service = makeService(prefix)
            await loadFailure(service)
            XCTAssertEqual(service.releaseFetchError, expected)
            XCTAssertTrue(service.releases.isEmpty)
            XCTAssertFalse(service.sheet)
        }
    }

    @MainActor
    func testSuccessfulRetryClearsTheErrorAndLoadsReleases() async {
        let service = makeService("retry")
        await loadFailure(service)
        XCTAssertNotNil(service.releaseFetchError)
        await loadSuccess(service)
        XCTAssertNil(service.releaseFetchError)
        XCTAssertEqual(service.releases.first?.tagName, "v3.0.0")
        XCTAssertTrue(service.updateAvailable)
    }

    @MainActor
    func testFailurePreservesPreviouslyLoadedReleasesAndAvailability() async {
        let service = makeService("preserve")
        await loadSuccess(service)
        service.sheet = false
        await loadFailure(service)
        XCTAssertEqual(service.releases.first?.tagName, "v3.0.0")
        XCTAssertTrue(service.updateAvailable)
        XCTAssertNotNil(service.releaseFetchError)
        XCTAssertFalse(service.sheet)
    }

    @MainActor
    func testSuccessfulEmptyResponseResetsAnEarlierUpdateBadge() async {
        let service = makeService("emptyafter")
        await loadSuccess(service)
        XCTAssertTrue(service.updateAvailable)
        await loadSuccess(service)
        XCTAssertTrue(service.releases.isEmpty)
        XCTAssertFalse(service.updateAvailable)
        XCTAssertNil(service.releaseFetchError)
    }

    @MainActor
    func testReleaseChecksBypassACachedPermanentRedirect() async throws {
        let service = makeService("cache")
        let url = try XCTUnwrap(URL(string: "https://api.github.com/repos/\(service.owner)/\(service.repo)/releases"))
        let request = URLRequest(url: url)
        let response = try XCTUnwrap(HTTPURLResponse(
            url: url, statusCode: 301, httpVersion: nil,
            headerFields: ["Location": "https://api.github.com/repositories/0/releases", "Cache-Control": "max-age=31536000"]
        ))
        URLCache.shared.storeCachedResponse(CachedURLResponse(response: response, data: Data()), for: request)
        defer { URLCache.shared.removeCachedResponse(for: request) }
        XCTAssertNotNil(URLCache.shared.cachedResponse(for: request))
        await loadSuccess(service)
        XCTAssertEqual(service.releases.first?.tagName, "v3.0.0")
        XCTAssertNil(service.releaseFetchError)
    }

    @MainActor
    func testOlderFailureCannotOverwriteANewerSuccessfulCheck() async {
        let service = makeService("overlap")
        let started = expectation(description: "First request starts")
        let observer = NotificationCenter.default.publisher(for: ReleaseURLProtocol.requestStarted)
            .filter { ($0.object as? URL)?.path.contains(service.repo) == true }
            .first()
            .sink { _ in started.fulfill() }
        service.loadGithubReleases(sheet: false)
        await fulfillment(of: [started], timeout: 5)
        observer.cancel()
        await loadSuccess(service)
        // The first fixture returns HTTP 404 after 200 ms, after the successful second response.
        try? await Task.sleep(for: .milliseconds(400))
        XCTAssertNil(service.releaseFetchError)
        XCTAssertEqual(service.releases.first?.tagName, "v3.0.0")
        XCTAssertTrue(service.updateAvailable)
        XCTAssertTrue(service.sheet)
    }

    @MainActor
    func testSharedUpdaterPublishesTheServiceErrorForSettings() async {
        let updater = Updater(owner: "VizCEUpdaterTests", repo: "http404-\(UUID().uuidString)", announcements: false)
        let failed = expectation(description: "Shared updater publishes its release error")
        let observer = updater.$releaseFetchError.compactMap { $0 }.first().sink { _ in
            XCTAssertTrue(Thread.isMainThread)
            failed.fulfill()
        }
        updater.checkForUpdates(force: true)
        await fulfillment(of: [failed], timeout: 5)
        XCTAssertEqual(updater.releaseFetchError, ReleaseFetchError.httpStatus(404).localizedDescription)
        observer.cancel()
    }

    /// Creates a service with a unique URL whose prefix selects its response sequence.
    private func makeService(_ prefix: String) -> UpdaterService {
        UpdaterService(owner: "VizCEUpdaterTests", repo: "\(prefix)-\(UUID().uuidString)", token: "")
    }

    /// Waits for a failing manual check to publish its error without presenting an update sheet.
    @MainActor
    private func loadFailure(_ service: UpdaterService) async {
        let failed = expectation(description: "Release request publishes an error")
        let observer = service.$releaseFetchError.dropFirst().compactMap { $0 }.first().sink { _ in
            XCTAssertTrue(Thread.isMainThread)
            failed.fulfill()
        }
        service.loadGithubReleases(sheet: true, force: true)
        await fulfillment(of: [failed], timeout: 5)
        observer.cancel()
    }

    /// Waits until a successful manual check has updated its releases and sheet state.
    @MainActor
    private func loadSuccess(_ service: UpdaterService) async {
        let loaded = expectation(description: "Release request completes successfully")
        let observer = service.$sheet.dropFirst().filter { $0 }.first().sink { _ in
            XCTAssertTrue(Thread.isMainThread)
            loaded.fulfill()
        }
        service.loadGithubReleases(sheet: true, force: true)
        await fulfillment(of: [loaded], timeout: 5)
        observer.cancel()
    }
}
