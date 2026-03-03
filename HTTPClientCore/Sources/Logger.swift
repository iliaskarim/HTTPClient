import Foundation

#if canImport(OSLog)
import OSLog
#endif

public final class Logger: Sendable {
  public enum LogLevel: String, Comparable, Sendable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
      lhs.priority < rhs.priority
    }

    case none, error, info, debug, trace

    private var priority: Int {
      switch self {
      case .none: 0

      case .error: 1

      case .info: 2

      case .debug: 3

      case .trace: 4
      }
    }
  }

  public static let shared = Logger()

  public let logLevel: LogLevel

#if canImport(OSLog)
  private let osLogger = os.Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "org.iliaskarim.HTTPClient",
    category: "network"
  )
#endif

  public func logError(_ error: Error) {
    guard logLevel > .none else {
      return
    }

    switch error {
    case let urlError as URLError:
      logErrorMessage("Transport error: \(urlError.localizedDescription)")

    case is HTTPError:
      break // already logged in logResponse

    default:
      logErrorMessage("Unexpected error: \(error.localizedDescription)")
    }
  }

  public func logRequest(_ request: LoggableRequest, httpBody: Data?) {
    guard logLevel > .error else {
      return
    }

    // INFO: log request line.
    print("\(request.method) \(request.url)")

    // TRACE: log request headers.
    if case .trace = logLevel {
      print(request.headerPairs.prettyPrintedHeadersString(prefix: ">"))
    }

    // DEBUG: log request body.
    guard let httpBody, logLevel >= .debug else {
      return
    }

    print(httpBody.prettyPrintedString)
  }

  public func logResponse(_ response: LoggableResponse, data: Data, for request: LoggableRequest) {
    guard logLevel > .none else {
      return
    }

    // INFO: log response status code and URL.
    // ERROR: log response line if the status code is non-2xx.
    if !response.isOK {
      logErrorMessage("\(response.statusCode) \(request.method) \(request.url)")
    } else if logLevel > .error {
      print("\(response.statusCode) \(request.method) \(request.url)")
    }

    // TRACE: log response headers.
    if case .trace = logLevel {
      print(response.headerPairs.prettyPrintedHeadersString(prefix: "<"))
    }

    // DEBUG: log response body.
    guard logLevel >= .debug, !data.isEmpty else {
      return
    }

    print(data.prettyPrintedString)
  }

  private init() {
    logLevel = (ProcessInfo.processInfo.environment["LOG_LEVEL"]
      ?? Bundle.main.object(forInfoDictionaryKey: "LOG_LEVEL") as? String)
      .flatMap { LogLevel(rawValue: $0.lowercased()) } ?? .none
  }

  private func logErrorMessage(_ message: String) {
#if canImport(OSLog)
    osLogger.error("\(message, privacy: .public)")
#else
    let data = Data((message + "\n").utf8)
    try? FileHandle.standardError.write(contentsOf: data)
#endif
  }
}

private extension [(String, String)] {
  func prettyPrintedHeadersString(prefix: String) -> String {
    sorted {
      let lhsFolded = $0.0.lowercased()
      let rhsFolded = $1.0.lowercased()
      return lhsFolded == rhsFolded ? $0.0 < $1.0 : lhsFolded < rhsFolded
    }
    .map { key, value in "\(prefix) \(key): \(value)" }
    .joined(separator: "\n")
  }
}
