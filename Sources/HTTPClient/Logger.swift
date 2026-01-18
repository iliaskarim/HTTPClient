import Foundation

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
  var headers: [(String, String)] {
    allHeaderFields.compactMap { key, value -> (String, String)? in
      (key as? String).map { key in
        (key, String(describing: value))
      }
    }
  }
}

private extension URLRequest {
  var headers: [(String, String)] {
    allHTTPHeaderFields?.map { ($0.key, $0.value) } ?? []
  }
}

final class Logger: Sendable {
  static let shared = Logger()

  private enum LogLevel: String {
    case none, info, debug, trace
  }

  private let logLevel: LogLevel

  func logRequest(_ request: URLRequest) {
    guard [.debug, .trace].contains(logLevel) else {
      return
    }

    print("\(request.httpMethod!) \(request)")

    if case .trace = logLevel {
      logHeaders(request.headers, prefix: ">")
    }

    guard let httpBody = request.httpBody else {
      return
    }

    print(httpBody.prettyPrintedString)
  }

  func logResponse(_ response: HTTPURLResponse, data: Data, for request: URLRequest) {
    guard [.info, .debug, .trace].contains(logLevel) else {
      return
    }

    print("\(response.statusCode) \(request)")

    if case .trace = logLevel {
      logHeaders(response.headers, prefix: "<")
    }

    guard [.debug, .trace].contains(logLevel), !data.isEmpty else {
      return
    }

    print(data.prettyPrintedString)
  }

  private init() {
    logLevel = ProcessInfo.processInfo.environment["LOG_LEVEL"].flatMap {
      LogLevel(rawValue: $0.lowercased())
    } ?? .info
  }

  private func logHeaders(_ headers: [(String, String)]?, prefix: String) {
    headers?
      .sorted { $0.0.lowercased() < $1.0.lowercased() }
      .forEach { key, value in
        print("\(prefix) \(key): \(value)")
      }
  }
}
