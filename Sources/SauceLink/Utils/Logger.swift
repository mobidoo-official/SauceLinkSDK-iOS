import Foundation

/// 로그 레벨
enum LogLevel: String {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
}

/// SDK 내부 로거
/// 디버그 빌드에서만 로그 출력
enum Logger {
    
    /// 로깅 활성화 여부 (기본값: DEBUG 빌드에서만 true)
    static var isEnabled: Bool = {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()
    
    /// 로그 태그
    private static let tag = "[SauceLinkTracker]"
    
    /// Debug 레벨 로그
    static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .debug, message: message, file: file, function: function, line: line)
    }
    
    /// Info 레벨 로그
    static func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .info, message: message, file: file, function: function, line: line)
    }
    
    /// Warning 레벨 로그
    static func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .warning, message: message, file: file, function: function, line: line)
    }
    
    /// Error 레벨 로그
    static func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .error, message: message, file: file, function: function, line: line)
    }
    
    /// 로그 출력
    private static func log(level: LogLevel, message: String, file: String, function: String, line: Int) {
        guard isEnabled else { return }
        
        let fileName = (file as NSString).lastPathComponent
        let timestamp = ISO8601DateFormatter().string(from: Date())
        
        print("\(timestamp) \(tag) [\(level.rawValue)] [\(fileName):\(line)] \(function) - \(message)")
    }
}

