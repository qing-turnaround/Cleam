import Foundation

struct MinHeap<T: Comparable> {
    private var elements: [T] = []
    let maxSize: Int

    init(maxSize: Int) {
        self.maxSize = maxSize
    }

    var count: Int { elements.count }
    var isEmpty: Bool { elements.isEmpty }

    var sorted: [T] {
        elements.sorted(by: >)
    }

    mutating func insert(_ element: T) {
        if elements.count < maxSize {
            elements.append(element)
            siftUp(elements.count - 1)
        } else if let min = elements.first, element > min {
            elements[0] = element
            siftDown(0)
        }
    }

    private mutating func siftUp(_ index: Int) {
        var child = index
        while child > 0 {
            let parent = (child - 1) / 2
            if elements[child] < elements[parent] {
                elements.swapAt(child, parent)
                child = parent
            } else {
                break
            }
        }
    }

    private mutating func siftDown(_ index: Int) {
        var parent = index
        let count = elements.count
        while true {
            let left = 2 * parent + 1
            let right = 2 * parent + 2
            var smallest = parent
            if left < count && elements[left] < elements[smallest] {
                smallest = left
            }
            if right < count && elements[right] < elements[smallest] {
                smallest = right
            }
            if smallest == parent { break }
            elements.swapAt(parent, smallest)
            parent = smallest
        }
    }
}
