import Foundation
import HTTPClientCore

extension LoggableResponse {
  init(response: HTTPURLResponse) {
    self.init(
      headerPairs: response.allHeaderFields.compactMap { key, value -> (String, String)? in
      (key as? String).map { key in
        (key, String(describing: value))
      }
    },
      isOK: response.isOK,
      statusCode: response.statusCode,
      url: response.url?.absoluteString ?? "UNKNOWN"
    )
  }
}