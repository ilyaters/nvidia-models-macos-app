import Foundation

/// Searches the web via Google Custom Search JSON API for research mode.
final class GoogleSearchService: @unchecked Sendable {
    private let session: URLSession
    private let decoder = JSONDecoder()

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// A single search result.
    struct SearchResult: Identifiable, Codable {
        var id: String { link }
        let title: String
        let link: String
        let snippet: String?
    }

    /// Performs a Google Custom Search.
    /// - Parameters:
    ///   - query: Search query string.
    ///   - apiKey: Google Custom Search API key.
    ///   - searchEngineId: Custom Search Engine ID (CX).
    ///   - maxResults: Maximum number of results (1–10).
    /// - Returns: Array of search results.
    func search(
        query: String,
        apiKey: String,
        searchEngineId: String,
        maxResults: Int = 5
    ) async throws -> [SearchResult] {
        var components = URLComponents(string: "https://www.googleapis.com/customsearch/v1")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "cx", value: searchEngineId),
            URLQueryItem(name: "num", value: String(min(max(1, maxResults), 10)))
        ]

        guard let url = components.url else {
            throw APIError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode, message: String(data: data, encoding: .utf8))
        }

        let responseModel = try decoder.decode(GoogleSearchResponse.self, from: data)
        return responseModel.items ?? []
    }

    /// Formats search results as context text to inject into the prompt.
    func formatContext(results: [SearchResult]) -> String {
        guard !results.isEmpty else { return "" }

        let formatted = results.enumerated().map { index, result in
            "[\(index + 1)] \(result.title)\nURL: \(result.link)\n\(result.snippet ?? "")"
        }.joined(separator: "\n\n")

        return "Web search results:\n\n\(formatted)"
    }
}

private struct GoogleSearchResponse: Codable {
    let items: [GoogleSearchService.SearchResult]?
}
