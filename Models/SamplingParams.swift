import Foundation

/// Sampling parameters for NVIDIA chat completions API.
/// Mirrors the OpenAI-compatible parameters accepted by `integrate.api.nvidia.com`.
struct SamplingParams: Codable, Hashable {
    var temperature: Double?
    var topP: Double?
    var maxTokens: Int?
    var presencePenalty: Double?
    var frequencyPenalty: Double?
    var stop: [String]?
    var seed: Int?
    var thinkingMode: Bool?

    enum CodingKeys: String, CodingKey {
        case temperature
        case topP = "top_p"
        case maxTokens = "max_tokens"
        case presencePenalty = "presence_penalty"
        case frequencyPenalty = "frequency_penalty"
        case stop
        case seed
    }

    /// Default parameters used for new conversations.
    static let defaults = SamplingParams(
        temperature: 0.7,
        topP: 0.95,
        maxTokens: 1024,
        presencePenalty: 0,
        frequencyPenalty: 0,
        stop: nil,
        seed: nil,
        thinkingMode: false
    )
}
