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
