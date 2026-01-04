import Foundation

public struct ISO8601DateEncodingStrategy: EncodingStrategy, Sendable {
  public static let shared: Self = .init()

  public func apply(to encoder: JSONEncoder) {
    encoder.dateEncodingStrategy = .iso8601
  }
}
