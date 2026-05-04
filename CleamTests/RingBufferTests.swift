import XCTest
@testable import Cleam

final class RingBufferTests: XCTestCase {
    func testAppendAndElements() {
        var buffer = RingBuffer<Int>(capacity: 3, defaultValue: 0)
        XCTAssertTrue(buffer.isEmpty)

        buffer.append(1)
        buffer.append(2)
        XCTAssertEqual(buffer.elements, [1, 2])
        XCTAssertEqual(buffer.currentCount, 2)

        buffer.append(3)
        XCTAssertEqual(buffer.elements, [1, 2, 3])
        XCTAssertTrue(buffer.isFull)

        buffer.append(4)
        XCTAssertEqual(buffer.elements, [2, 3, 4])
        XCTAssertEqual(buffer.latest, 4)
    }

    func testLatest() {
        var buffer = RingBuffer<String>(capacity: 5, defaultValue: "")
        XCTAssertNil(buffer.latest)

        buffer.append("a")
        XCTAssertEqual(buffer.latest, "a")

        buffer.append("b")
        XCTAssertEqual(buffer.latest, "b")
    }
}
