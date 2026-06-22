import XCTest
@testable import NvidiaLLM

final class ModelsFetcherTests: XCTestCase {
    func testFetchModelsWithEmptyKey() async {
        let fetcher = ModelsFetcher()
        do {
            _ = try await fetcher.fetchModels(
                endpoint: "https://test.example.com/v1",
                apiKey: ""
            )
            XCTFail("Expected an error")
        } catch {
            // Expected — either invalidURL or network error.
            XCTAssertTrue(error is APIError || error is URLError)
        }
    }

    func testNvidiaModelDisplayName() {
        let model = NvidiaModel(id: "nvidia/llama-3.1-nemotron-70b-instruct", object: nil, created: nil, ownedBy: nil, contextLength: 131072)
        XCTAssertEqual(model.displayName, "Llama 3.1 Nemotron 70b Instruct")
    }

    func testNvidiaModelDisplayNameWithoutPrefix() {
        let model = NvidiaModel(id: "mistral-7b-instruct", object: nil, created: nil, ownedBy: nil, contextLength: nil)
        XCTAssertEqual(model.displayName, "Mistral 7b Instruct")
    }
}
