import Foundation

/// An ``Endpoint`` that sends a JSON-encoded request body.
///
/// Conforming types provide an associated ``Request`` type and an instance
/// of it. The request is automatically JSON-encoded and sent with
/// `Content-Type: application/json` headers.
public protocol JSONRequestEndpoint: Endpoint {
  /// The type of the request body to be sent.
  associatedtype Request

  /// The request payload to send to the endpoint.
  var request: Request { get }
}

public extension JSONRequestEndpoint {
  /// HTTP headers for JSON requests.
  ///
  /// Defaults to `Accept` and `Content-Type` both set to `"application/json"`.
  var httpHeaderFields: [String: String] {
    [
      "Accept": "application/json",
      "Content-Type": "application/json"
    ]
  }

  /// The HTTP method used for JSON requests.
  ///
  /// Defaults to `"POST"`.
  var httpMethod: String {
    "POST"
  }
}

public extension JSONRequestEndpoint where Request: Encodable {
  /// Encode the request payload as JSON for the HTTP body.
  ///
  /// If the request type conforms to ``CustomEncodable``, any encoding
  /// strategies are automatically applied (e.g., camelCase to snake_case
  /// conversion).
  ///
  /// - Returns: The JSON-encoded request payload, or `nil` if encoding fails.
  /// - Throws: Any encoding error encountered during JSON serialization.
  func httpBody() throws -> Data? {
    try ((Request.self as? CustomEncodable.Type)?.encodingStrategies ?? [])
      .reduce(into: JSONEncoder()) { encoder, strategy in
        strategy.apply(to: encoder)
      }
      .encode(request)
  }
}
