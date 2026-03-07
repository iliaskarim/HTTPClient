#if canImport(Combine)
import Combine
import Foundation

public extension Endpoint where Response: Decodable {
  /// Obtain a publisher that executes the request and emits the decoded
  /// response.
  ///
  /// - Parameters:
  ///   - session: The ``URLSession`` to use for the request. Defaults to the
  ///     shared session.
  ///   - bearerToken: An optional bearer token for the `Authorization`
  ///     header.
  /// - Returns: A publisher that emits the decoded response body or fails with
  ///   ``HTTPError`` if the status code is non-2xx, ``URLError`` for transport
  ///   failures, a decoding error if the response body cannot be decoded as
  ///   the expected type, or any error thrown from ``httpBody()``.
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
  /// Obtain a publisher that executes the request and emits `Void` on success.
  ///
  /// - Parameters:
  ///   - session: The ``URLSession`` to use for the request. Defaults to the
  ///     shared session.
  ///   - bearerToken: An optional bearer token for the `Authorization`
  ///     header.
  /// - Returns: A publisher that emits `()` or fails with ``HTTPError`` if
  ///   the status code is non-2xx, ``URLError`` for transport failures, or any
  ///   error thrown from ``httpBody()``.
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
  /// Create a publisher that executes the request and emits the raw response
  /// data.
  ///
  /// Builds and logs the request, logs and validates the HTTP response, and
  /// propagates errors.
  ///
  /// - Parameters:
  ///   - session: The ``URLSession`` to use for the request. Defaults to the
  ///     shared session.
  ///   - bearerToken: An optional bearer token for the `Authorization`
  ///     header.
  /// - Returns: A publisher that emits the raw response data or fails with
  ///   ``HTTPError`` if the status code is non-2xx, ``URLError`` for
  ///   transport failures, or any error thrown from ``httpBody()``.
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
