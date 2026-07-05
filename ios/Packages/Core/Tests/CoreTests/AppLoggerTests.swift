import Testing
@testable import Core

final class RecordingLogger: AppLogger, @unchecked Sendable {
    private(set) var entries: [(LogLevel, String, String)] = []

    func log(_ level: LogLevel, _ message: String, category: String) {
        entries.append((level, message, category))
    }
}

@Test func loggerConvenienceMethodsForwardTheRightLevel() {
    let logger = RecordingLogger()
    logger.debug("d")
    logger.info("i")
    logger.warning("w")
    logger.error("e", category: "custom")

    #expect(logger.entries.map(\.0) == [.debug, .info, .warning, .error])
    #expect(logger.entries.last?.2 == "custom")
    #expect(logger.entries.first?.2 == "app")
}
