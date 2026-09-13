import Foundation
import Testing
@testable import HTTPClient

@Test
func testSnakeCaseKeyDecodingStrategy() {
  let decoder = JSONDecoder()
  SnakeCaseKeyDecodingStrategy.shared.apply(to: decoder)
  let isSnakeCase = switch decoder.keyDecodingStrategy {
  case .convertFromSnakeCase:
    true

  default:
    false
  }
  #expect(isSnakeCase)
}
