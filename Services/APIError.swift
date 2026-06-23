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

    /// Full detailed error text including status codes, response bodies, and
    /// underlying error descriptions. Used for copying to clipboard.
    var detailedDescription: String {
        switch self {
        case .missingAPIKey:
            return """
            Error: Missing API Key
            
            The NVIDIA API key is not set. 
            Open Settings → API to add your key, or set a per-chat API key.
            """
        case .invalidURL:
            return """
            Error: Invalid URL
            
            The API endpoint URL is malformed. Check Settings → API → Endpoint.
            """
        case .invalidResponse:
            return """
            Error: Invalid Response
            
            The server returned a response that could not be parsed as HTTP.
            """
        case .httpError(let statusCode, let message):
            return """
            Error: HTTP \(statusCode)
            
            Response body:
            \(message ?? "(empty)")
            """
        case .decodingError(let error):
            return """
            Error: Decoding Failed
            
            \(error)
            
            Localized: \(error.localizedDescription)
            """
        case .networkError(let error):
            let nsError = error as NSError
            return """
            Error: Network Error
            
            \(error.localizedDescription)
            
            Domain: \(nsError.domain)
            Code: \(nsError.code)
            UserInfo: \(nsError.userInfo)
            """
        case .rateLimited(let retryAfter):
            return """
            Error: Rate Limited (HTTP 429)
            
            Retry after: \(retryAfter.map { "\(Int($0)) seconds" } ?? "unknown")
            """
        case .streamError(let message):
            return """
            Error: Streaming Error
            
            \(message)
            """
        }
    }
}
