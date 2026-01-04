import Foundation

public struct SnakeCaseKeyEncodingStrategy: EncodingStrategy, Sendable {
  public static let shared: Self = .init()

  public func apply(to encoder: JSONEncoder) {
    encoder.keyEncodingStrategy = .convertToSnakeCase
  }
}
