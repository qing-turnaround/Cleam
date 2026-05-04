import XCTest
@testable import Cleam

final class MinHeapTests: XCTestCase {
    func testInsertAndSorted() {
        var heap = MinHeap<Int>(maxSize: 3)
        heap.insert(5)
        heap.insert(2)
        heap.insert(8)

        XCTAssertEqual(heap.count, 3)
        XCTAssertEqual(heap.sorted, [8, 5, 2])
    }

    func testMaxSizeEnforced() {
        var heap = MinHeap<Int>(maxSize: 3)
        heap.insert(1)
        heap.insert(2)
        heap.insert(3)
        heap.insert(10)
        heap.insert(0)

        XCTAssertEqual(heap.count, 3)
        let sorted = heap.sorted
        XCTAssertTrue(sorted.contains(10))
        XCTAssertTrue(sorted.contains(3))
        XCTAssertTrue(sorted.contains(2))
        XCTAssertFalse(sorted.contains(1))
        XCTAssertFalse(sorted.contains(0))
    }

    func testEmpty() {
        let heap = MinHeap<Int>(maxSize: 5)
        XCTAssertTrue(heap.isEmpty)
        XCTAssertEqual(heap.count, 0)
        XCTAssertEqual(heap.sorted, [])
    }
}
