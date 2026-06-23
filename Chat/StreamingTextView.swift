import SwiftUI
import MarkdownUI

/// Renders text with a blinking cursor during streaming.
///
/// While streaming, shows plain text with cursor (markdown can't render
/// incomplete markup). When streaming completes, renders full markdown.
/// Optimized to minimize re-renders during streaming.
struct StreamingTextView: View {
    let text: String
    let isStreaming: Bool

    @State private var cursorVisible = true

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            if isStreaming {
                // During streaming: plain text with cursor.
                // Using Text(verbatim:) to avoid markdown parsing overhead
                // during rapid streaming updates.
                Text(verbatim: text.isEmpty ? "" : text)
                    .font(.body)
                    .textSelection(.enabled)

                Rectangle()
                    .fill(Color.primary)
                    .frame(width: 2, height: 14)
                    .opacity(cursorVisible ? 1 : 0)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                            cursorVisible = false
                        }
                    }
            } else {
                // When complete: render full markdown.
                Markdown(text)
                    .markdownTheme(.basic)
                    .textSelection(.enabled)
            }
        }
    }
}
