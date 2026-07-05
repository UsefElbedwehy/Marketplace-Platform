import Testing
@testable import Configuration

@Test func localDataSourceRoundTripsAConfigByClientId() async throws {
    let local = ConfigurationLocalDataSource(container: try .configurationCache(inMemory: true))
    try await local.saveConfig(.fixture(), clientId: "client_a", etag: "\"v1\"")

    let loaded = await local.loadConfig(clientId: "client_a")

    #expect(loaded?.etag == "\"v1\"")
    #expect(loaded?.dto.clientId == "default")
}

@Test func localDataSourceKeepsDifferentClientsSeparate() async throws {
    let local = ConfigurationLocalDataSource(container: try .configurationCache(inMemory: true))
    try await local.saveConfig(.fixture(), clientId: "client_a", etag: nil)

    let loaded = await local.loadConfig(clientId: "client_b")

    #expect(loaded == nil)
}

@Test func localDataSourceSaveOverwritesThePreviousEntryForTheSameClient() async throws {
    let local = ConfigurationLocalDataSource(container: try .configurationCache(inMemory: true))
    try await local.saveConfig(.fixture(), clientId: "client_a", etag: "\"v1\"")
    try await local.saveConfig(.fixture(), clientId: "client_a", etag: "\"v2\"")

    let loaded = await local.loadConfig(clientId: "client_a")

    #expect(loaded?.etag == "\"v2\"")
}

@Test func localDataSourceRoundTripsATheme() async throws {
    let local = ConfigurationLocalDataSource(container: try .configurationCache(inMemory: true))
    try await local.saveTheme(.fixture(themeVersion: 3), clientId: "client_a", etag: "\"t1\"")

    let loaded = await local.loadTheme(clientId: "client_a")

    #expect(loaded?.dto.themeVersion == 3)
}
