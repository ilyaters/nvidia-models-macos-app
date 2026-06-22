import Foundation

/// A single Server-Sent Events chunk parsed from the streaming response.
struct SSEChunk: Codable {
    let id: String?
    let model: String?
    let choices: [StreamChoice]?
    /// Present only in the final chunk when `stream_options.include_usage` is true.
    let usage: Usage?
}

struct StreamChoice: Codable {
    let index: Int?
    let delta: Delta?
    let finishReason: String?

    enum CodingKeys: String, CodingKey {
        case index, delta
        case finishReason = "finish_reason"
    }
}

struct Delta: Codable {
    let role: String?
    let content: String?
}
