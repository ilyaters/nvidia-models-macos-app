import Foundation

/// Fetches the list of available models from the NVIDIA API.
final class ModelsFetcher {
    private let session: URLSession
    private let decoder = JSONDecoder()

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Fetches all available models.
    /// - Parameters:
    ///   - endpoint: Base API endpoint (e.g. `https://integrate.api.nvidia.com/v1`).
    ///   - apiKey: NVIDIA API key.
    /// - Returns: Array of `NvidiaModel`, sorted alphabetically by id.
    func fetchModels(endpoint: String, apiKey: String) async throws -> [NvidiaModel] {
        guard let url = URL(string: "\(endpoint)/models") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode, message: String(data: data, encoding: .utf8))
        }

        let modelsResponse = try decoder.decode(ModelsResponse.self, from: data)
        return modelsResponse.data.sorted { $0.id < $1.id }
    }
}
