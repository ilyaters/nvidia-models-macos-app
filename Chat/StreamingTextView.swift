import SwiftUI

/// Renders text with a blinking cursor during streaming.
struct StreamingTextView: View {
    let text: String
    let isStreaming: Bool

    @State private var cursorVisible = true

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            Text(text.isEmpty && isStreaming ? "" : text)
                .font(.body)
                .textSelection(.enabled)

            if isStreaming {
                Rectangle()
                    .fill(Color.primary)
                    .frame(width: 2, height: 14)
                    .opacity(cursorVisible ? 1 : 0)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.5).repeatForever()) {
                            cursorVisible.toggle()
                        }
                    }
            }
        }
    }
}
