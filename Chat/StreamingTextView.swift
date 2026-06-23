import SwiftUI
import MarkdownUI

/// Renders text with a blinking cursor during streaming.
///
/// While streaming, shows plain text (markdown can't render incomplete markup).
/// When streaming completes, renders full markdown via MarkdownUI.
struct StreamingTextView: View {
    let text: String
    let isStreaming: Bool

    @State private var cursorVisible = true

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            if isStreaming {
                // During streaming: plain text with cursor (markdown can't
                // render partial/incomplete markup reliably).
                Text(text.isEmpty ? "" : text)
                    .font(.body)
                    .textSelection(.enabled)

                Rectangle()
                    .fill(Color.primary)
                    .frame(width: 2, height: 14)
                    .opacity(cursorVisible ? 1 : 0)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.5).repeatForever()) {
                            cursorVisible.toggle()
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
