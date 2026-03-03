import Foundation
import Testing
@testable import HTTPEndpoint

@Test func testSnakeCaseKeyDecodingStrategy() async throws {
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
