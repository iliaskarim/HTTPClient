import Foundation

public protocol Endpoint: Sendable {
  associatedtype Response

  var httpHeaderFields: [String: String] { get }

  var httpMethod: String { get }

  var urlHost: String { get }

  var urlPath: String { get }

  var urlPort: Int? { get }

  var urlQueryItems: [String: String] { get }

  var urlScheme: String { get }

  func httpBody() throws -> Data?
}

public extension Endpoint {
  var httpHeaderFields: [String: String] {
    ["Accept": "application/json"]
  }

  var httpMethod: String {
    "GET"
  }

  var urlPath: String {
    "/"
  }

  var urlPort: Int? {
    nil
  }

  var urlScheme: String {
    "https"
  }

  var urlQueryItems: [String: String] {
    [:]
  }

  func httpBody() throws -> Data? {
    nil
  }
}
