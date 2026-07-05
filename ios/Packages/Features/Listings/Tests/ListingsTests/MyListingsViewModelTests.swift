import Testing
import DomainKit
@testable import Listings

@Suite @MainActor struct MyListingsViewModelTests {
    @Test func nonModeratorNeverFetchesTheModerationQueue() async {
        let useCase = RoleAwareStubListingUseCase(
            minePage: Page(items: [.fixture(status: .draft)], nextCursor: nil, hasMore: false),
            queuePage: Page(items: [.fixture(status: .pendingReview)], nextCursor: nil, hasMore: false)
        )
        let viewModel = MyListingsViewModel(listingUseCase: useCase, authUseCase: StubAuthUseCase(session: .fixture(appRole: "seller")))

        await viewModel.load()

        #expect(!viewModel.isModerator)
        #expect(viewModel.mine.count == 1)
        #expect(viewModel.moderationQueue.isEmpty)
    }

    @Test func moderatorFetchesBothMineAndTheQueueConcurrently() async {
        let useCase = RoleAwareStubListingUseCase(
            minePage: Page(items: [.fixture(id: "mine-1")], nextCursor: nil, hasMore: false),
            queuePage: Page(items: [.fixture(id: "queue-1", status: .pendingReview)], nextCursor: nil, hasMore: false)
        )
        let viewModel = MyListingsViewModel(listingUseCase: useCase, authUseCase: StubAuthUseCase(session: .fixture(appRole: "moderator")))

        await viewModel.load()

        #expect(viewModel.isModerator)
        #expect(viewModel.mine.map(\.id) == ["mine-1"])
        #expect(viewModel.moderationQueue.map(\.id) == ["queue-1"])
    }

    @Test func transitionCallsUpdateStatusAndReloads() async {
        let useCase = StubListingUseCase(page: Page(items: [.fixture(status: .published)], nextCursor: nil, hasMore: false))
        let viewModel = MyListingsViewModel(listingUseCase: useCase, authUseCase: StubAuthUseCase(session: .fixture(appRole: "seller")))
        await viewModel.load()

        await viewModel.transition(.fixture(id: "l1", status: .draft), to: .pendingReview)

        let calls = await useCase.updateStatusCalls
        #expect(calls.first?.id == "l1")
        #expect(calls.first?.status == .pendingReview)
    }

    @Test func ownerActionsMatchTheBackendStateMachine() {
        #expect(OwnerAction.actions(for: .draft) == [.submitForReview])
        #expect(OwnerAction.actions(for: .pendingReview) == [.withdraw])
        #expect(OwnerAction.actions(for: .published) == [.archive, .markSold])
        #expect(OwnerAction.actions(for: .rejected) == [.relist])
        #expect(OwnerAction.actions(for: .archived) == [.relist])
        #expect(OwnerAction.actions(for: .sold).isEmpty)
    }
}
