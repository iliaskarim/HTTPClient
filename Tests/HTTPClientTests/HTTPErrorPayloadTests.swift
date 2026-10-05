import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Testing
@testable import HTTPClient

struct HTTPErrorPayloadTests {
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

  @Test
  func testOmittedFailurePayloadUsesHTTPErrorPayload() throws {
    let url = try #require(URL(string: "https://example.com/items/1"))
    let endpoint = PlainEndpoint(url: url)
    expectSameType(PlainEndpoint.FailurePayload.self, HTTPErrorPayload.self)

    let data = Data("""
    {
      "error": "not_found",
      "message": "Missing"
    }
    """.utf8)
    let response = try #require(
      HTTPURLResponse(url: url, statusCode: 404, httpVersion: nil, headerFields: nil)
    )

    do {
      try endpoint.handleResponse(data: data, response: response, request: URLRequest(url: url))
      Issue.record("Expected a non-2xx response to throw")
    } catch let error as HTTPError<HTTPErrorPayload> {
      #expect(error.statusCode == 404)
      #expect(error.payload?.code == "not_found")
      #expect(error.payload?.message == "Missing")
    }
  }

  @Test
  func testFailurePayloadTypealiasOverridesDefault() throws {
    let url = try #require(URL(string: "https://api.github.com/repos/a/b"))
    let endpoint = CustomFailureEndpoint(url: url)
    expectSameType(CustomFailureEndpoint.FailurePayload.self, CustomFailure.self)

    let data = Data("""
    {
      "detail": "name is too short"
    }
    """.utf8)
    let response = try #require(
      HTTPURLResponse(url: url, statusCode: 422, httpVersion: nil, headerFields: nil)
    )

    do {
      try endpoint.handleResponse(data: data, response: response, request: URLRequest(url: url))
      Issue.record("Expected a non-2xx response to throw")
    } catch let error as HTTPError<CustomFailure> {
      #expect(error.statusCode == 422)
      #expect(error.payload?.detail == "name is too short")
    }
  }

  private func expectSameType<T>(_: T.Type, _: T.Type) {}

  private struct PlainEndpoint: Endpoint {
    let url: URL
  }

  private struct CustomFailure: Decodable, Sendable {
    var detail: String
  }

  private struct CustomFailureEndpoint: Endpoint {
    typealias FailurePayload = CustomFailure

    let url: URL
  }
}
