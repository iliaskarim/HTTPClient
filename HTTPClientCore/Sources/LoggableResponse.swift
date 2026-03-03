
public struct LoggableResponse {
  let headerPairs: [(String, String)]

  let isOK: Bool

  let statusCode: Int

  let url: String

  public init(headerPairs: [(String, String)], isOK: Bool, statusCode: Int, url: String) {
    self.headerPairs = headerPairs
    self.isOK = isOK
    self.statusCode = statusCode
    self.url = url
  }
}