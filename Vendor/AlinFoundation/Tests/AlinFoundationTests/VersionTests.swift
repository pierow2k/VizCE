import AlinFoundation
import XCTest

final class VersionTests: XCTestCase {
    func testPrefixedReleaseRetainsItsMajorVersion() {
        let version = "v3.0.0".versionStringToTuple()
        XCTAssertEqual(version.0, 3)
        XCTAssertEqual(version.1, 0)
        XCTAssertEqual(version.2, 0)
        XCTAssertTrue("v3.0.0" > "1.0.0")
        XCTAssertTrue("V3.0.0" > "1.0.0")
    }

    func testEqualAndOlderReleasesDoNotOfferAnUpdate() {
        XCTAssertFalse("v3.0.0" > "3.0.0")
        XCTAssertFalse("3.0.0" > "v3.0.0")
        XCTAssertFalse("v2.9.9" > "3.0.0")
        XCTAssertFalse("v3.0.0" > "10.0.0")
    }

    func testVersionsCompareNumericallyAcrossComponents() {
        XCTAssertTrue("v10.0.0" > "9.0.0")
        XCTAssertTrue("v3.10.0" > "3.9.0")
        XCTAssertTrue("v3.0.10" > "3.0.9")
        XCTAssertFalse("v3.9.0" > "3.10.0")
    }

    func testUnprefixedAndShortVersionsRemainSupported() {
        XCTAssertTrue("3.0.0" > "1.0.0")
        XCTAssertTrue("v3" > "2.9.9")
        XCTAssertFalse("v3.0" > "3.0.0")
        XCTAssertFalse("" > "1.0.0")
    }
}
