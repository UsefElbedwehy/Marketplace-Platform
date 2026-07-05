import Testing
import DomainKit
@testable import Chat

@Suite @MainActor struct MessageThreadViewModelTests {
    @Test func loadFetchesMessagesAndTheCurrentSession() async {
        let viewModel = MessageThreadViewModel(
            chatUseCase: StubChatUseCase(messages: [.fixture(id: "m1"), .fixture(id: "m2")]),
            authUseCase: StubAuthUseCase(session: .fixture(sub: "buyer-1"))
        )

        await viewModel.load(conversationId: "c1")

        #expect(viewModel.messages.count == 2)
        #expect(viewModel.currentUserId == "buyer-1")
    }

    @Test func isFromCurrentUserComparesSenderIdAgainstTheSession() async {
        let viewModel = MessageThreadViewModel(chatUseCase: StubChatUseCase(), authUseCase: StubAuthUseCase(session: .fixture(sub: "buyer-1")))
        await viewModel.load(conversationId: "c1")

        #expect(viewModel.isFromCurrentUser(.fixture(senderId: "buyer-1")))
        #expect(!viewModel.isFromCurrentUser(.fixture(senderId: "seller-1")))
    }

    @Test func sendAppendsTheReturnedMessageAndClearsTheDraft() async {
        let useCase = StubChatUseCase(sentMessage: .fixture(id: "new-m", body: "hello"))
        let viewModel = MessageThreadViewModel(chatUseCase: useCase, authUseCase: StubAuthUseCase())
        viewModel.draftBody = "hello"

        await viewModel.send(conversationId: "c1")

        #expect(viewModel.messages.last?.body == "hello")
        #expect(viewModel.draftBody.isEmpty)
    }

    @Test func sendIgnoresAWhitespaceOnlyDraft() async {
        let viewModel = MessageThreadViewModel(chatUseCase: StubChatUseCase(), authUseCase: StubAuthUseCase())
        viewModel.draftBody = "   "

        await viewModel.send(conversationId: "c1")

        #expect(viewModel.messages.isEmpty)
    }
}
