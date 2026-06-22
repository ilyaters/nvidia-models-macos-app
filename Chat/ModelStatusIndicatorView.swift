import SwiftUI

/// Compact indicator showing whether the selected model is available.
///
/// Displays a colored SF Symbol with the model status in a Liquid Glass
/// capsule. Clicking triggers a health check.
struct ModelStatusIndicatorView: View {
    let modelId: String
    let status: ModelHealthStatus
    let onCheck: () -> Void

    @State private var rotation: Double = 0

    var body: some View {
        Button(action: onCheck) {
            HStack(spacing: 4) {
                Image(systemName: status.icon)
                    .font(.system(size: 10))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(statusColor)
                    .rotationEffect(.degrees(status == .checking ? rotation : 0))
                    .animation(
                        status == .checking
                            ? .linear(duration: 1).repeatForever(autoreverses: false)
                            : .default,
                        value: status == .checking
                    )
                    .onChange(of: status == .checking) { _, isChecking in
                        if isChecking { rotation = 360 } else { rotation = 0 }
                    }

                Text(status.label)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .glassCapsuleBackground()
        }
        .buttonStyle(.plain)
        .help(status == .available
              ? "Model is available. Click to re-check."
              : "Click to check model availability.")
        .disabled(status == .checking)
    }

    private var statusColor: Color {
        switch status {
        case .unknown: .secondary
        case .checking: .blue
        case .available: .green
        case .unavailable: .red
        case .noApiKey: .orange
        }
    }
}
