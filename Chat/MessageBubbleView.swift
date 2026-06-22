import SwiftUI

/// Renders a single chat message bubble with Liquid Glass styling.
struct MessageBubbleView: View {
    let message: Message
    let isStreaming: Bool

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 6) {
                // Role label with hierarchical SF Symbol
                HStack(spacing: 4) {
                    Image(systemName: message.role == .user ? "person.fill" : "cpu")
                        .font(.system(size: 10))
                        .symbolRenderingMode(.hierarchical)
                    Text(message.role == .user ? "You" : "Assistant")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(.secondary)

                // Message content
                if message.role == .assistant && isStreaming && message.content.isEmpty {
                    StreamingTextView(text: "", isStreaming: true)
                        .padding(12)
                        .glassBackground(cornerRadius: 14)
                } else if message.role == .assistant {
                    StreamingTextView(text: message.content, isStreaming: isStreaming)
                        .padding(12)
                        .glassBackground(cornerRadius: 14)
                        .textSelection(.enabled)
                } else {
                    Text(message.content)
                        .font(.body)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.userBubble)
                        )
                        .textSelection(.enabled)
                }

                // Usage badge for assistant messages with metrics
                if message.role == .assistant && (message.totalTokens > 0 || message.responseTimeMs > 0) {
                    UsageBadgeView(message: message)
                }

                // Timestamp
                Text(message.timestamp.shortFormatted)
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }

            if message.role == .assistant {
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal)
    }
}
