import Foundation
import Testing
@testable import HTTPClient

@Suite
struct SnakeCaseKeyEncodingStrategyTests {
  @Test
  func testSnakeCaseKeyEncodingStrategy() {
    let encoder = JSONEncoder()
    SnakeCaseKeyEncodingStrategy.shared.apply(to: encoder)
    let isSnakeCase = switch encoder.keyEncodingStrategy {
    case .convertToSnakeCase:
      true

    default:
      false
    }
    #expect(isSnakeCase)
  }
}
