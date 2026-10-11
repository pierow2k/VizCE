import XCTest

final class LaunchAtLoginTests: XCTestCase {
    @MainActor
    func testRefreshReflectsEveryStatusWithoutRegistering() async {
        XCTAssertEqual(LaunchAtLoginStatus.allCases, [.notRegistered, .enabled, .requiresApproval, .notFound])
        for status in LaunchAtLoginStatus.allCases {
            let service = FakeLoginService(status: status)
            let controller = LaunchAtLoginController(service: service)
            await controller.waitForPendingOperation()
            XCTAssertEqual(controller.status, status)
            XCTAssertEqual(controller.isEnabled, status == .enabled)
            controller.refresh()
            await controller.waitForPendingOperation()
            let counts = await service.counts()
            XCTAssertEqual(counts, [0, 0])
        }
    }

    @MainActor
    func testRegistrationFailureRestoresActualStatusAndReportsError() async {
        let service = FakeLoginService(status: .notRegistered, fail: true)
        let controller = LaunchAtLoginController(service: service)
        await controller.waitForPendingOperation()
        controller.isEnabled = true
        await controller.waitForPendingOperation()
        XCTAssertFalse(controller.isEnabled)
        XCTAssertNotNil(controller.errorMessage)
        XCTAssertFalse(controller.isPending)
    }

    @MainActor
    func testUnregistrationFailureKeepsEnabledStatus() async {
        let service = FakeLoginService(status: .enabled, fail: true)
        let controller = LaunchAtLoginController(service: service)
        await controller.waitForPendingOperation()
        controller.isEnabled = false
        await controller.waitForPendingOperation()
        XCTAssertTrue(controller.isEnabled)
        XCTAssertNotNil(controller.errorMessage)
    }

    @MainActor
    func testApprovalRequiredDoesNotReregisterAndCanUnregister() async {
        let service = FakeLoginService(status: .requiresApproval)
        let controller = LaunchAtLoginController(service: service)
        await controller.waitForPendingOperation()
        controller.isEnabled = true
        await controller.waitForPendingOperation()
        XCTAssertEqual(controller.status, .requiresApproval)
        XCTAssertFalse(controller.isEnabled)
        controller.isEnabled = false
        await controller.waitForPendingOperation()
        let counts = await service.counts()
        XCTAssertEqual(counts, [0, 1])
    }

    @MainActor
    func testSuccessAndEqualRequestsAvoidCompetingOperations() async {
        let service = FakeLoginService(status: .notRegistered)
        let controller = LaunchAtLoginController(service: service)
        await controller.waitForPendingOperation()
        controller.isEnabled = true
        controller.isEnabled = false
        await controller.waitForPendingOperation()
        XCTAssertTrue(controller.isEnabled)
        controller.isEnabled = true
        await controller.waitForPendingOperation()
        let counts = await service.counts()
        XCTAssertEqual(counts, [1, 0])
    }

    @MainActor
    func testErrorAfterPartialSuccessStillPublishesActualStatus() async {
        let service = FakeLoginService(status: .notRegistered, fail: true, partialSuccess: true)
        let controller = LaunchAtLoginController(service: service)
        await controller.waitForPendingOperation()
        controller.isEnabled = true
        await controller.waitForPendingOperation()
        XCTAssertTrue(controller.isEnabled)
        XCTAssertNotNil(controller.errorMessage)
    }
}

private actor FakeLoginService: LaunchAtLoginServicing {
    private var actual: LaunchAtLoginStatus
    private let fail: Bool
    private let partialSuccess: Bool
    private var registrations = 0
    private var unregistrations = 0

    init(status: LaunchAtLoginStatus, fail: Bool = false, partialSuccess: Bool = false) {
        actual = status
        self.fail = fail
        self.partialSuccess = partialSuccess
    }
    func status() -> LaunchAtLoginStatus { actual }
    func register() throws {
        registrations += 1
        if partialSuccess { actual = .enabled }
        if fail { throw CocoaError(.fileWriteNoPermission) }
        actual = .enabled
    }
    func unregister() throws {
        unregistrations += 1
        if fail { throw CocoaError(.fileWriteNoPermission) }
        actual = .notRegistered
    }
    func counts() -> [Int] { [registrations, unregistrations] }
}
