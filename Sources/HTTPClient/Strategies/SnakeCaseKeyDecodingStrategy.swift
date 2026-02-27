import Foundation

/// Decoding strategy that converts snake_case JSON keys to camelCase
/// properties.
///
/// When applied to a ``JSONDecoder``, this strategy configures it to
/// automatically convert snake_case keys in the JSON (e.g., `user_name`) to
/// their camelCase equivalents in Swift structs (e.g., `userName`). This is
/// useful for APIs that use snake_case naming conventions.
public struct SnakeCaseKeyDecodingStrategy: DecodingStrategy, Sendable {
  /// Shared instance for convenient access.
  public static let shared: Self = .init()

  /// Configure the decoder to convert snake_case keys to camelCase.
  ///
  /// - Parameter decoder: The decoder to configure.
  public func apply(to decoder: JSONDecoder) {
    decoder.keyDecodingStrategy = .convertFromSnakeCase
  }
}
