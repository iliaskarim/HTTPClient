import Foundation

/// An ``DecodingStrategy`` that decodes ISO 8601 date strings into Date values.
///
/// When applied to a JSONDecoder, this strategy configures it to parse dates in
/// ISO 8601 format (e.g., 2024-02-27T12:34:56Z). Foundation’s native
/// ``JSONDecoder.DateDecodingStrategy.iso8601`` date decoding strategy is used
/// internally.
public struct ISO8601DateDecodingStrategy: DecodingStrategy, Sendable {
  /// Shared instance for convenient access.
  public static let shared: Self = .init()

  /// Applies the ISO 8601 date decoding strategy to the provided JSONDecoder.
  public func apply(to decoder: JSONDecoder) {
    decoder.dateDecodingStrategy = .iso8601
  }
}
