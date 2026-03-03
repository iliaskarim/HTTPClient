import Foundation
import Testing
@testable import HTTPEndpoint

@Test func testSnakeCaseKeyEncodingStrategy() async throws {
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
