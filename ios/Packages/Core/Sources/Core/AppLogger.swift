import Foundation
import os

public enum LogLevel: Sendable {
    case debug, info, warning, error
}

/// A protocol (not a concrete `os.Logger` call site) so every module logs
/// through `Core` and call sites stay testable — a test can inject a
/// `AppLogger` that records calls instead of writing to the system log.
public protocol AppLogger: Sendable {
    func log(_ level: LogLevel, _ message: String, category: String)
}

extension AppLogger {
    public func debug(_ message: String, category: String = "app") { log(.debug, message, category: category) }
    public func info(_ message: String, category: String = "app") { log(.info, message, category: category) }
    public func warning(_ message: String, category: String = "app") { log(.warning, message, category: category) }
    public func error(_ message: String, category: String = "app") { log(.error, message, category: category) }
}

/// The production logger: one `os.Logger` per category, lazily created and
/// cached so repeated calls for the same category don't re-allocate one.
public final class OSAppLogger: AppLogger {
    public static let shared = OSAppLogger()

    private let subsystem: String
    private let loggers = OSAllocatedUnfairLock<[String: Logger]>(initialState: [:])

    public init(subsystem: String = "com.marketplaceplatform.app") {
        self.subsystem = subsystem
    }

    public func log(_ level: LogLevel, _ message: String, category: String) {
        let logger = loggers.withLock { cache -> Logger in
            if let existing = cache[category] { return existing }
            let created = Logger(subsystem: subsystem, category: category)
            cache[category] = created
            return created
        }
        switch level {
        case .debug: logger.debug("\(message, privacy: .public)")
        case .info: logger.info("\(message, privacy: .public)")
        case .warning: logger.warning("\(message, privacy: .public)")
        case .error: logger.error("\(message, privacy: .public)")
        }
    }
}
