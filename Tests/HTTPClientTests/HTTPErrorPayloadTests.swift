import Foundation
import Testing
@testable import HTTPClient

@Test
func testDefaultPayloadDecodesErrorAndMessage() throws {
  let json = Data("""
  {
    "error": "invalid_request",
    "message": "Validation Failed"
  }
  """.utf8)

  let payload = try JSONDecoder().decode(HTTPErrorPayload.self, from: json)
  #expect(payload.code == "invalid_request")
  #expect(payload.message == "Validation Failed")

  let error = HTTPError(payload: payload, statusCode: 422)
  #expect(error.statusCode == 422)
  #expect(error.payload?.message == "Validation Failed")
}

@Test
func testHTTPErrorConformsToHTTPFailure() {
  let error: any HTTPFailure = HTTPError<HTTPErrorPayload>(
    payload: nil,
    statusCode: 404
  )
  #expect(error.statusCode == 404)
}
