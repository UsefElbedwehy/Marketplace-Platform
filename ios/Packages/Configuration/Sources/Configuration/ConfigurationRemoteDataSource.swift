import Networking

/// `GET /v1/config` / `GET /v1/theme` — public reads (guest-first browsing,
/// docs/planning/08-api-auth.md §Part B), so `requiresAuth: false`.
public struct ConfigurationRemoteDataSource: Sendable {
    private let apiClient: APIClient

    public init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    public func fetchConfig(ifNoneMatch: String?) async throws -> APIResponse<ConfigDTO> {
        try await apiClient.send(
            APIEndpoint(path: "/v1/config", requiresAuth: false, ifNoneMatch: ifNoneMatch),
            decodingTo: ConfigDTO.self
        )
    }

    public func fetchTheme(ifNoneMatch: String?) async throws -> APIResponse<ThemeDTO> {
        try await apiClient.send(
            APIEndpoint(path: "/v1/theme", requiresAuth: false, ifNoneMatch: ifNoneMatch),
            decodingTo: ThemeDTO.self
        )
    }
}
