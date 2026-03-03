import Foundation
import HTTPClientCore

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension Endpoint {
  func handleResponse(data: Data, response: URLResponse, request: URLRequest) throws {
    guard let httpResponse = response as? HTTPURLResponse else {
      throw URLError(.badServerResponse)
    }

    Logger.shared.logResponse(.init(response: httpResponse), data: data, for: .init(request: request))

    guard httpResponse.isOK else {
      throw HTTPError(
        payload: try? JSONDecoder().decode(HTTPError.Payload.self, from: data),
        statusCode: httpResponse.statusCode
      )
    }
  }

  func request(bearerToken: String? = nil) throws -> URLRequest {
    var components = URLComponents()
    components.host = urlHost
    components.port = urlPort
    components.path = urlPath
    components.queryItems = urlQueryItems.isEmpty ? nil : urlQueryItems.map {
      URLQueryItem(name: $0.key, value: $0.value)
    }
    components.scheme = urlScheme

    guard let url = components.url else {
      throw URLError(.badURL)
    }

    var request = URLRequest(url: url)
    httpHeaderFields.forEach {
      request.setValue($1, forHTTPHeaderField: $0)
    }
    request.httpBody = try httpBody()
    request.httpMethod = httpMethod

    if let bearerToken {
      request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
    }

    Logger.shared.logRequest(.init(request: request), httpBody: request.httpBody)

    return request
  }
}
