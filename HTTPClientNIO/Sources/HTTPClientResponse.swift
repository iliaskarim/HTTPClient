import AsyncHTTPClient

extension HTTPClient.Response {
  var isOK: Bool {
    (200 ..< 300).contains(status.code)
  }
}
