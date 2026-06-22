import Foundation
import Observation

/// Status of a model health check.
enum ModelHealthStatus: Equatable {
    case unknown
    case checking
    case available
    case unavailable(String)
    case noApiKey

    /// SF Symbol icon name for the status indicator.
    var icon: String {
        switch self {
        case .unknown: "questionmark.circle"
        case .checking: "arrow.triangle.2.circlepath"
        case .available: "checkmark.circle.fill"
        case .unavailable: "xmark.circle.fill"
        case .noApiKey: "lock.circle"
        }
    }

    /// Color for the status indicator.
    var color: String {
        switch self {
        case .unknown: "secondary"
        case .checking: "blue"
        case .available: "green"
        case .unavailable: "red"
        case .noApiKey: "orange"
        }
    }

    /// Human-readable label.
    var label: String {
        switch self {
        case .unknown: "Unknown"
        case .checking: "Checking…"
        case .available: "Available"
        case .unavailable(let msg): "Unavailable: \(msg)"
        case .noApiKey: "No API key"
        }
    }
}

/// Sends a lightweight health-check request to verify that a model is
/// accessible with the current API key.
///
/// The check sends a minimal 1-token request (`max_tokens: 1`) and
/// inspects the HTTP status code. A 200 response means the model is
/// available; a 401/403 means the key is invalid; a 404 means the
/// model id is wrong; a 429 means rate-limited but the model exists.
@MainActor
@Observable
final class HealthCheckService {
    private let session: URLSession
    private let encoder = JSONEncoder()

    /// Cached status per model id.
    private(set) var statuses: [String: ModelHealthStatus] = [:]

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Performs a health check for the given model.
    func check(model: String, endpoint: String, apiKey: String) async {
        guard !apiKey.isEmpty {
            statuses[model] = .noApiKey
            return
        }

        statuses[model] = .checking

        guard let url = URL(string: "\(endpoint)/chat/completions") else {
            statuses[model] = .unavailable("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15

        // Minimal request — 1 token, cheapest possible.
        let body: [String: Any] = [
            "model": model,
            "messages": [["role": "user", "content": "Hi"]],
            "max_tokens": 1,
            "stream": false
        ]

        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else {
            statuses[model] = .unavailable("Request error")
            return
        }
        request.httpBody = bodyData

        do {
            let (_, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                statuses[model] = .unavailable("Invalid response")
                return
            }

            switch httpResponse.statusCode {
            case 200...299:
                statuses[model] = .available
            case 401, 403:
                statuses[model] = .unavailable("Auth failed")
            case 404:
                statuses[model] = .unavailable("Model not found")
            case 429:
                // Rate-limited but the model exists and key is valid.
                statuses[model] = .available
            default:
                statuses[model] = .unavailable("HTTP \(httpResponse.statusCode)")
            }
        } catch {
            statuses[model] = .unavailable("Network error")
        }
    }

    /// Returns the cached status for a model, or `.unknown`.
    func status(for model: String) -> ModelHealthStatus {
        statuses[model] ?? .unknown
    }

    /// Clears all cached statuses.
    func clear() {
        statuses.removeAll()
    }
}
