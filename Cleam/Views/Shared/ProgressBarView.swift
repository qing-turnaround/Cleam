import SwiftUI

struct ProgressBarView: View {
    let value: Double
    var maxValue: Double = 100
    var height: CGFloat = 8
    var showLabel: Bool = false

    private var fraction: Double {
        guard maxValue > 0 else { return 0 }
        return min(value / maxValue, 1.0)
    }

    private var percentage: Double {
        fraction * 100
    }

    var body: some View {
        HStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(Color.secondary.opacity(0.15))
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(Color.sizeColor(percentage: percentage))
                        .frame(width: max(geo.size.width * fraction, 0))
                }
            }
            .frame(height: height)

            if showLabel {
                Text(String(format: "%.0f%%", percentage))
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(width: 36, alignment: .trailing)
            }
        }
    }
}

struct SizeLabel: View {
    let bytes: UInt64

    var body: some View {
        Text(ByteFormatter.format(bytes))
            .monospacedDigit()
            .foregroundStyle(.secondary)
    }
}
