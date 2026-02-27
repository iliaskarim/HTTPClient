import Foundation

/// A strategy that configures a ``JSONDecoder`` with custom decoding behavior.
///
/// Conforming types typically configure one or more decoding strategies on the
/// provided ``JSONDecoder`` (e.g., date formatting and key conversion).
public protocol DecodingStrategy {
  /// Apply this strategy's configuration to the given decoder.
  ///
  /// - Parameter decoder: The decoder to configure.
  func apply(to decoder: JSONDecoder)
}
