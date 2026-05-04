import XCTest
@testable import Cleam

final class ByteFormatterTests: XCTestCase {
    func testBytes() {
        XCTAssertEqual(ByteFormatter.format(0 as UInt64), "0 B")
        XCTAssertEqual(ByteFormatter.format(512 as UInt64), "512 B")
        XCTAssertEqual(ByteFormatter.format(999 as UInt64), "999 B")
    }

    func testKilobytes() {
        XCTAssertEqual(ByteFormatter.format(1000 as UInt64), "1.0 KB")
        XCTAssertEqual(ByteFormatter.format(1500 as UInt64), "1.5 KB")
        XCTAssertEqual(ByteFormatter.format(999_999 as UInt64), "1000.0 KB")
    }

    func testMegabytes() {
        XCTAssertEqual(ByteFormatter.format(1_000_000 as UInt64), "1.0 MB")
        XCTAssertEqual(ByteFormatter.format(1_500_000 as UInt64), "1.5 MB")
    }

    func testGigabytes() {
        XCTAssertEqual(ByteFormatter.format(1_000_000_000 as UInt64), "1.0 GB")
        XCTAssertEqual(ByteFormatter.format(2_500_000_000 as UInt64), "2.5 GB")
    }

    func testTerabytes() {
        XCTAssertEqual(ByteFormatter.format(1_000_000_000_000 as UInt64), "1.0 TB")
    }
}
