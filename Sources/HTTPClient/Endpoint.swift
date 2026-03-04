import Foundation

/// Defines the requirements for an HTTP endpoint.
///
/// Conforming types describe the details of an HTTP request (URL, method,
/// headers, body) and an associated ``Response`` type. Convenience methods are
/// provided via protocol extensions to execute the request either
/// asynchronously or via Combine publishers.
public protocol Endpoint: Sendable {
  /// The type of the response body.
  associatedtype Response

  /// The HTTP header fields.
  ///
  /// Default is `["Accept": "application/json"]`.
  var httpHeaderFields: [String: String] { get }

  /// The HTTP method.
  ///
  /// Default is `"GET"`.
  var httpMethod: String { get }

  /// The host component of the URL (e.g., "api.example.com").
  ///
  /// This property has no default value and must be provided by conforming
  /// types.
  var urlHost: String { get }

  /// The path component of the URL (e.g., "/users/123").
  ///
  /// Default is `"/"`.
  var urlPath: String { get }

  /// The optional port number for the URL.
  ///
  /// Default is `nil` (uses the default port for the scheme).
  var urlPort: Int? { get }

  /// The query parameters to append to the URL.
  ///
  /// Default is an empty dictionary.
  var urlQueryItems: [String: String] { get }

  /// The scheme component of the URL (e.g., "https", "http").
  ///
  /// Default is `"https"`.
  var urlScheme: String { get }

  /// Produce the HTTP body data for the request, if any.
  ///
  /// Default returns `nil` (no body).
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

  /// Default returns `nil` (no body).
  func httpBody() throws -> Data? {
    nil
  }
}
