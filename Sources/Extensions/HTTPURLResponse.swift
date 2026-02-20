import Foundation

extension HTTPURLResponse {
  var isOK: Bool {
    (200 ..< 300).contains(statusCode)
  }
}
