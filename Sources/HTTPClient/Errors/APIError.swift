public struct APIError: Decodable, Error, Sendable {
  public let error: String

  public let message: String
}
