import Core

/// The cache-then-network policy for config/theme (ADR-0013's table row:
/// "cache-then-network, version-gated... on config version bump"). Combines
/// `ConfigurationLocalDataSource` (SwiftData) + `ConfigurationRemoteDataSource`
/// (network) + `BundledDefaults` (build-time fallback) into the single object
/// `DataKit`'s repositories and `DesignSystem`'s theme loader both call.
public final class ConfigurationDataSource: Sendable {
    private let local: ConfigurationLocalDataSource
    private let remote: ConfigurationRemoteDataSource
    private let clientId: String
    private let logger: AppLogger

    public init(local: ConfigurationLocalDataSource, remote: ConfigurationRemoteDataSource, clientId: String = "default", logger: AppLogger = OSAppLogger.shared) {
        self.local = local
        self.remote = remote
        self.clientId = clientId
        self.logger = logger
    }

    public func loadConfig() async throws -> ConfigDTO {
        let cached = await local.loadConfig(clientId: clientId)
        do {
            let response = try await remote.fetchConfig(ifNoneMatch: cached?.etag)
            if response.notModified, let cached { return cached.dto }
            if let value = response.value {
                try? await local.saveConfig(value, clientId: clientId, etag: response.etag)
                return value
            }
            return try cached?.dto ?? BundledDefaults.config()
        } catch {
            if let cached { return cached.dto }
            logger.warning("Config fetch failed with no cache; falling back to the bundled default: \(error)", category: "configuration")
            return try BundledDefaults.config()
        }
    }

    public func loadTheme() async throws -> ThemeDTO {
        let cached = await local.loadTheme(clientId: clientId)
        do {
            let response = try await remote.fetchTheme(ifNoneMatch: cached?.etag)
            if response.notModified, let cached { return cached.dto }
            if let value = response.value {
                try? await local.saveTheme(value, clientId: clientId, etag: response.etag)
                return value
            }
            return try cached?.dto ?? BundledDefaults.theme()
        } catch {
            if let cached { return cached.dto }
            logger.warning("Theme fetch failed with no cache; falling back to the bundled default: \(error)", category: "configuration")
            return try BundledDefaults.theme()
        }
    }
}
