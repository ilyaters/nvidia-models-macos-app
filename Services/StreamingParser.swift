import Foundation

/// Parses a Server-Sent Events stream from the NVIDIA API into `SSEChunk` values.
///
/// The stream is a sequence of lines. Data lines begin with `data: `.
/// A `data: [DONE]` line signals the end of the stream.
/// The final data chunk (before `[DONE]`) typically contains the `usage` object
/// when `stream_options.include_usage` is set to `true`.
struct StreamingParser {
    private let decoder = JSONDecoder()

    /// Parses a single raw SSE line into a chunk, if applicable.
    /// Returns `nil` for non-data lines, comments, or `[DONE]`.
    func parse(line: String) -> SSEChunk? {
        // Trim leading/trailing whitespace.
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)

        // Skip empty lines and comments.
        guard trimmed.hasPrefix("data:") else { return nil }

        let payload = trimmed
            .dropFirst("data:".count)
            .trimmingCharacters(in: .whitespaces)

        // End-of-stream marker.
        if payload == "[DONE]" { return nil }

        guard let data = payload.data(using: .utf8) else { return nil }
        return try? decoder.decode(SSEChunk.self, from: data)
    }

    /// Extracts the text content delta from a chunk.
    func contentDelta(from chunk: SSEChunk) -> String? {
        chunk.choices?.first?.delta?.content
    }

    /// Extracts the usage object from a chunk (present in the final chunk).
    func usage(from chunk: SSEChunk) -> Usage? {
        chunk.usage
    }
}
