import Testing
import SwiftData
@testable import Configuration

@Suite struct ConfigurationDataSourceTests {
    func makeLocal() throws -> ConfigurationLocalDataSource {
        ConfigurationLocalDataSource(container: try .configurationCache(inMemory: true))
    }

    @Test func loadConfigSavesAFreshNetworkResponseToTheCache() async throws {
        let local = try makeLocal()
        let remote = ConfigurationRemoteDataSource(apiClient: FakeAPIClient(behavior: .value(ConfigDTO.fixture(clientId: "client_a"))))
        let dataSource = ConfigurationDataSource(local: local, remote: remote)

        let config = try await dataSource.loadConfig()

        #expect(config.clientId == "client_a")
        let cached = await local.loadConfig(clientId: "default")
        #expect(cached?.dto.clientId == "client_a")
    }

    @Test func loadConfigReturnsCacheOn304() async throws {
        let local = try makeLocal()
        try await local.saveConfig(.fixture(clientId: "cached-client"), clientId: "default", etag: "\"etag-1\"")
        let remote = ConfigurationRemoteDataSource(apiClient: FakeAPIClient(behavior: .notModified))
        let dataSource = ConfigurationDataSource(local: local, remote: remote)

        let config = try await dataSource.loadConfig()

        #expect(config.clientId == "cached-client")
    }

    @Test func loadConfigFallsBackToCacheWhenTheNetworkFails() async throws {
        struct Boom: Error {}
        let local = try makeLocal()
        try await local.saveConfig(.fixture(clientId: "cached-client"), clientId: "default", etag: nil)
        let remote = ConfigurationRemoteDataSource(apiClient: FakeAPIClient(behavior: .throwing(Boom())))
        let dataSource = ConfigurationDataSource(local: local, remote: remote)

        let config = try await dataSource.loadConfig()

        #expect(config.clientId == "cached-client")
    }

    @Test func loadConfigFallsBackToTheBundledDefaultWithNoCacheAndNoNetwork() async throws {
        struct Boom: Error {}
        let local = try makeLocal()
        let remote = ConfigurationRemoteDataSource(apiClient: FakeAPIClient(behavior: .throwing(Boom())))
        let dataSource = ConfigurationDataSource(local: local, remote: remote)

        let config = try await dataSource.loadConfig()

        #expect(config.clientId == "default")
    }

    @Test func loadThemeSavesAFreshNetworkResponseToTheCache() async throws {
        let local = try makeLocal()
        let remote = ConfigurationRemoteDataSource(apiClient: FakeAPIClient(behavior: .value(ThemeDTO.fixture(themeVersion: 7))))
        let dataSource = ConfigurationDataSource(local: local, remote: remote)

        let theme = try await dataSource.loadTheme()

        #expect(theme.themeVersion == 7)
        let cached = await local.loadTheme(clientId: "default")
        #expect(cached?.dto.themeVersion == 7)
    }
}
