import Foundation

/// An ``EncodingStrategy`` that encodes camelCase properties as snake_case JSON
/// keys.
///
/// When applied to a JSONEncoder, this strategy configures it to convert
/// camelCase properties in the Swift types (e.g., userName) to their snake_case
/// equivalents in the resulting JSON (e.g., user_name). Foundation’s native
/// ``JSONEncoder.KeyEncodingStrategy.convertToSnakeCase`` key encoding strategy
/// is used internally.
public struct SnakeCaseKeyEncodingStrategy: EncodingStrategy, Sendable {
  /// Shared instance for convenient access.
  public static let shared: Self = .init()

  /// Applies the snake_case key encoding strategy to the provided JSONEncoder.
  public func apply(to encoder: JSONEncoder) {
    encoder.keyEncodingStrategy = .convertToSnakeCase
  }
}
