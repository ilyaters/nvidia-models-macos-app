import SwiftUI

/// Shows the estimated context window usage and warns when approaching the limit.
/// Uses hierarchical SF Symbols and Liquid Glass capsule background.
struct ContextIndicatorView: View {
    let estimatedTokens: Int
    let contextLimit: Int?
    let isApproachingLimit: Bool

    var body: some View {
        if let contextLimit, contextLimit > 0 {
            let usage = min(1.0, Double(estimatedTokens) / Double(contextLimit))

            HStack(spacing: 6) {
                Image(systemName: isApproachingLimit ? "exclamationmark.triangle.fill" : "text.alignleft")
                    .font(.system(size: 10))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(isApproachingLimit ? .orange : .secondary)

                Text("\(estimatedTokens) / \(contextLimit)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(isApproachingLimit ? .orange : .secondary)

                ProgressView(value: usage)
                    .progressViewStyle(.linear)
                    .frame(width: 80)
                    .tint(usage < 0.6 ? .green : (usage < 0.8 ? .yellow : .red))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .glassCapsuleBackground()
            .help("Estimated context usage: \(Int(usage * 100))% of \(contextLimit) tokens")
        } else {
            HStack(spacing: 6) {
                Image(systemName: "text.alignleft")
                    .font(.system(size: 10))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
                Text("~\(estimatedTokens) tokens")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .glassCapsuleBackground()
        }
    }
}
