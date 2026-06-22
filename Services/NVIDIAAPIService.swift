import Foundation

/// HTTP client for the NVIDIA chat completions API.
///
/// Supports both streaming (SSE) and non-streaming modes.
/// In streaming mode, `stream_options.include_usage` is set to `true` so the
/// final chunk includes token counts.
///
/// Includes automatic retry with exponential backoff for rate-limited (429)
/// and transient network errors.
@MainActor
final class NVIDIAAPIService {
    private let session: URLSession
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let parser = StreamingParser()

    /// Maximum number of retry attempts for transient errors.
    private let maxRetries: Int

    /// Base delay for exponential backoff (seconds).
    private let baseRetryDelay: TimeInterval = 1.0

    /// Request timeout in seconds.
    private let requestTimeout: TimeInterval

    init(session: URLSession? = nil) {
        self.maxRetries = AppSettings.shared.maxRetries
        self.requestTimeout = TimeInterval(AppSettings.shared.requestTimeout)

        if let session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = TimeInterval(self.requestTimeout)
            config.timeoutIntervalForResource = TimeInterval(AppSettings.shared.resourceTimeout)
            config.waitsForConnectivity = true
            self.session = URLSession(configuration: config)
        }
    }

    // MARK: - Streaming

    /// Events emitted during a streaming chat completion.
    enum StreamEvent {
        /// A text content delta arrived.
        case delta(String)
        /// The stream completed with the final usage object.
        case complete(Usage?)
        /// An error occurred.
        case error(APIError)
    }

    /// Sends a streaming chat completion request.
    ///
    /// - Parameters:
    ///   - endpoint: Base API endpoint.
    ///   - apiKey: NVIDIA API key.
    ///   - model: Model id.
    ///   - messages: Conversation messages (including system prompt as first element).
    ///   - params: Sampling parameters.
    /// - Returns: An `AsyncStream` of `StreamEvent` values.
    nonisolated
    func streamChat(
        endpoint: String,
        apiKey: String,
        model: String,
        messages: [APIRequestMessage],
        params: SamplingParams
    ) -> AsyncStream<StreamEvent> {
        AsyncStream { [maxRetries, baseRetryDelay] continuation in
            Task {
                var attempt = 0

                retryLoop: while attempt <= maxRetries {
                    attempt += 1

                    do {
                        let request = try buildRequest(
                            endpoint: endpoint,
                            apiKey: apiKey,
                            model: model,
                            messages: messages,
                            params: params,
                            stream: true
                        )

                        let (bytes, response) = try await session.bytes(for: request)

                        guard let httpResponse = response as? HTTPURLResponse else {
                            continuation.yield(.error(.invalidResponse))
                            continuation.finish()
                            return
                        }

                        if httpResponse.statusCode == 429 {
                            let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                                .flatMap(TimeInterval.init)

                            if attempt <= maxRetries {
                                let delay = retryAfter ?? (baseRetryDelay * pow(2.0, Double(attempt - 1)))
                                continuation.yield(.error(.rateLimited(retryAfter: delay)))
                                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                                continue retryLoop
                            }

                            continuation.yield(.error(.rateLimited(retryAfter: retryAfter)))
                            continuation.finish()
                            return
                        }

                        guard (200...299).contains(httpResponse.statusCode) else {
                            let body: String?
                            do {
                                var data = Data()
                                for try await byte in bytes {
                                    data.append(byte)
                                }
                                body = String(data: data, encoding: .utf8)
                            } catch {
                                body = nil
                            }

                            // Retry on 5xx server errors.
                            if (500...599).contains(httpResponse.statusCode) && attempt <= maxRetries {
                                let delay = baseRetryDelay * pow(2.0, Double(attempt - 1))
                                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                                continue retryLoop
                            }

                            continuation.yield(.error(.httpError(statusCode: httpResponse.statusCode, message: body)))
                            continuation.finish()
                            return
                        }

                        var finalUsage: Usage?

                        for try await line in bytes.lines {
                            guard let chunk = parser.parse(line: line) else { continue }

                            if let delta = parser.contentDelta(from: chunk) {
                                continuation.yield(.delta(delta))
                            }

                            if let usage = parser.usage(from: chunk) {
                                finalUsage = usage
                            }
                        }

                        continuation.yield(.complete(finalUsage))
                        continuation.finish()
                        return

                    } catch let error as APIError {
                        continuation.yield(.error(error))
                        continuation.finish()
                        return
                    } catch {
                        // Retry on transient network errors.
                        let isTransient = (error as NSError).code == URLError.timedOut.rawValue
                            || (error as NSError).code == URLError.networkConnectionLost.rawValue
                            || (error as NSError).code == URLError.notConnectedToInternet.rawValue

                        if isTransient && attempt <= maxRetries {
                            let delay = baseRetryDelay * pow(2.0, Double(attempt - 1))
                            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                            continue retryLoop
                        }

                        continuation.yield(.error(.networkError(error)))
                        continuation.finish()
                        return
                    }
                }
            }
        }
    }

    // MARK: - Non-streaming

    /// Sends a non-streaming chat completion request with retry.
    func chat(
        endpoint: String,
        apiKey: String,
        model: String,
        messages: [APIRequestMessage],
        params: SamplingParams
    ) async throws -> ChatCompletionResponse {
        var attempt = 0

        while attempt <= maxRetries {
            attempt += 1

            do {
                let request = try buildRequest(
                    endpoint: endpoint,
                    apiKey: apiKey,
                    model: model,
                    messages: messages,
                    params: params,
                    stream: false
                )

                let (data, response) = try await session.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }

                if httpResponse.statusCode == 429 {
                    let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                        .flatMap(TimeInterval.init)

                    if attempt <= maxRetries {
                        let delay = retryAfter ?? (baseRetryDelay * pow(2.0, Double(attempt - 1)))
                        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        continue
                    }

                    throw APIError.rateLimited(retryAfter: retryAfter)
                }

                // Retry on 5xx server errors.
                if (500...599).contains(httpResponse.statusCode) && attempt <= maxRetries {
                    let delay = baseRetryDelay * pow(2.0, Double(attempt - 1))
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }

                guard (200...299).contains(httpResponse.statusCode) else {
                    throw APIError.httpError(
                        statusCode: httpResponse.statusCode,
                        message: String(data: data, encoding: .utf8)
                    )
                }

                do {
                    return try decoder.decode(ChatCompletionResponse.self, from: data)
                } catch {
                    throw APIError.decodingError(error)
                }
            } catch let error as APIError {
                throw error
            } catch {
                let isTransient = (error as NSError).code == URLError.timedOut.rawValue
                    || (error as NSError).code == URLError.networkConnectionLost.rawValue
                    || (error as NSError).code == URLError.notConnectedToInternet.rawValue

                if isTransient && attempt <= maxRetries {
                    let delay = baseRetryDelay * pow(2.0, Double(attempt - 1))
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }

                throw APIError.networkError(error)
            }
        }

        throw APIError.streamError("Max retries exceeded")
    }

    // MARK: - Private

    private nonisolated func buildRequest(
        endpoint: String,
        apiKey: String,
        model: String,
        messages: [APIRequestMessage],
        params: SamplingParams,
        stream: Bool
    ) throws -> URLRequest {
        guard !apiKey.isEmpty else { throw APIError.missingAPIKey }

        guard let url = URL(string: "\(endpoint)/chat/completions") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = self.requestTimeout

        let body = ChatCompletionRequest(
            model: model,
            messages: messages,
            temperature: params.temperature,
            topP: params.topP,
            maxTokens: params.maxTokens,
            presencePenalty: params.presencePenalty,
            frequencyPenalty: params.frequencyPenalty,
            stop: params.stop,
            seed: params.seed,
            stream: stream,
            streamOptions: stream ? StreamOptions(includeUsage: true) : nil,
            chatTemplateKwargs: params.thinkingMode.map { ["thinking_mode": $0 ? "on" : "off"] }
        )

        request.httpBody = try encoder.encode(body)
        return request
    }
}
