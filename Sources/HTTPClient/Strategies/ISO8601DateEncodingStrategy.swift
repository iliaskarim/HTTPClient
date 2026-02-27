import Foundation

/// An ``EncodingStrategy`` that encodes Date values as ISO 8601 date strings.
///
/// When applied to a JSONEncoder, this strategy configures it to format Date
/// values as ISO 8601 strings (e.g., 2024-02-27T12:34:56Z). Foundation’s native
/// ``JSONEncoder.DateEncodingStrategy.iso8601`` date encoding strategy is used
/// internally.
public struct ISO8601DateEncodingStrategy: EncodingStrategy, Sendable {
  /// Shared instance for convenient access.
  public static let shared: Self = .init()

  /// Applies the ISO 8601 date encoding strategy to the provided JSONEncoder.
  public func apply(to encoder: JSONEncoder) {
    encoder.dateEncodingStrategy = .iso8601
  }
}
