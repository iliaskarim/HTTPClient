import Foundation

public protocol EncodingStrategy {
  func apply(to encoder: JSONEncoder)
}
