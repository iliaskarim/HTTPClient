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

final class Logger: Sendable {
  static let shared = Logger()

  private enum LogLevel: String {
    case none, info, debug, trace
  }

  private let logLevel: LogLevel

  func logRequest(_ request: URLRequest) {
    switch logLevel {
    case .none, .info:
      break

    case .debug:
      print("\(request.httpMethod!) \(request)")

      if let httpBody = request.httpBody {
        print(httpBody.prettyPrintedString)
      }

    case .trace:
      print("\(request.httpMethod!) \(request)")
      logRequestHeaders(request)

      if let httpBody = request.httpBody {
        print(httpBody.prettyPrintedString)
      }
    }
  }

  func logResponse(_ response: HTTPURLResponse, data: Data, for request: URLRequest) {
    let statusCode = response.statusCode

    switch logLevel {
    case .none:
      break

    case .info:
      print("\(statusCode) \(request)")

    case .debug:
      print("\(statusCode) \(request)")

      if !data.isEmpty {
        print(data.prettyPrintedString)
      }

    case .trace:
      print("\(statusCode) \(request)")
      logResponseHeaders(response)

      if !data.isEmpty {
        print(data.prettyPrintedString)
      }
    }
  }

  private init() {
    logLevel = ProcessInfo.processInfo.environment["LOG_LEVEL"].flatMap {
      LogLevel(rawValue: $0.lowercased())
    } ?? .info
  }

  private func logRequestHeaders(_ request: URLRequest) {
    guard let headers = request.allHTTPHeaderFields else {
      return
    }

    headers
      .sorted { $0.key.lowercased() < $1.key.lowercased() }
      .forEach { key, value in
        print("> \(key): \(value)")
      }
  }

  private func logResponseHeaders(_ response: HTTPURLResponse) {
    response.allHeaderFields
      .compactMap { key, value -> (String, String)? in
        guard let key = key as? String else {
          return nil
        }
        return (key, String(describing: value))
      }
      .sorted { $0.0.lowercased() < $1.0.lowercased() }
      .forEach { key, value in
        print("< \(key): \(value)")
      }
  }
}
