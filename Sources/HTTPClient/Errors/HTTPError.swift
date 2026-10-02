/// A structured error type for HTTP endpoint responses.
///
/// Thrown for a non-2xx status. ``Payload`` is that endpoint's
/// ``Endpoint/FailurePayload``, decoded from the response body. If the body
/// does not match ``Payload``, ``payload`` is `nil`. ``statusCode`` is still
/// set.
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
