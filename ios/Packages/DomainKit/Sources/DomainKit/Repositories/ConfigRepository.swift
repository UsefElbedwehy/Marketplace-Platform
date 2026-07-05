import Core

/// Fulfilled in `DataKit` by wrapping `Configuration`'s cache-then-network
/// data source and mapping its DTO onto `AppConfiguration`
/// (docs/planning/02-ios-architecture.md §1 flow: RI -.implements.-> RP).
/// Throws only `DomainError` by convention (not enforced via typed throws, to
/// keep call sites simple) — `DataKit` implementations never let a raw
/// networking/decoding error escape this boundary.
public protocol ConfigRepository: Sendable {
    func fetchConfiguration() async throws -> AppConfiguration
}
