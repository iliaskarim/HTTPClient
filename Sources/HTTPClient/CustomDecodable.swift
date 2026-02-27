/// A type that can be decoded from JSON with custom decoding strategies.
///
/// Types that conform to this protocol must provide a list of
/// ``DecodingStrategy`` instances that will be applied to a ``JSONDecoder``
/// before decoding. This allows for flexible customization of how the JSON
/// data is interpreted (e.g., converting snake_case keys to camelCase,
/// parsing ISO 8601 dates, etc.).
public protocol CustomDecodable: Decodable {
  /// The decoding strategies to apply to the decoder for this type.
  static var decodingStrategies: [DecodingStrategy] { get }
}

extension Array: CustomDecodable where Element: CustomDecodable {
  /// Arrays inherit the decoding strategies of their element type.
  ///
  /// This allows ``Array`` of ``CustomDecodable`` elements to automatically
  /// use the same strategies as the element type when being decoded.
  public static var decodingStrategies: [DecodingStrategy] {
    Element.decodingStrategies
  }
}
