import Foundation
import Testing
@testable import HTTPEndpoint

@Test func testISO8601DateEncodingStrategy() async throws {
  let encoder = JSONEncoder()
  ISO8601DateEncodingStrategy.shared.apply(to: encoder)
  let isISO8601 = switch encoder.dateEncodingStrategy {
  case .iso8601:
    true

  default:
    false
  }
  #expect(isISO8601)
}
