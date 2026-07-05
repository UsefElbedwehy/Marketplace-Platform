import Testing
import Foundation
import Core
import Networking
import DomainKit
@testable import DataKit

struct FakeDevAuthClient: APIClient {
    var accessToken: String = "minted-token"
    var error: Error?

    func send<T: Decodable & Sendable>(_ endpoint: APIEndpoint, decodingTo type: T.Type) async throws -> APIResponse<T> {
        if let error { throw error }
        let response = DevAuthResponse(accessToken: accessToken)
        return APIResponse(value: (response as! T), etag: nil, notModified: false)
    }

    func sendCollection<T: Decodable & Sendable>(_ endpoint: APIEndpoint, decodingItemsTo type: T.Type) async throws -> (items: [T], page: PaginationMeta) {
        fatalError("not used by DataKit's auth tests")
    }

    func sendNoContent(_ endpoint: APIEndpoint) async throws {
        fatalError("not used by DataKit's auth tests")
    }
}

@Test func authRepositorySignInPersistsAndReturnsTheSession() async throws {
    let tokenStore = TokenStore(service: "datakit-test.\(UUID())")
    let repo = AuthRepositoryImpl(apiClient: FakeDevAuthClient(accessToken: "abc123"), tokenStore: tokenStore, tenantId: "t1")
    let identity = DevIdentity(sub: "u1", appRole: "admin", displayName: "Dev Admin")

    let session = try await repo.signIn(as: identity)

    #expect(session.accessToken == "abc123")
    #expect(session.appRole == "admin")
    let persisted = await repo.currentSession()
    #expect(persisted?.accessToken == "abc123")
}

@Test func authRepositoryCurrentSessionIsNilBeforeSignIn() async {
    let tokenStore = TokenStore(service: "datakit-test.\(UUID())")
    let repo = AuthRepositoryImpl(apiClient: FakeDevAuthClient(), tokenStore: tokenStore, tenantId: "t1")

    #expect(await repo.currentSession() == nil)
}

@Test func authRepositorySignOutClearsTheSession() async throws {
    let tokenStore = TokenStore(service: "datakit-test.\(UUID())")
    let repo = AuthRepositoryImpl(apiClient: FakeDevAuthClient(), tokenStore: tokenStore, tenantId: "t1")
    _ = try await repo.signIn(as: DevIdentity(sub: "u1", appRole: "buyer", displayName: "Dev Buyer"))

    await repo.signOut()

    #expect(await repo.currentSession() == nil)
}

@Test func authRepositorySignInMapsAnUnexpectedFailureToDomainNetworkError() async {
    struct Boom: Error {}
    let tokenStore = TokenStore(service: "datakit-test.\(UUID())")
    let repo = AuthRepositoryImpl(apiClient: FakeDevAuthClient(error: Boom()), tokenStore: tokenStore, tenantId: "t1")

    await #expect(throws: DomainError.network) {
        try await repo.signIn(as: DevIdentity(sub: "u1", appRole: "buyer", displayName: "Dev Buyer"))
    }
}

@Test func authRepositorySignInPropagatesADomainErrorAsIs() async {
    let tokenStore = TokenStore(service: "datakit-test.\(UUID())")
    let repo = AuthRepositoryImpl(apiClient: FakeDevAuthClient(error: DomainError.forbidden), tokenStore: tokenStore, tenantId: "t1")

    await #expect(throws: DomainError.forbidden) {
        try await repo.signIn(as: DevIdentity(sub: "u1", appRole: "buyer", displayName: "Dev Buyer"))
    }
}
