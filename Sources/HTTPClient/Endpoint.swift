import Foundation

/// Defines an HTTP endpoint that can be requested and decoded.
///
/// Conforming types describe the details of an HTTP request (URL, method,
/// headers, body) and the desired response type. The conforming type provides
/// convenience methods to execute the request either asynchronously or via
/// Combine publishers.
public protocol Endpoint: Sendable {
  /// The type of the decoded response body.
  associatedtype Response

  /// HTTP header fields to include in every request to this endpoint.
  ///
  /// Default is `["Accept": "application/json"]`.
  var httpHeaderFields: [String: String] { get }

  /// The HTTP method for the request (e.g., "GET", "POST").
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

  /// Optional port number for the URL.
  ///
  /// Default is `nil` (uses the default port for the scheme).
  var urlPort: Int? { get }

  /// Query parameters to append to the URL.
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
