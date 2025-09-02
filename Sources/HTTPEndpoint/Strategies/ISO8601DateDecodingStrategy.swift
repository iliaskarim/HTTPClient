import Foundation

public struct ISO8601DateDecodingStrategy: DecodingStrategy, Sendable {
  public static let shared: Self = .init()

  public func apply(to decoder: JSONDecoder) {
    decoder.dateDecodingStrategy = .iso8601
  }
}
