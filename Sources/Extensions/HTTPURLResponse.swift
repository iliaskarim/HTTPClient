import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension HTTPURLResponse {
  /// Whether the response indicates success.
  ///
  /// Returns `true` if the status code is in the 2xx range, `false` otherwise.
  var isOK: Bool {
    (200 ..< 300).contains(statusCode)
  }
}
