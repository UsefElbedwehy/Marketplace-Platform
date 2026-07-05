import Foundation
import SwiftData

/// Wraps the SwiftData cache. An **actor** so the `ModelContext` it owns is
/// only ever touched from one isolation domain, regardless of how many
/// concurrent callers (boot, pull-to-refresh, background refresh) hit it.
public actor ConfigurationLocalDataSource {
    private let context: ModelContext

    public init(container: ModelContainer) {
        self.context = ModelContext(container)
    }

    public func loadConfig(clientId: String) -> (dto: ConfigDTO, etag: String?)? {
        var descriptor = FetchDescriptor<CachedConfigRecord>(predicate: #Predicate { $0.clientId == clientId })
        descriptor.fetchLimit = 1
        guard let record = try? context.fetch(descriptor).first else { return nil }
        guard let dto = try? JSONDecoder().decode(ConfigDTO.self, from: record.payload) else { return nil }
        return (dto, record.etag)
    }

    /// Keyed by the explicit `clientId` param, not `dto.clientId` — the cache
    /// key is "which client's config is this a cache entry for", independent
    /// of whatever the payload's own `clientId` field happens to say.
    public func saveConfig(_ dto: ConfigDTO, clientId: String, etag: String?) throws {
        let payload = try JSONEncoder().encode(dto)
        var descriptor = FetchDescriptor<CachedConfigRecord>(predicate: #Predicate { $0.clientId == clientId })
        descriptor.fetchLimit = 1
        if let existing = try context.fetch(descriptor).first {
            existing.payload = payload
            existing.etag = etag
            existing.fetchedAt = Date()
        } else {
            context.insert(CachedConfigRecord(clientId: clientId, payload: payload, etag: etag, fetchedAt: Date()))
        }
        try context.save()
    }

    public func loadTheme(clientId: String) -> (dto: ThemeDTO, etag: String?)? {
        var descriptor = FetchDescriptor<CachedThemeRecord>(predicate: #Predicate { $0.clientId == clientId })
        descriptor.fetchLimit = 1
        guard let record = try? context.fetch(descriptor).first else { return nil }
        guard let dto = try? JSONDecoder().decode(ThemeDTO.self, from: record.payload) else { return nil }
        return (dto, record.etag)
    }

    public func saveTheme(_ dto: ThemeDTO, clientId: String, etag: String?) throws {
        let payload = try JSONEncoder().encode(dto)
        var descriptor = FetchDescriptor<CachedThemeRecord>(predicate: #Predicate { $0.clientId == clientId })
        descriptor.fetchLimit = 1
        if let existing = try context.fetch(descriptor).first {
            existing.payload = payload
            existing.etag = etag
            existing.fetchedAt = Date()
        } else {
            context.insert(CachedThemeRecord(clientId: clientId, payload: payload, etag: etag, fetchedAt: Date()))
        }
        try context.save()
    }
}
