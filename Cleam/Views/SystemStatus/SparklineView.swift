import SwiftUI

struct SparklineView: View {
    let data: [Double]
    var color: Color = .blue
    var height: CGFloat = 30

    private var normalizedData: [Double] {
        guard let maxVal = data.max(), maxVal > 0 else { return data.map { _ in 0.0 } }
        return data.map { $0 / maxVal }
    }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let stepX = data.count > 1 ? width / CGFloat(data.count - 1) : width
            let normalized = normalizedData

            Path { path in
                guard normalized.count > 1 else { return }
                let firstY = height - (normalized[0] * height)
                path.move(to: CGPoint(x: 0, y: firstY))

                for i in 1..<normalized.count {
                    let x = CGFloat(i) * stepX
                    let y = height - (normalized[i] * height)
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(color, lineWidth: 1.5)

            Path { path in
                guard normalized.count > 1 else { return }
                let firstY = height - (normalized[0] * height)
                path.move(to: CGPoint(x: 0, y: height))
                path.addLine(to: CGPoint(x: 0, y: firstY))

                for i in 1..<normalized.count {
                    let x = CGFloat(i) * stepX
                    let y = height - (normalized[i] * height)
                    path.addLine(to: CGPoint(x: x, y: y))
                }
                path.addLine(to: CGPoint(x: CGFloat(normalized.count - 1) * stepX, y: height))
                path.closeSubpath()
            }
            .fill(color.opacity(0.1))
        }
        .frame(height: height)
    }
}
