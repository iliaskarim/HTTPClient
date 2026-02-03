import Combine
import Foundation

public protocol Endpoint: Sendable {
  associatedtype Response

  var httpHeaderFields: [String: String] { get }

  var httpMethod: String { get }

  var urlHost: String { get }

  var urlPath: String { get }

  var urlPort: Int? { get }

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

  var urlPath: String {
    "/"
  }

  var urlPort: Int? {
    nil
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

public extension Endpoint where Response: Decodable {
  private var decoder: JSONDecoder {
    ((Response.self as? CustomDecodable.Type)?.decodingStrategies ?? [])
      .reduce(into: JSONDecoder()) { decoder, strategy in
        strategy.apply(to: decoder)
      }
  }

  func response(using session: URLSession = .shared, bearerToken: String? = nil) async throws -> Response {
    try await decoder.decode(Response.self, from: responseData(using: session, bearerToken: bearerToken))
  }

  func responsePublisher(
    using session: URLSession = .shared,
    bearerToken: String? = nil
  ) -> AnyPublisher<Response, Error> {
    responseDataPublisher(using: session, bearerToken: bearerToken)
      .decode(type: Response.self, decoder: decoder)
      .eraseToAnyPublisher()
  }
}

public extension Endpoint where Response == Void {
  func response(using session: URLSession = .shared, bearerToken: String? = nil) async throws {
    try await responseData(using: session, bearerToken: bearerToken)
  }

  func responsePublisher(
    using session: URLSession = .shared,
    bearerToken: String? = nil
  ) -> AnyPublisher<Void, Error> {
    responseDataPublisher(using: session, bearerToken: bearerToken)
      .map { _ in }
      .eraseToAnyPublisher()
  }
}

private extension Endpoint {
  @discardableResult
  func responseData(using session: URLSession = .shared, bearerToken: String? = nil) async throws -> Data {
    let request = try request(bearerToken: bearerToken)
    let (data, response) = try await session.data(for: request)
    try handleResponse(data: data, response: response, request: request)
    return data
  }

  func responseDataPublisher(
    using session: URLSession = .shared,
    bearerToken: String? = nil
  ) -> AnyPublisher<Data, Error> {
    Deferred {
      Future<URLRequest, Error> { promise in
        do {
          try promise(.success(self.request(bearerToken: bearerToken)))
        } catch {
          promise(.failure(error))
        }
      }
    }
    .flatMap { request in
      session.dataTaskPublisher(for: request)
        .tryMap { data, response in
          try handleResponse(data: data, response: response, request: request)
          return data
        }
    }
    .eraseToAnyPublisher()
  }

  func handleResponse(data: Data, response: URLResponse, request: URLRequest) throws {
    guard let httpResponse = response as? HTTPURLResponse else {
      throw URLError(.badServerResponse)
    }

    Logger.shared.logResponse(httpResponse, data: data, for: request)

    let statusCode = httpResponse.statusCode
    guard 200 ..< 300 ~= statusCode else {
      throw HTTPError(
        payload: try? JSONDecoder().decode(HTTPError.Payload.self, from: data),
        statusCode: statusCode
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

    Logger.shared.logRequest(request)

    return request
  }
}
