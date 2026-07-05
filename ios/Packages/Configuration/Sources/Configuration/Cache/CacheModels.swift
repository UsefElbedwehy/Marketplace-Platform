import Foundation
import SwiftData

/// SwiftData is an **offline read cache, never a source of truth** (ADR-0013)
/// — so these models store the raw decoded-JSON payload plus just enough
/// metadata (ETag, fetch time) to drive cache-then-network + invalidation,
/// rather than decomposing every config/theme field into `@Model` properties.
@Model
public final class CachedConfigRecord {
    @Attribute(.unique) public var clientId: String
    public var payload: Data
    public var etag: String?
    public var fetchedAt: Date

    public init(clientId: String, payload: Data, etag: String?, fetchedAt: Date) {
        self.clientId = clientId
        self.payload = payload
        self.etag = etag
        self.fetchedAt = fetchedAt
    }
}

@Model
public final class CachedThemeRecord {
    @Attribute(.unique) public var clientId: String
    public var payload: Data
    public var etag: String?
    public var fetchedAt: Date

    public init(clientId: String, payload: Data, etag: String?, fetchedAt: Date) {
        self.clientId = clientId
        self.payload = payload
        self.etag = etag
        self.fetchedAt = fetchedAt
    }
}

extension ModelContainer {
    /// The single container the app's Configuration cache lives in — a
    /// dedicated on-disk store when `inMemory` is false (production), or an
    /// isolated in-memory store per test (`inMemory: true`) so tests never
    /// touch a shared file or leak state between runs.
    public static func configurationCache(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([CachedConfigRecord.self, CachedThemeRecord.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
