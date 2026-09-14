import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Testing
@testable import HTTPClient

private struct VoidEndpoint: ComponentEndpoint {
  var urlHost: String {
    "example.com"
  }

  var urlPath: String {
    "/resource"
  }
}

private struct ExistenceEndpoint: ComponentEndpoint, TreatsNotFoundAsFalse {
  var urlHost: String {
    "example.com"
  }

  var urlPath: String {
    "/resource"
  }
}

private final class StubURLProtocol: URLProtocol, @unchecked Sendable {
  nonisolated(unsafe) static var statusCode = 200

  nonisolated(unsafe) static var body = Data()

  private static let lock = NSLock()

  override class func canInit(with _: URLRequest) -> Bool {
    true
  }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    request
  }

  override func startLoading() {
    let statusCode: Int
    let body: Data
    Self.lock.lock()
    statusCode = Self.statusCode
    body = Self.body
    Self.lock.unlock()

    let response = HTTPURLResponse(
      url: request.url!,
      statusCode: statusCode,
      httpVersion: "HTTP/1.1",
      headerFields: ["Content-Type": "application/json"]
    )!
    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
    client?.urlProtocol(self, didLoad: body)
    client?.urlProtocolDidFinishLoading(self)
  }

  override func stopLoading() {}

  static func setResponse(statusCode: Int, body: Data = Data()) {
    lock.lock()
    self.statusCode = statusCode
    self.body = body
    lock.unlock()
  }
}

private func stubSession() -> URLSession {
  let configuration = URLSessionConfiguration.ephemeral
  configuration.protocolClasses = [StubURLProtocol.self]
  return URLSession(configuration: configuration)
}

@Suite(.serialized)
struct NotFoundResponseTests {
  @Test
  func treatsNotFoundAsFalseReturnsTrueOn2xx() async throws {
    StubURLProtocol.setResponse(statusCode: 204)
    let exists = try await ExistenceEndpoint().response(using: stubSession())
    #expect(exists)
  }

  @Test
  func treatsNotFoundAsFalseReturnsFalseOn404() async throws {
    StubURLProtocol.setResponse(statusCode: 404)
    let exists = try await ExistenceEndpoint().response(using: stubSession())
    #expect(!exists)
  }

  @Test
  func treatsNotFoundAsFalseThrowsOnOtherClientError() async {
    StubURLProtocol.setResponse(statusCode: 403)
    await #expect(throws: HTTPError.self) {
      _ = try await ExistenceEndpoint().response(using: stubSession())
    }
  }

  @Test
  func voidResponseThrowsOn404() async {
    StubURLProtocol.setResponse(statusCode: 404)
    await #expect(throws: HTTPError.self) {
      try await VoidEndpoint().response(using: stubSession())
    }
  }

  @Test
  func treatsNotFoundAsFalsePreservesHTTPErrorStatusCode() async {
    StubURLProtocol.setResponse(statusCode: 500)
    do {
      _ = try await ExistenceEndpoint().response(using: stubSession())
      Issue.record("Expected HTTPError")
    } catch let error as HTTPError {
      #expect(error.statusCode == 500)
    } catch {
      Issue.record("Expected HTTPError, got \(error)")
    }
  }
}
