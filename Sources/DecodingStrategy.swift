import Foundation

public protocol DecodingStrategy {
  func apply(to decoder: JSONDecoder)
}
