public protocol CustomEncodable: Encodable {
  static var encodingStrategies: [EncodingStrategy] { get }
}

extension Array: CustomEncodable where Element: CustomEncodable {
  public static var encodingStrategies: [EncodingStrategy] {
    Element.encodingStrategies
  }
}
