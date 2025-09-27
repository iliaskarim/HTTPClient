import Foundation

private extension Data {
  var prettyPrintedString: String {
    if let object = try? JSONSerialization.jsonObject(with: self),
       let data = try? JSONSerialization.data(withJSONObject: object, options: .prettyPrinted),
       let string = String(data: data, encoding: .utf8) {
      return string
    }

    return String(data: self, encoding: .utf8) ?? "<non-UTF8 data>"
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

    case .trace:
      if let httpBody = request.httpBody {
        print("\(request.httpMethod!) \(request): \(httpBody.prettyPrintedString)")
      } else {
        print("\(request.httpMethod!) \(request)")
      }
    }
  }

  func logResponse(_ statusCode: Int, data: Data, for request: URLRequest) {
    switch logLevel {
    case .none:
      break

    case .debug, .info:
      print("\(statusCode) \(request)")

    case .trace:
      if data.count > 0 {
        print("\(statusCode) \(request): \(data.prettyPrintedString)")
      } else {
        print("\(statusCode) \(request)")
      }
    }
  }

  private init() {
    logLevel = ProcessInfo.processInfo.environment["LOG_LEVEL"].flatMap {
      LogLevel(rawValue: $0.lowercased())
    } ?? .none
  }
}
