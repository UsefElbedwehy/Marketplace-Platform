import Testing
import DomainKit
@testable import Chat

@Suite @MainActor struct ConversationListViewModelTests {
    @Test func loadFetchesConversationsAndTheCurrentSession() async {
        let viewModel = ConversationListViewModel(
            chatUseCase: StubChatUseCase(conversations: [.fixture()]),
            authUseCase: StubAuthUseCase(session: .fixture(sub: "buyer-1"))
        )

        await viewModel.load()

        #expect(viewModel.conversations == [.fixture()])
        #expect(viewModel.currentUserId == "buyer-1")
    }

    @Test func otherPartyDisplayNameResolvesRelativeToTheCurrentUser() async {
        let viewModel = ConversationListViewModel(
            chatUseCase: StubChatUseCase(conversations: [.fixture()]),
            authUseCase: StubAuthUseCase(session: .fixture(sub: "seller-1"))
        )
        await viewModel.load()

        #expect(viewModel.otherPartyDisplayName(for: .fixture()) == "Dev Buyer")
    }

    @Test func loadSurfacesAnErrorMessage() async {
        struct Boom: Error {}
        let viewModel = ConversationListViewModel(chatUseCase: StubChatUseCase(error: Boom()), authUseCase: StubAuthUseCase())

        await viewModel.load()

        #expect(viewModel.errorMessage != nil)
    }
}
