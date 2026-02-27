import Foundation

/// A ``DecodingStrategy`` that decodes snake_case JSON keys to camelCase
/// properties.
///
/// When applied to a JSONDecoder, this strategy configures it to convert
/// snake_case keys in the JSON (e.g., user_name) to their camelCase equivalents
/// in the resulting Swift types (e.g., userName). Foundation’s native
/// ``JSONDecoder.KeyDecodingStrategy.convertFromSnakeCase`` key decoding
/// strategy is used internally.
public struct SnakeCaseKeyDecodingStrategy: DecodingStrategy, Sendable {
  /// Shared instance for convenient access.
  public static let shared: Self = .init()

  /// Applies the snake_case key decoding strategy to the provided JSONDecoder.
  public func apply(to decoder: JSONDecoder) {
    decoder.keyDecodingStrategy = .convertFromSnakeCase
  }
}
