import Foundation
import HTTPClientCore

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension HTTPURLResponse {
  public var headerPairs: [(String, String)] {
    allHeaderFields.compactMap { key, value -> (String, String)? in
      (key as? String).map { key in
        (key, String(describing: value))
      }
    }
  }

  public var isOK: Bool {
    (200..<300).contains(statusCode)
  }

  public var urlString: String {
    url?.absoluteString ?? "UNKNOWN"
  }
}

