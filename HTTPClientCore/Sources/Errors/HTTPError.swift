public struct HTTPError: Error, Sendable {
  public struct Payload: Decodable, Sendable {
    enum CodingKeys: String, CodingKey {
      case code = "error"

      case message
    }

    public let code: String

    public let message: String
  }

  public let payload: Payload?

  public let statusCode: Int

  public init(payload: Payload?, statusCode: Int) {
    self.payload = payload
    self.statusCode = statusCode
  }
}
