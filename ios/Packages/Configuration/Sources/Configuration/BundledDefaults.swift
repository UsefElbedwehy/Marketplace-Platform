import Foundation

/// The build-time fallback (docs/planning/02-ios-architecture.md §4 scope:
/// "Configuration (build-time + runtime + SwiftData cache)") — used only when
/// there is neither a cache entry nor network reachability (e.g. first launch,
/// offline). Ships in the package's resource bundle, generated from the same
/// `configs/clients/default/{config,theme}.json` the backend seeds from, so
/// the two never drift silently.
public enum BundledDefaults {
    public static func config() throws -> ConfigDTO {
        try decode("default-config", as: ConfigDTO.self)
    }

    public static func theme() throws -> ThemeDTO {
        try decode("default-theme", as: ThemeDTO.self)
    }

    private static func decode<T: Decodable>(_ resource: String, as type: T.Type) throws -> T {
        guard let url = Bundle.module.url(forResource: resource, withExtension: "json") else {
            throw ConfigurationError.missingBundledResource(resource)
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(T.self, from: data)
    }
}

public enum ConfigurationError: Error, Equatable {
    case missingBundledResource(String)
}
