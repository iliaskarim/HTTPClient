import Foundation
import Testing
@testable import HTTPClient

@Suite
struct ISO8601DateDecodingStrategyTests {
  @Test
  func testISO8601DateDecodingStrategy() {
    let decoder = JSONDecoder()
    ISO8601DateDecodingStrategy.shared.apply(to: decoder)
    let isISO8601 = switch decoder.dateDecodingStrategy {
    case .iso8601:
      true

    default:
      false
    }
    #expect(isISO8601)
  }
}
