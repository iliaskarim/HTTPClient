import Foundation

final class Logger: Sendable {
  static let shared = Logger()

  private enum LogLevel: String {
    case none, error, info, debug, trace
  }

  private let logLevel: LogLevel

  func logRequest(_ request: URLRequest) {
    guard ![.none, .error].contains(logLevel) else {
      return
    }

    // INFO: log request method and URL.
    print("\(request.httpMethod!) \(request)")

    // TRACE: log request headers.
    if case .trace = logLevel {
      logHeaders(request.headerPairs, prefix: ">")
    }

    // DEBUG: log request body.
    guard let httpBody = request.httpBody, [.debug, .trace].contains(logLevel) else {
      return
    }

    print(httpBody.prettyPrintedString)
  }

  func logResponse(_ response: HTTPURLResponse, data: Data, for request: URLRequest) {
    guard logLevel != .none else {
      return
    }

    // INFO: log response status code and URL.
    // ERROR: log response line if the status code is non-2xx.
    if !response.isOK || logLevel != .error {
      print("\(response.statusCode) \(request)")
    }

    // TRACE: log response headers.
    if case .trace = logLevel {
      logHeaders(response.headerPairs, prefix: "<")
    }

    // DEBUG: log response body.
    guard [.debug, .trace].contains(logLevel), !data.isEmpty else {
      return
    }

    print(data.prettyPrintedString)
  }

  private init() {
    logLevel = (ProcessInfo.processInfo.environment["LOG_LEVEL"]
      ?? Bundle.main.object(forInfoDictionaryKey: "LOG_LEVEL") as? String)
      .flatMap { LogLevel(rawValue: $0.lowercased()) } ?? .info
  }

  private func logHeaders(_ headers: [(String, String)]?, prefix: String) {
    headers?
      .sorted { $0.0.lowercased() < $1.0.lowercased() }
      .forEach { key, value in
        print("\(prefix) \(key): \(value)")
      }
  }
}

private extension Data {
  var prettyPrintedString: String {
    (try? JSONSerialization.jsonObject(with: self))
      .flatMap { try? JSONSerialization.data(withJSONObject: $0, options: .prettyPrinted) }
      .flatMap { String(data: $0, encoding: .utf8) }
      ?? String(data: self, encoding: .utf8)
      ?? "<non-UTF8 data>"
  }
}

private extension HTTPURLResponse {
  var headerPairs: [(String, String)] {
    allHeaderFields.compactMap { key, value -> (String, String)? in
      (key as? String).map { key in
        (key, String(describing: value))
      }
    }
  }
}

private extension URLRequest {
  var headerPairs: [(String, String)] {
    allHTTPHeaderFields?.map { ($0.key, $0.value) } ?? []
  }
}
