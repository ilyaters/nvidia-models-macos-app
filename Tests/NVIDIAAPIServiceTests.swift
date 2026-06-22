import XCTest
@testable import NvidiaLLM

final class NVIDIAAPIServiceTests: XCTestCase {
    func testMissingAPIKeyThrows() async {
        let service = NVIDIAAPIService()
        let messages = [APIRequestMessage(role: "user", content: "Hello")]
        let params = SamplingParams.defaults

        do {
            _ = try await service.chat(
                endpoint: "https://test.example.com/v1",
                apiKey: "",
                model: "test-model",
                messages: messages,
                params: params
            )
            XCTFail("Expected missingAPIKey error")
        } catch let error as APIError {
            switch error {
            case .missingAPIKey:
                break // expected
            default:
                XCTFail("Expected missingAPIKey, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testInvalidURLThrows() async {
        let service = NVIDIAAPIService()
        let messages = [APIRequestMessage(role: "user", content: "Hello")]
        let params = SamplingParams.defaults

        do {
            _ = try await service.chat(
                endpoint: "not a url",
                apiKey: "test-key",
                model: "test-model",
                messages: messages,
                params: params
            )
            XCTFail("Expected invalidURL error")
        } catch let error as APIError {
            switch error {
            case .invalidURL:
                break // expected
            default:
                XCTFail("Expected invalidURL, got \(error)")
            }
        } catch {
            // Other errors are acceptable since the URL is malformed.
        }
    }

    func testStreamChatReturnsEvents() async {
        let service = NVIDIAAPIService()
        let messages = [APIRequestMessage(role: "user", content: "Hello")]
        let params = SamplingParams.defaults

        // This will fail to connect, but should produce an error event.
        let stream = service.streamChat(
            endpoint: "https://invalid.example.com/v1",
            apiKey: "test-key",
            model: "test-model",
            messages: messages,
            params: params
        )

        var receivedError = false
        for await event in stream {
            if case .error = event {
                receivedError = true
            }
        }

        XCTAssertTrue(receivedError, "Expected an error event from invalid endpoint")
    }
}
