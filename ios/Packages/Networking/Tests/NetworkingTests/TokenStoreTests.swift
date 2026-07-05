import Testing
import Foundation
@testable import Networking

@Test func tokenStoreRoundTripsASession() async throws {
    let store = TokenStore(service: "test.\(UUID())")
    let session = StoredSession(accessToken: "abc", sub: "u1", tenantId: "t1", appRole: "buyer", displayName: "Buyer")

    try await store.save(session)

    #expect(await store.load() == session)
}

@Test func tokenStoreLoadIsNilBeforeAnySave() async {
    let store = TokenStore(service: "test.\(UUID())")
    #expect(await store.load() == nil)
}

@Test func tokenStoreClearRemovesTheSession() async throws {
    let store = TokenStore(service: "test.\(UUID())")
    try await store.save(StoredSession(accessToken: "abc", sub: "u1", tenantId: "t1", appRole: "buyer", displayName: "Buyer"))

    await store.clear()

    #expect(await store.load() == nil)
}

@Test func tokenStoreSaveOverwritesAPreviousSession() async throws {
    let store = TokenStore(service: "test.\(UUID())")
    try await store.save(StoredSession(accessToken: "first", sub: "u1", tenantId: "t1", appRole: "buyer", displayName: "Buyer"))
    try await store.save(StoredSession(accessToken: "second", sub: "u1", tenantId: "t1", appRole: "buyer", displayName: "Buyer"))

    #expect(await store.load()?.accessToken == "second")
}
