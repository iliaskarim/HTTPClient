import AsyncHTTPClient
import HTTPClientCore

extension LoggableRequest {
  init(request: HTTPClient.Request) {
    self.init(
      headerPairs: request.headers.map { ($0.name, $0.value) },
      method: request.method.rawValue,
      url: String(describing: request.url)
    )
  }
}
