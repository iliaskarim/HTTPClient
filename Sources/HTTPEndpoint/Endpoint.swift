import Combine
import Foundation

#if DEBUG
private extension Data {
  var jsonString: String {
    guard let object = try? JSONSerialization.jsonObject(with: self),
          let data = try? JSONSerialization.data(withJSONObject: object, options: .prettyPrinted) else {
      return .init(data: self, encoding: .utf8)!
    }

    return .init(data: data, encoding: .utf8)!
  }
}
#endif

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

#if DEBUG
      if let httpBody = request.httpBody {
        print("\(request.httpMethod!) \(request): \(httpBody.jsonString)")
      } else {
        print("\(request.httpMethod!) \(request)")
      }
#endif

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

#if DEBUG
        print("\(statusCode) \(self): \(output.data.jsonString)")
#endif

        guard 200 ..< 300 ~= statusCode else {
          throw HTTPError(statusCode: statusCode)
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
      .map { _ in () }
      .eraseToAnyPublisher()
  }
}
