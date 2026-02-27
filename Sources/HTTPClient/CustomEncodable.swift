/// A type that can be encoded to JSON with custom encoding strategies.
///
/// Types that conform to this protocol must provide a list of
/// ``EncodingStrategy`` instances that will be applied to a ``JSONEncoder``
/// before encoding. This allows for flexible customization of how the data
/// is converted (e.g., converting camelCase property names to snake_case JSON
/// keys, formatting dates as ISO 8601, etc.).
public protocol CustomEncodable: Encodable {
  /// The encoding strategies to apply to the encoder for this type.
  static var encodingStrategies: [EncodingStrategy] { get }
}

extension Array: CustomEncodable where Element: CustomEncodable {
  /// Arrays inherit the encoding strategies of their element type.
  ///
  /// This allows ``Array`` of ``CustomEncodable`` elements to automatically
  /// use the same strategies as the element type when being encoded.
  public static var encodingStrategies: [EncodingStrategy] {
    Element.encodingStrategies
  }
}
