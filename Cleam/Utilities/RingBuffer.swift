import Foundation

struct RingBuffer<T> {
    private var storage: [T]
    private var writeIndex: Int = 0
    private let capacity: Int
    private var count: Int = 0

    init(capacity: Int, defaultValue: T) {
        self.capacity = capacity
        self.storage = Array(repeating: defaultValue, count: capacity)
    }

    mutating func append(_ element: T) {
        storage[writeIndex] = element
        writeIndex = (writeIndex + 1) % capacity
        if count < capacity { count += 1 }
    }

    var elements: [T] {
        if count < capacity {
            return Array(storage[0..<count])
        }
        return Array(storage[writeIndex..<capacity]) + Array(storage[0..<writeIndex])
    }

    var latest: T? {
        guard count > 0 else { return nil }
        let index = (writeIndex - 1 + capacity) % capacity
        return storage[index]
    }

    var isEmpty: Bool { count == 0 }
    var isFull: Bool { count == capacity }
    var currentCount: Int { count }
}
