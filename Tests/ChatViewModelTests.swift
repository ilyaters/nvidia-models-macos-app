import XCTest
import SwiftData
@testable import NvidiaLLM

@MainActor
final class ChatViewModelTests: XCTestCase {
    private var container: ModelContainer!

    override func setUp() async throws {
        container = try ModelContainer(
            for: Conversation.self, Message.self, UsageRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    func testCreateNewConversation() {
        let viewModel = ChatViewModel()
        viewModel.configure(modelContext: container.mainContext)

        let initialCount = viewModel.conversations.count
        viewModel.createNewConversation(modelContext: container.mainContext)

        XCTAssertEqual(viewModel.conversations.count, initialCount + 1)
        XCTAssertNotNil(viewModel.currentConversation)
    }

    func testDeleteConversation() {
        let viewModel = ChatViewModel()
        viewModel.configure(modelContext: container.mainContext)

        viewModel.createNewConversation(modelContext: container.mainContext)
        let conversation = viewModel.currentConversation!
        let countAfterCreate = viewModel.conversations.count

        viewModel.deleteConversation(conversation, modelContext: container.mainContext)

        XCTAssertEqual(viewModel.conversations.count, countAfterCreate - 1)
        XCTAssertFalse(viewModel.conversations.contains { $0.id == conversation.id })
    }

    func testRenameConversation() {
        let viewModel = ChatViewModel()
        viewModel.configure(modelContext: container.mainContext)

        viewModel.createNewConversation(modelContext: container.mainContext)
        let conversation = viewModel.currentConversation!

        viewModel.renameConversation(conversation, to: "Renamed Chat", modelContext: container.mainContext)

        XCTAssertEqual(conversation.title, "Renamed Chat")
    }

    func testSendMessageWithoutAPIKey() async {
        let viewModel = ChatViewModel()
        viewModel.configure(modelContext: container.mainContext)
        viewModel.createNewConversation(modelContext: container.mainContext)

        // Ensure no API key is set.
        KeychainManager.delete("nvidia_api_key")
        viewModel.loadAPIKey()

        viewModel.inputText = "Hello"
        await viewModel.sendMessage(modelContext: container.mainContext)

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("API key") == true)
    }

    func testContextEstimationUpdates() {
        let viewModel = ChatViewModel()
        viewModel.configure(modelContext: container.mainContext)
        viewModel.createNewConversation(modelContext: container.mainContext)

        // Add a message to the conversation.
        let conversation = viewModel.currentConversation!
        let message = Message(role: .user, content: "This is a test message for context estimation.")
        message.conversation = conversation
        container.mainContext.insert(message)

        viewModel.updateContextEstimation()

        XCTAssertGreaterThan(viewModel.estimatedContextTokens, 0)
    }
}
