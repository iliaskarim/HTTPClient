import Foundation

/// A strategy that configures a ``JSONEncoder`` with custom encoding behavior.
///
/// Conforming types typically configure one or more encoding strategies on
/// the provided ``JSONEncoder``—such as date formatting, key conversion, or
/// data encoding. Strategies are composed and applied in sequence when encoding
/// objects that conform to ``CustomEncodable``.
public protocol EncodingStrategy {
  /// Apply this strategy's configuration to the given encoder.
  ///
  /// - Parameter encoder: The encoder to configure.
  func apply(to encoder: JSONEncoder)
}
