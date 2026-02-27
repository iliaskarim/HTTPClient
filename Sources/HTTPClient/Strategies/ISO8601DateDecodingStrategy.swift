import Foundation

/// Decoding strategy that interprets date strings as ISO 8601 formatted dates.
///
/// When applied to a ``JSONDecoder``, this strategy configures it to parse
/// dates in ISO 8601 format (e.g., `2024-02-27T12:34:56Z`). Foundation's
/// native `iso8601` decoding strategy is used internally.
public struct ISO8601DateDecodingStrategy: DecodingStrategy, Sendable {
  /// Shared instance for convenient access.
  public static let shared: Self = .init()

  /// Configure the decoder to use ISO 8601 date decoding.
  ///
  /// - Parameter decoder: The decoder to configure.
  public func apply(to decoder: JSONDecoder) {
    decoder.dateDecodingStrategy = .iso8601
  }
}
