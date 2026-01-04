import Foundation

public struct SnakeCaseKeyDecodingStrategy: DecodingStrategy, Sendable {
  public static let shared: Self = .init()

  public func apply(to decoder: JSONDecoder) {
    decoder.keyDecodingStrategy = .convertFromSnakeCase
  }
}
