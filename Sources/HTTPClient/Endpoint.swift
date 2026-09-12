import Foundation

/// Defines the requirements for an HTTP endpoint.
///
/// Conforming types define an endpoint's request details (URL, method, headers,
/// and request body) and associated ``Response`` type (decoded response body).
///
/// Provide a finished ``url`` when the caller already has one. To build a URL
/// from host, path, port, query, and scheme, conform to ``ComponentEndpoint``.
///
/// When ``Request`` is ``Encodable``, default ``httpBody()``, ``httpMethod``,
/// and ``httpHeaderFields`` encode JSON and use POST; when ``Request`` is
/// ``Void``, the body is omitted and GET defaults apply.
public protocol Endpoint: Sendable {
  /// The type of the response body.
  ///
  /// Default is `Void`.
  associatedtype Response = Void

  /// The type of the request body.
  ///
  /// Default is `Void`.
  associatedtype Request = Void

  /// The HTTP header fields.
  var httpHeaderFields: [String: String] { get }

  /// The HTTP method (e.g. `"GET"`, `"POST"`).
  var httpMethod: String { get }

  /// The request payload to send to the endpoint.
  ///
  /// Default is `Void`.
  var request: Request { get }

  /// The URL of the request.
  ///
  /// This property has no default value and must be provided. Conform to
  /// ``ComponentEndpoint`` to assemble a URL from host, path, port, query,
  /// and scheme.
  var url: URL { get }

  /// The UTF-8 body data for the HTTP request, if any.
  ///
  /// - Returns: Body bytes, or `nil` when the endpoint sends no body.
  /// - Throws: Encoding or other errors from the implementation.
  func httpBody() throws -> Data?
}

public extension Endpoint {
  /// The HTTP header fields.
  ///
  /// Default is `["Accept": "application/json"]`.
  var httpHeaderFields: [String: String] {
    ["Accept": "application/json"]
  }

  /// The HTTP method.
  ///
  /// Default is `"GET"`.
  var httpMethod: String {
    "GET"
  }

  /// The UTF-8 body data for the HTTP request, if any.
  ///
  /// Default is `nil`.
  ///
  /// - Returns: `nil`.
  /// - Throws: This default implementation does not throw.
  func httpBody() throws -> Data? {
    nil
  }
}

public extension Endpoint where Request == Void {
  /// The request payload to send to the endpoint.
  ///
  /// Default is `Void`.
  var request: Request {
    ()
  }
}

public extension Endpoint where Request: Encodable {
  /// The HTTP header fields.
  ///
  /// Default is `Accept` and `Content-Type` both set to `"application/json"`.
  var httpHeaderFields: [String: String] {
    [
      "Accept": "application/json",
      "Content-Type": "application/json"
    ]
  }

  /// The HTTP method.
  ///
  /// Default is `"POST"`.
  var httpMethod: String {
    "POST"
  }

  /// The UTF-8 body data for the HTTP request, if any.
  ///
  /// Default is JSON-encoded ``request``. Encoder strategies from
  /// ``CustomEncodable`` apply first when ``Request`` conforms to it (e.g.,
  /// date formatting and key conversion).
  ///
  /// - Returns: UTF-8 JSON forming the HTTP body contents.
  /// - Throws: Any error surfaced by ``JSONEncoder`` while encoding
  ///   ``request``.
  func httpBody() throws -> Data? {
    try ((Request.self as? CustomEncodable.Type)?.encodingStrategies ?? [])
      .reduce(into: JSONEncoder()) { encoder, strategy in
        strategy.apply(to: encoder)
      }
      .encode(request)
  }
}
