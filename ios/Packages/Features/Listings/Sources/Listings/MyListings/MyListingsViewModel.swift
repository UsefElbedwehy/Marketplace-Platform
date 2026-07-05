import Core
import DomainKit
import Observation

/// Transitions a caller with no special privilege can make on their own
/// listing — mirrors `dashboard/src/app/listings/page.tsx`'s `OWNER_ACTIONS`.
enum OwnerAction: String, CaseIterable {
    case submitForReview = "Submit for review"
    case withdraw = "Withdraw"
    case archive = "Archive"
    case markSold = "Mark sold"
    case relist = "Relist"

    var target: ListingStatus {
        switch self {
        case .submitForReview: return .pendingReview
        case .withdraw, .relist: return .draft
        case .archive: return .archived
        case .markSold: return .sold
        }
    }

    static func actions(for status: ListingStatus) -> [OwnerAction] {
        switch status {
        case .draft: return [.submitForReview]
        case .pendingReview: return [.withdraw]
        case .published: return [.archive, .markSold]
        case .rejected: return [.relist]
        case .archived: return [.relist]
        case .sold: return []
        }
    }
}

@Observable
@MainActor
final class MyListingsViewModel {
    private(set) var mine: [Listing] = []
    private(set) var moderationQueue: [Listing] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var busyListingId: String?
    private(set) var isModerator = false

    private static let moderatorRoles: Set<String> = ["moderator", "admin", "super_admin"]

    private let listingUseCase: ListingUseCase
    private let authUseCase: AuthUseCase

    init(listingUseCase: ListingUseCase = Container.shared.listingUseCase(), authUseCase: AuthUseCase = Container.shared.authUseCase()) {
        self.listingUseCase = listingUseCase
        self.authUseCase = authUseCase
    }

    /// Resolves the caller's moderator standing itself (rather than taking
    /// it as an init parameter derived from an async `.task` in the host
    /// view) — a value SwiftUI captures into `@State`'s `initialValue` at
    /// first render can never update later, so a boolean computed
    /// asynchronously by the caller would permanently freeze at its initial
    /// (usually `false`) value. Re-resolving on every `load()` keeps it
    /// correct across sign-in/sign-out without relying on view identity.
    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let session = await authUseCase.currentSession()
            isModerator = session.map { Self.moderatorRoles.contains($0.appRole) } ?? false
            async let mineTask = listingUseCase.fetchListings(filters: ListingFilters(mine: true))
            async let queueTask = fetchModerationQueueIfNeeded()
            let (minePage, queuePage) = try await (mineTask, queueTask)
            mine = minePage.items
            moderationQueue = queuePage.items
        } catch {
            errorMessage = (error as? DomainError)?.errorDescription ?? "\(error)"
        }
    }

    private func fetchModerationQueueIfNeeded() async throws -> Page<Listing> {
        guard isModerator else { return Page(items: [], nextCursor: nil, hasMore: false) }
        return try await listingUseCase.fetchListings(filters: ListingFilters(status: .pendingReview))
    }

    func transition(_ listing: Listing, to status: ListingStatus) async {
        busyListingId = listing.id
        defer { busyListingId = nil }
        do {
            _ = try await listingUseCase.updateStatus(listingId: listing.id, status: status)
            await load()
        } catch {
            errorMessage = (error as? DomainError)?.errorDescription ?? "\(error)"
        }
    }
}
