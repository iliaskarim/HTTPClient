public protocol CustomDecodable: Decodable {
  static var decodingStrategies: [DecodingStrategy] { get }
}

extension Array: CustomDecodable where Element: CustomDecodable {
  public static var decodingStrategies: [DecodingStrategy] {
    Element.decodingStrategies
  }
}
