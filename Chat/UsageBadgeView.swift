import SwiftUI

/// Compact badge showing token counts, response time, and tokens/sec
/// for an assistant message. Uses Liquid Glass capsule background.
struct UsageBadgeView: View {
    let message: Message
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: "speedometer")
                    .font(.system(size: 9))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)

                if message.totalTokens > 0 {
                    Label("\(message.totalTokens)", systemImage: "text.alignleft")
                        .labelStyle(.titleAndIcon)
                        .symbolRenderingMode(.hierarchical)
                }

                if message.outputTokens > 0 {
                    Text("↑\(message.inputTokens) ↓\(message.outputTokens)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                if message.responseTimeMs > 0 {
                    Text(formatTime(message.responseTimeMs))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                if isExpanded && message.outputTokens > 0 && message.responseTimeMs > 0 {
                    let tps = Double(message.outputTokens) / (message.responseTimeMs / 1000)
                    Text(String(format: "%.1f tok/s", tps))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                if message.outputTokens > 0 || message.responseTimeMs > 0 {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 8))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.tertiary)
                        .onTapGesture { isExpanded.toggle() }
                }
            }
            .font(.system(size: 10))
            .foregroundStyle(.secondary)

            if isExpanded {
                Divider()
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Input tokens").font(.system(size: 9)).foregroundStyle(.tertiary)
                        Text("\(message.inputTokens)").font(.system(size: 11, design: .monospaced))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Output tokens").font(.system(size: 9)).foregroundStyle(.tertiary)
                        Text("\(message.outputTokens)").font(.system(size: 11, design: .monospaced))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Total").font(.system(size: 9)).foregroundStyle(.tertiary)
                        Text("\(message.totalTokens)").font(.system(size: 11, design: .monospaced))
                    }
                    if let model = message.modelId {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Model").font(.system(size: 9)).foregroundStyle(.tertiary)
                            Text(model).font(.system(size: 10, design: .monospaced)).lineLimit(1)
                        }
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .glassCapsuleBackground()
    }

    private func formatTime(_ ms: Double) -> String {
        if ms < 1000 {
            return String(format: "%.0fms", ms)
        } else {
            return String(format: "%.1fs", ms / 1000)
        }
    }
}
