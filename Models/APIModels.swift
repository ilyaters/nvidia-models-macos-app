import Foundation

// MARK: - Request

/// A single message in the chat completions request body.
struct APIRequestMessage: Codable {
    let role: String
    let content: String
}

/// Top-level request body for `POST /v1/chat/completions`.
struct ChatCompletionRequest: Codable {
    let model: String
    let messages: [APIRequestMessage]
    let temperature: Double?
    let topP: Double?
    let maxTokens: Int?
    let presencePenalty: Double?
    let frequencyPenalty: Double?
    let stop: [String]?
    let seed: Int?
    let stream: Bool
    let streamOptions: StreamOptions?
    let chatTemplateKwargs: [String: String]?

    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case topP = "top_p"
        case maxTokens = "max_tokens"
        case presencePenalty = "presence_penalty"
        case frequencyPenalty = "frequency_penalty"
        case stop, seed, stream
        case streamOptions = "stream_options"
        case chatTemplateKwargs = "chat_template_kwargs"
    }
}

/// Options controlling streaming behaviour.
struct StreamOptions: Codable {
    /// When true, the final SSE chunk includes a `usage` object with token counts.
    let includeUsage: Bool

    enum CodingKeys: String, CodingKey {
        case includeUsage = "include_usage"
    }
}

// MARK: - Response (non-streaming)

/// Non-streaming chat completion response.
struct ChatCompletionResponse: Codable {
    let id: String?
    let model: String?
    let choices: [Choice]
    let usage: Usage?
}

struct Choice: Codable {
    let index: Int?
    let message: ResponseMessage
    let finishReason: String?

    enum CodingKeys: String, CodingKey {
        case index, message
        case finishReason = "finish_reason"
    }
}

struct ResponseMessage: Codable {
    let role: String
    let content: String?
}

/// Token usage returned by the API (in non-streaming responses and the final SSE chunk).
struct Usage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int

    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}
