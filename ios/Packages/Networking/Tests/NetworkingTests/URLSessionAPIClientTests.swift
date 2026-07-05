import Testing
import Foundation
import Core
@testable import Networking

struct Greeting: Decodable, Sendable, Equatable {
    let message: String
}

@Suite(.serialized)
struct URLSessionAPIClientTests {
    func makeClient(tokenStore: TokenStore, onSessionExpired: (@Sendable () async -> Void)? = nil) -> URLSessionAPIClient {
        URLSessionAPIClient(
            baseURL: URL(string: "https://example.test")!,
            session: StubURLProtocol.session,
            tokenStore: tokenStore,
            onSessionExpired: onSessionExpired
        )
    }

    @Test func decodesTheSuccessEnvelopeIntoTheExpectedType() async throws {
        StubURLProtocol.stub = .init(status: 200, headers: [:], body: #"{"data":{"message":"hi"}}"#.data(using: .utf8)!)
        let client = makeClient(tokenStore: TokenStore(service: "test.\(UUID())"))

        let result: Greeting = try await client.send(APIEndpoint(path: "/v1/greeting", requiresAuth: false), decodingTo: Greeting.self)

        #expect(result.message == "hi")
    }

    @Test func injectsTheBearerTokenWhenAnAuthenticatedEndpointHasASession() async throws {
        let store = TokenStore(service: "test.\(UUID())")
        try await store.save(StoredSession(accessToken: "secret-token", sub: "u1", tenantId: "t1", appRole: "buyer", displayName: "Buyer"))
        StubURLProtocol.stub = .init(status: 200, headers: [:], body: #"{"data":{"message":"hi"}}"#.data(using: .utf8)!)
        let client = makeClient(tokenStore: store)

        let _: Greeting = try await client.send(APIEndpoint(path: "/v1/greeting"), decodingTo: Greeting.self)

        #expect(StubURLProtocol.lastRequest?.value(forHTTPHeaderField: "authorization") == "Bearer secret-token")
    }

    @Test func doesNotInjectABearerTokenWhenTheEndpointDoesNotRequireAuth() async throws {
        let store = TokenStore(service: "test.\(UUID())")
        try await store.save(StoredSession(accessToken: "secret-token", sub: "u1", tenantId: "t1", appRole: "buyer", displayName: "Buyer"))
        StubURLProtocol.stub = .init(status: 200, headers: [:], body: #"{"data":{"message":"hi"}}"#.data(using: .utf8)!)
        let client = makeClient(tokenStore: store)

        let _: Greeting = try await client.send(APIEndpoint(path: "/v1/greeting", requiresAuth: false), decodingTo: Greeting.self)

        #expect(StubURLProtocol.lastRequest?.value(forHTTPHeaderField: "authorization") == nil)
    }

    @Test func mapsA403ToForbidden() async throws {
        StubURLProtocol.stub = .init(status: 403, headers: [:], body: #"{"error":{"code":"forbidden","message":"nope"}}"#.data(using: .utf8)!)
        let client = makeClient(tokenStore: TokenStore(service: "test.\(UUID())"))

        await #expect(throws: DomainError.forbidden) {
            let _: Greeting = try await client.send(APIEndpoint(path: "/v1/greeting", requiresAuth: false), decodingTo: Greeting.self)
        }
    }

    @Test func mapsA422WithFieldsToValidation() async throws {
        let body = #"{"error":{"code":"validation_failed","message":"bad","fields":[{"field":"mileage","code":"max","message":"too high"}]}}"#
        StubURLProtocol.stub = .init(status: 422, headers: [:], body: body.data(using: .utf8)!)
        let client = makeClient(tokenStore: TokenStore(service: "test.\(UUID())"))

        await #expect(throws: DomainError.validation([FieldError(field: "mileage", code: "max", message: "too high")])) {
            let _: Greeting = try await client.send(APIEndpoint(path: "/v1/greeting", requiresAuth: false), decodingTo: Greeting.self)
        }
    }

    @Test func aNotModifiedResponseSurfacesAsNilValueNotAThrow() async throws {
        StubURLProtocol.stub = .init(status: 304, headers: ["ETag": "\"v3\""], body: Data())
        let client = makeClient(tokenStore: TokenStore(service: "test.\(UUID())"))

        let response: APIResponse<Greeting> = try await client.send(
            APIEndpoint(path: "/v1/greeting", requiresAuth: false, ifNoneMatch: "\"v3\""),
            decodingTo: Greeting.self
        )

        #expect(response.notModified == true)
        #expect(response.value == nil)
        #expect(response.etag == "\"v3\"")
    }

    @Test func a401TriggersTheSessionExpiredHook() async throws {
        StubURLProtocol.stub = .init(status: 401, headers: [:], body: #"{"error":{"code":"unauthorized","message":"nope"}}"#.data(using: .utf8)!)
        let expired = Counter()
        let client = makeClient(tokenStore: TokenStore(service: "test.\(UUID())")) { await expired.increment() }

        _ = try? await client.send(APIEndpoint(path: "/v1/greeting"), decodingTo: Greeting.self) as Greeting

        #expect(await expired.count == 1)
    }

    @Test func sendCollectionDecodesBothTheItemsAndTheSiblingPageObject() async throws {
        let body = #"{"data":[{"message":"a"},{"message":"b"}],"page":{"nextCursor":"cursor-1","hasMore":true}}"#
        StubURLProtocol.stub = .init(status: 200, headers: [:], body: body.data(using: .utf8)!)
        let client = makeClient(tokenStore: TokenStore(service: "test.\(UUID())"))

        let (items, page) = try await client.sendCollection(APIEndpoint(path: "/v1/things", requiresAuth: false), decodingItemsTo: Greeting.self)

        #expect(items.map(\.message) == ["a", "b"])
        #expect(page.nextCursor == "cursor-1")
        #expect(page.hasMore == true)
    }

    @Test func sendCollectionWithNoMorePagesHasANilCursor() async throws {
        let body = #"{"data":[],"page":{"nextCursor":null,"hasMore":false}}"#
        StubURLProtocol.stub = .init(status: 200, headers: [:], body: body.data(using: .utf8)!)
        let client = makeClient(tokenStore: TokenStore(service: "test.\(UUID())"))

        let (items, page) = try await client.sendCollection(APIEndpoint(path: "/v1/things", requiresAuth: false), decodingItemsTo: Greeting.self)

        #expect(items.isEmpty)
        #expect(page.nextCursor == nil)
        #expect(page.hasMore == false)
    }
}

actor Counter {
    private(set) var count = 0
    func increment() { count += 1 }
}
