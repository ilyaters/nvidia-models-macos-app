import XCTest
@testable import NvidiaLLM

final class StreamingParserTests: XCTestCase {
    private let parser = StreamingParser()

    func testParseContentDelta() throws {
        let line = #"data: {"id":"chatcmpl-1","choices":[{"index":0,"delta":{"content":"Hello"}}]}"#
        let chunk = parser.parse(line: line)
        XCTAssertNotNil(chunk)
        XCTAssertEqual(parser.contentDelta(from: chunk!), "Hello")
    }

    func testParseUsageChunk() throws {
        let line = #"data: {"id":"chatcmpl-1","choices":[],"usage":{"prompt_tokens":10,"completion_tokens":20,"total_tokens":30}}"#
        let chunk = parser.parse(line: line)
        XCTAssertNotNil(chunk)
        let usage = parser.usage(from: chunk!)
        XCTAssertNotNil(usage)
        XCTAssertEqual(usage?.promptTokens, 10)
        XCTAssertEqual(usage?.completionTokens, 20)
        XCTAssertEqual(usage?.totalTokens, 30)
    }

    func testParseDoneMarker() {
        let chunk = parser.parse(line: "data: [DONE]")
        XCTAssertNil(chunk)
    }

    func testParseNonDataLine() {
        let chunk = parser.parse(line: ": comment")
        XCTAssertNil(chunk)
    }

    func testParseEmptyLine() {
        let chunk = parser.parse(line: "")
        XCTAssertNil(chunk)
    }

    func testParseInvalidJSON() {
        let chunk = parser.parse(line: "data: {invalid}")
        XCTAssertNil(chunk)
    }

    func testParseRoleDelta() throws {
        let line = #"data: {"choices":[{"delta":{"role":"assistant"}}]}"#
        let chunk = parser.parse(line: line)
        XCTAssertNotNil(chunk)
        XCTAssertEqual(chunk?.choices?.first?.delta?.role, "assistant")
    }
}
