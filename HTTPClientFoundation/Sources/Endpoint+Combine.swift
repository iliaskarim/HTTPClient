#if canImport(Combine)
import Combine
import Foundation
import HTTPClientCore

public extension Endpoint where Response: Decodable {
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
        .mapError { error in
          Logger.shared.logError(error)
          return error
        }
    }
    .eraseToAnyPublisher()
  }
}
#endif
