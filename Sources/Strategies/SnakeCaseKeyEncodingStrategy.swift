import Foundation

/// Encoding strategy that converts camelCase properties to snake_case JSON
/// keys.
///
/// When applied to a ``JSONEncoder``, this strategy configures it to
/// automatically convert camelCase property names in Swift structs (e.g.,
/// `userName`) to their snake_case equivalents in the resulting JSON (e.g.,
/// `user_name`). This is useful for APIs that use snake_case naming
/// conventions.
public struct SnakeCaseKeyEncodingStrategy: EncodingStrategy, Sendable {
  /// Shared instance for convenient access.
  public static let shared: Self = .init()

  /// Configure the encoder to convert camelCase properties to snake_case keys.
  ///
  /// - Parameter encoder: The encoder to configure.
  public func apply(to encoder: JSONEncoder) {
    encoder.keyEncodingStrategy = .convertToSnakeCase
  }
}
