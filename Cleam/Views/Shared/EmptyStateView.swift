import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    var action: (() -> Void)?
    var actionLabel: LocalizedStringKey?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.title2)
                .fontWeight(.medium)

            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)

            if let action = action, let label = actionLabel {
                Button(label, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ConfirmationDialog: View {
    let title: String
    let message: String
    let items: [(String, String)]
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)

            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)

            if !items.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(items, id: \.0) { item in
                            HStack {
                                Text(item.0)
                                    .font(.caption)
                                    .lineLimit(1)
                                Spacer()
                                Text(item.1)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .frame(maxHeight: 200)
            }

            HStack {
                Spacer()
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Button("Confirm", action: onConfirm)
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
            }
        }
        .padding(20)
        .frame(width: 450)
    }
}
