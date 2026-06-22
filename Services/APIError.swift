import Foundation

/// Errors that can occur when communicating with the NVIDIA API.
enum APIError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, message: String?)
    case decodingError(Error)
    case networkError(Error)
    case rateLimited(retryAfter: TimeInterval?)
    case streamError(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "NVIDIA API key is not set. Open Settings to add your key."
        case .invalidURL:
            return "The API URL is invalid."
        case .invalidResponse:
            return "Received an invalid response from the server."
        case .httpError(let statusCode, let message):
            let base = "HTTP \(statusCode)"
            if let message, !message.isEmpty {
                return "\(base): \(message)"
            }
            return base
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .rateLimited(let retryAfter):
            if let retryAfter {
                return "Rate limited. Retry after \(Int(retryAfter)) seconds."
            }
            return "Rate limited. Please try again later."
        case .streamError(let message):
            return "Streaming error: \(message)"
        }
    }
}
