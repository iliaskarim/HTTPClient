import Foundation

/// A strategy that configures a ``JSONDecoder`` with custom decoding behavior.
///
/// Conforming types typically configure one or more decoding strategies on
/// the provided ``JSONDecoder``—such as date formatting, key conversion, or
/// data decoding. Strategies are composed and applied in sequence when decoding
/// objects that conform to ``CustomDecodable``.
public protocol DecodingStrategy {
  /// Apply this strategy's configuration to the given decoder.
  func apply(to decoder: JSONDecoder)
}
