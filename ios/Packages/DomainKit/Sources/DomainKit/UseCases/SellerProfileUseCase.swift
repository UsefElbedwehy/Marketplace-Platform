public protocol SellerProfileUseCase: Sendable {
    func fetchSellerProfile(id: String) async throws -> SellerProfile
}

public struct DefaultSellerProfileUseCase: SellerProfileUseCase {
    private let sellerProfileRepository: SellerProfileRepository

    public init(sellerProfileRepository: SellerProfileRepository) {
        self.sellerProfileRepository = sellerProfileRepository
    }

    public func fetchSellerProfile(id: String) async throws -> SellerProfile {
        try await sellerProfileRepository.fetchSellerProfile(id: id)
    }
}
