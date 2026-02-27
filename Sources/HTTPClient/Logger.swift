import Foundation
import OSLog

/// Central logger used throughout the HTTP client.
///
/// The logger supports multiple verbosity levels controlled by the
/// `LOG_LEVEL` environment variable or Info.plist entry. It emits human-
/// readable output to `stdout` for development/debugging and forwards
/// error-level messages to ``os.Logger`` so they appear in Console.app.
final class Logger: Sendable {
  /// Verbosity level for the logger.
  ///
  /// Levels are ordered from least verbose (`none`) to most verbose (`trace`).
  /// The comparison operators are used internally to decide which details to
  /// emit when logging requests, responses, and bodies.
  private enum LogLevel: String, Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
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

  /// Shared singleton instance used by the public API.
  static let shared = Logger()

  /// Current log level; controls how much information gets printed.
  private let logLevel: LogLevel

  /// ``os.Logger`` used for error messages so they integrate with the unified
  /// logging system and respect system privacy controls.
  private let osLogger = os.Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "org.iliaskarim.HTTPClient",
    category: "network"
  )

  /// Log an error-level event.
  ///
  /// Most errors are forwarded to the underlying ``os.Logger``; transport
  /// errors get a customized message and HTTP errors are intentionally ignored
  /// here because they are handled by ``logResponse(_:data:for:)``.
  ///
  /// - Parameter error: The error to log.
  func logError(_ error: Error) {
    guard logLevel > .none else {
      return
    }

    switch error {
    case let urlError as URLError:
      osLogger.error("Transport error: \(urlError.localizedDescription)")

    case is HTTPError:
      break // already logged in logResponse

    default:
      osLogger.error("Unexpected error: \(error.localizedDescription)")
    }
  }

  /// Emit details about the given ``URLRequest``.
  ///
  /// - Error level: no request details are emitted
  /// - Info level: method and URL
  /// - Debug level: HTTP body (if present and can be converted to string)
  /// - Trace level: headers
  ///
  /// - Parameter request: The request to log.
  func logRequest(_ request: URLRequest) {
    guard logLevel > .error else {
      return
    }

    // INFO: log request line.
    print("\(request.httpMethod!) \(request)")

    // TRACE: log request headers.
    if case .trace = logLevel {
      print(request.headerPairs.prettyPrintedHeadersString(prefix: ">"))
    }

    // DEBUG: log request body.
    guard let httpBody = request.httpBody, logLevel >= .debug else {
      return
    }

    print(httpBody.prettyPrintedString)
  }

  /// Emit details about the given ``HTTPURLResponse``.
  ///
  /// - Error level: non-2xx status codes are forwarded to ``os.Logger``
  /// - Info level: status code and URL
  /// - Debug level: response body when non-empty
  /// - Trace level: response headers
  ///
  /// - Parameters:
  ///   - response: The response to log.
  ///   - data: The response body data.
  ///   - request: The original request associated with the response.
  func logResponse(_ response: HTTPURLResponse, data: Data, for request: URLRequest) {
    guard logLevel > .none else {
      return
    }

    // INFO: log response status code and URL.
    // ERROR: log response line if the status code is non-2xx.
    if !response.isOK {
      osLogger.error("\(response.statusCode, privacy: .public) \(request, privacy: .public)")
    } else if logLevel > .error {
      print("\(response.statusCode) \(request)")
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

  /// Private initializer; reads the desired log level from the environment or
  /// Info.plist so the behaviour is configurable without recompiling.
  private init() {
    logLevel = (ProcessInfo.processInfo.environment["LOG_LEVEL"]
      ?? Bundle.main.object(forInfoDictionaryKey: "LOG_LEVEL") as? String)
      .flatMap { LogLevel(rawValue: $0.lowercased()) } ?? .none
  }
}

private extension [(String, String)] {
  /// Return the headers as a single formatted string.
  ///
  /// Headers are sorted case-insensitively and each line is prefixed with the
  /// given string.
  ///
  /// - Parameter prefix: The string to prepend to each header line.
  /// - Returns: A newline-separated string containing all headers.
  func prettyPrintedHeadersString(prefix: String) -> String {
    sorted { $0.0.lowercased() < $1.0.lowercased() }
      .map { key, value in "\(prefix) \(key): \(value)" }
      .joined(separator: "\n")
  }
}

private extension Data {
  /// Attempt to format the data as pretty‑printed JSON, falling back to a
  /// UTF‑8 string or a placeholder if that fails. Used when logging bodies.
  ///
  /// - Returns: A formatted string representation of the data.
  var prettyPrintedString: String {
    (try? JSONSerialization.jsonObject(with: self))
      .flatMap { try? JSONSerialization.data(withJSONObject: $0, options: .prettyPrinted) }
      .flatMap { String(data: $0, encoding: .utf8) }
      ?? String(data: self, encoding: .utf8)
      ?? "<non-UTF8 data>"
  }
}

private extension HTTPURLResponse {
  /// Headers represented as key/value string pairs for logging.
  ///
  /// Converts Foundation's `allHeaderFields` dictionary into `(name, value)`
  /// string pairs.
  var headerPairs: [(String, String)] {
    allHeaderFields.compactMap { key, value -> (String, String)? in
      (key as? String).map { key in
        (key, String(describing: value))
      }
    }
  }
}

private extension URLRequest {
  /// Headers represented as key/value string pairs for logging.
  ///
  /// Converts Foundation's `allHTTPHeaderFields` dictionary into `(name,
  /// value)` string pairs.
  var headerPairs: [(String, String)] {
    allHTTPHeaderFields?.map { ($0.key, $0.value) } ?? []
  }
}
