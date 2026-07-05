public protocol SellerProfileRepository: Sendable {
    func fetchSellerProfile(id: String) async throws -> SellerProfile
}
