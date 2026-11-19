import Foundation
#if canImport(OSLog)
import OSLog
#endif

/// 카테고리별 로거. 금액·메모·바코드 값 등 개인정보는 로그에 남기지 않는다 (SECURITY_POLICY.md §4.4).
public enum Log {
    public enum Category: String, Sendable {
        case app, ui, data, sync, auth
    }

    public static func debug(_ message: String, category: Category = .app) {
        write(message, category: category, level: "DEBUG")
    }

    public static func info(_ message: String, category: Category = .app) {
        write(message, category: category, level: "INFO")
    }

    public static func error(_ message: String, category: Category = .app) {
        write(message, category: category, level: "ERROR")
    }

    private static func write(_ message: String, category: Category, level: String) {
        #if canImport(OSLog)
        let logger = Logger(subsystem: "app.dokkaebiwallet.ios", category: category.rawValue)
        switch level {
        case "ERROR": logger.error("\(message, privacy: .public)")
        case "DEBUG": logger.debug("\(message, privacy: .public)")
        default: logger.info("\(message, privacy: .public)")
        }
        #else
        FileHandle.standardError.write(Data("[\(level)][\(category.rawValue)] \(message)\n".utf8))
        #endif
    }
}
