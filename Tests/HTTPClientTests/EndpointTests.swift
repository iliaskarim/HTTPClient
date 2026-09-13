import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Testing
@testable import HTTPClient

@Test
func testFinishedURLEndpointPreservesURL() throws {
  let finished = try #require(
    URL(string: "https://raw.githubusercontent.com/owner/repo/main/file%20name.txt?token=abc#L10")
  )
  let endpoint = FinishedURLEndpoint(url: finished)

  #expect(endpoint.url == finished)
  #expect(try endpoint.request().url == finished)
}

@Test
func testComponentEndpointAssemblesURLFromPieces() throws {
  let endpoint = UserEndpoint(userID: 42)
  let url = endpoint.url

  #expect(url.scheme == "https")
  #expect(url.host == "api.example.com")
  #expect(url.path == "/users/42")
  #expect(url.port == nil)
  #expect(url.query == nil)
  #expect(try endpoint.request().url == url)
}

@Test
func testComponentEndpointIncludesPortSchemeAndQuery() throws {
  let endpoint = LocalSearchEndpoint()
  let components = URLComponents(url: endpoint.url, resolvingAgainstBaseURL: false)

  #expect(components?.scheme == "http")
  #expect(components?.host == "localhost")
  #expect(components?.port == 8080)
  #expect(components?.path == "/v1/search")
  let queryItems = components?.queryItems ?? []
  #expect(queryItems.count == 2)
  #expect(queryItems.contains(URLQueryItem(name: "q", value: "octodoge")))
  #expect(queryItems.contains(URLQueryItem(name: "page", value: "2")))
}

@Test
func testComponentEndpointDefaults() throws {
  let endpoint = HostOnlyEndpoint()
  let expected = try #require(URL(string: "https://api.example.com/"))

  #expect(endpoint.urlPath == "/")
  #expect(endpoint.urlPort == nil)
  #expect(endpoint.urlQueryItems.isEmpty)
  #expect(endpoint.urlScheme == "https")
  #expect(endpoint.url == expected)
}

@Test
func testRequestUsesFinishedURLWithoutReassembly() throws {
  let finished = try #require(URL(string: "https://objects.githubusercontent.com/lfs/oid?token=xyz"))
  let request = try FetchURLDataEndpoint(
    url: finished,
    httpHeaderFields: ["Accept": "application/vnd.git-lfs+json"]
  ).request()

  #expect(request.url == finished)
  #expect(request.httpMethod == "GET")
  #expect(request.value(forHTTPHeaderField: "Accept") == "application/vnd.git-lfs+json")
}

@Test
func testRequestAttachesBearerToken() throws {
  let request = try HostOnlyEndpoint().request(bearerToken: "secret")

  #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer secret")
}

private struct FinishedURLEndpoint: Endpoint {
  typealias Response = Data

  let url: URL
}

private struct FetchURLDataEndpoint: Endpoint {
  typealias Response = Data

  let url: URL
  let httpHeaderFields: [String: String]
}

private struct UserEndpoint: ComponentEndpoint {
  struct Response: Decodable {
    let id: Int
    let name: String
  }

  var urlHost: String {
    "api.example.com"
  }

  var urlPath: String {
    "/users/\(userID)"
  }

  let userID: Int
}

private struct LocalSearchEndpoint: ComponentEndpoint {
  var urlHost: String {
    "localhost"
  }

  var urlPath: String {
    "/v1/search"
  }

  var urlPort: Int? {
    8080
  }

  var urlQueryItems: [String: String] {
    [
      "q": "octodoge",
      "page": "2"
    ]
  }

  var urlScheme: String {
    "http"
  }
}

private struct HostOnlyEndpoint: ComponentEndpoint {
  var urlHost: String {
    "api.example.com"
  }
}
