import Foundation

/// A structured error type for HTTP endpoint responses.
///
/// The error payload is decoded from the response body when the server returns
/// an error status code. If the body cannot be decoded into the expected
/// schema, ``payload`` will be `nil` but the ``statusCode`` is always
/// available. The payload type is supplied by ``Endpoint/FailurePayload``.
public struct HTTPError<Payload: Decodable & Sendable>: HTTPFailure, Sendable {
  /// The decoded error payload, if the response body was valid JSON with the
  /// expected schema, or `nil` if decoding failed.
  public let payload: Payload?

  /// The HTTP status code of the error response.
  public let statusCode: Int

  public init(payload: Payload?, statusCode: Int) {
    self.payload = payload
    self.statusCode = statusCode
  }
}

/// Default `{ "error", "message" }` JSON body used when an endpoint does not
/// declare a custom ``Endpoint/FailurePayload``.
public struct HTTPErrorPayload: Decodable, Sendable {
  private enum CodingKeys: String, CodingKey {
    case code = "error"

    case message
  }

  /// The machine-readable error identifier from the server (mapped from the
  /// JSON `error` field), when present.
  public let code: String?

  /// The human-readable error message from the server.
  public let message: String
}

/// Status code for a non-2xx HTTP response.
///
/// Existential casting (`as? any HTTPFailure`) works across ``HTTPError``
/// specializations so callers can handle status without knowing the payload
/// type.
public protocol HTTPFailure: Error {
  /// The HTTP status code of the error response.
  var statusCode: Int { get }
}
