import Combine
import Foundation

public protocol Endpoint {
  associatedtype Response

  var httpHeaderFields: [String: String] { get }

  var httpMethod: String { get }

  var urlHost: String { get }

  var urlPath: String { get }

  var urlQueryItems: [String: String] { get }

  var urlScheme: String { get }

  func httpBody() throws -> Data?
}

public extension Endpoint {
  var httpHeaderFields: [String: String] {
    ["Accept": "application/json"]
  }

  var httpMethod: String {
    "GET"
  }

  var urlScheme: String {
    "https"
  }

  var urlQueryItems: [String: String] {
    [:]
  }

  func httpBody() throws -> Data? {
    nil
  }
}

private extension Endpoint {
  func requestPublisher(bearerToken: String? = nil) -> AnyPublisher<URLRequest, Error> {
    Result {
      var components = URLComponents()
      components.host = urlHost
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

      Logger.shared.logRequest(request)

      return request
    }
    .publisher
    .eraseToAnyPublisher()
  }
}

private extension URLRequest {
  func responsePublisher(using session: URLSession = .shared) -> AnyPublisher<Data, Error> {
    session
      .dataTaskPublisher(for: self)
      .tryMap { output in
        guard let httpResponse = output.response as? HTTPURLResponse else {
          throw URLError(.badServerResponse)
        }

        let statusCode = httpResponse.statusCode

        Logger.shared.logResponse(httpResponse.statusCode, data: output.data, for: self)

        guard 200 ..< 300 ~= statusCode else {
          throw HTTPError(
            payload: try? JSONDecoder().decode(HTTPError.Payload.self, from: output.data),
            statusCode: statusCode
          )
        }

        return output.data
      }
      .eraseToAnyPublisher()
  }
}

public extension Endpoint where Response: Decodable {
  func responsePublisher(
    using session: URLSession = .shared,
    bearerToken: String? = nil
  ) -> AnyPublisher<Response, Error> {
    let decoder = ((Response.self as? CustomDecodable.Type)?.decodingStrategies ?? [])
      .reduce(into: JSONDecoder()) { decoder, strategy in
        strategy.apply(to: decoder)
      }

    return requestPublisher(bearerToken: bearerToken)
      .flatMap { request in
        request.responsePublisher(using: session)
      }
      .decode(type: Response.self, decoder: decoder)
      .eraseToAnyPublisher()
  }
}

public extension Endpoint where Response == Void {
  func responsePublisher(
    using session: URLSession = .shared,
    bearerToken: String? = nil
  ) -> AnyPublisher<Void, Error> {
    requestPublisher(bearerToken: bearerToken)
      .flatMap { request in
        request.responsePublisher(using: session)
      }
      .map { _ in }
      .eraseToAnyPublisher()
  }
}
