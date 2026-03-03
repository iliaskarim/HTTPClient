import Foundation
import HTTPClientCore

extension LoggableRequest {
  init(request: URLRequest) {
    self.init(
      headerPairs: request.allHTTPHeaderFields?.map { ($0.key, $0.value) } ?? [],
      method: request.httpMethod ?? "UNKNOWN",
      url: request.url?.absoluteString ?? "UNKNOWN"
    )
  }
}