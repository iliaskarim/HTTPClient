
public struct LoggableRequest {
  let headerPairs: [(String, String)]

  let method: String

  let url: String

  public init(headerPairs: [(String, String)], method: String, url: String) {
    self.headerPairs = headerPairs
    self.method = method
    self.url = url
  }
}
