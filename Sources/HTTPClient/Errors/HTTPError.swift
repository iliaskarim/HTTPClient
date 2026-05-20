/// A structured error type for HTTP endpoint responses.
///
/// The error payload is decoded from the response body when the server
/// returns an error status code. If the body cannot be decoded into the
/// expected schema, ``payload`` will be `nil` but the ``statusCode``
/// is always available.
public struct HTTPError: Error, Sendable {
  /// A structured error payload returned by the server.
  ///
  /// Contains a machine-readable error code and a human-readable message
  /// extracted from the response body. This is `nil` if the server response
  /// body could not be decoded as JSON with the expected schema.
  public struct Payload: Decodable, Sendable {
    private enum CodingKeys: String, CodingKey {
      case code = "error"

      case message
    }

    /// The machine-readable error identifier from the server (mapped from
    /// the JSON `error` field), when present.
    public let code: String?

    /// The human-readable error message from the server.
    public let message: String
  }

  /// The decoded error payload, if the response body was valid JSON with
  /// the expected schema, or `nil` if decoding failed.
  public let payload: Payload?

  /// The HTTP status code of the error response.
  public let statusCode: Int
}
