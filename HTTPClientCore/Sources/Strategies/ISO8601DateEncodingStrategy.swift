import Foundation

/// Encoding strategy that formats dates as ISO 8601 strings.
///
/// When applied to a ``JSONEncoder``, this strategy configures it to encode
/// `Date` values using the ISO 8601 format (e.g., `2024-02-27T12:34:56Z`).
/// Foundation's native `iso8601` encoding strategy is used internally.
public struct ISO8601DateEncodingStrategy: EncodingStrategy, Sendable {
  /// Shared instance for convenient access.
  public static let shared: Self = .init()

  /// Configure the encoder to use ISO 8601 date encoding.
  ///
  /// - Parameter encoder: The encoder to configure.
  public func apply(to encoder: JSONEncoder) {
    encoder.dateEncodingStrategy = .iso8601
  }
}
