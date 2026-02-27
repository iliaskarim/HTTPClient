/// Represents a structured error response from an HTTP endpoint.
///
/// The error payload is decoded from the response body when the server
/// returns an error status code. If the body cannot be decoded into the
/// expected structure, ``payload`` will be `nil` but the ``statusCode``
/// is always available.
public struct HTTPError: Error, Sendable {
  /// The structured error data returned by the server.
  ///
  /// Contains a machine-readable error code and a human-readable message
  /// extracted from the response body. This is `nil` if the server response
  /// body could not be decoded as JSON with the expected schema.
  public struct Payload: Decodable, Sendable {
    /// Coding keys map JSON field names to struct properties.
    ///
    /// The `error` field in the JSON response is decoded into the ``code``
    /// property of this struct.
    enum CodingKeys: String, CodingKey {
      case code = "error"

      case message
    }

    /// Machine-readable error identifier from the server (mapped from
    /// JSON `error` field).
    public let code: String

    /// Human-readable error message from the server.
    public let message: String
  }

  /// The decoded error payload, if the response body was valid JSON with
  /// the expected schema; `nil` if decoding failed.
  public let payload: Payload?

  /// HTTP status code of the error response.
  public let statusCode: Int
}
