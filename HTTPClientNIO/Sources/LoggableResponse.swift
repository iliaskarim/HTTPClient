import AsyncHTTPClient
import HTTPClientCore

extension LoggableResponse {
  init(response: HTTPClient.Response) {
    self.init(
      headerPairs: response.headers.map { ($0.name, $0.value) },
      isOK: response.isOK,
      statusCode: Int(response.status.code),
      url: "UNKNOWN"
    )
  }
}
