#if canImport(Combine)
import Combine
import Foundation

public extension Endpoint where Response: Decodable {
  /// Obtain a publisher that executes the request and emits the decoded
  /// response body.
  ///
  /// If the response type conforms to ``CustomDecodable``, any decoding
  /// strategies are automatically applied (e.g., date formatting and key
  /// conversion).
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

public extension Endpoint where Response == Data {
  /// Obtain a publisher that executes the request and emits the raw response
  /// body.
  ///
  /// - Parameters:
  ///   - session: The ``URLSession`` to use for the request. Defaults to the
  ///     shared session.
  ///   - bearerToken: An optional bearer token for the `Authorization`
  ///     header.
  /// - Returns: A publisher that emits the response body data or fails with
  ///   ``HTTPError`` if the status code is non-2xx, ``URLError`` for transport
  ///   failures, or any error thrown from ``httpBody()``.
  func responsePublisher(
    using session: URLSession = .shared,
    bearerToken: String? = nil
  ) -> AnyPublisher<Data, Error> {
    responseDataPublisher(using: session, bearerToken: bearerToken)
  }
}

public extension Endpoint where Response == Void {
  /// Obtain a publisher that executes the request and emits `Void`.
  ///
  /// To treat HTTP 404 as a successful `false`, conform to
  /// ``TreatsNotFoundAsFalse`` instead.
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

public extension TreatsNotFoundAsFalse {
  /// Obtain a publisher that treats HTTP 404 as a successful negative.
  ///
  /// A 404 is not logged as an error.
  ///
  /// - Parameters:
  ///   - session: The ``URLSession`` to use for the request. Defaults to the
  ///     shared session.
  ///   - bearerToken: An optional bearer token for the `Authorization`
  ///     header.
  /// - Returns: A publisher that emits `true` on 2xx and `false` on 404, or
  ///   fails with ``HTTPError`` for any other non-2xx status, ``URLError``
  ///   for transport failures, or any error thrown from ``httpBody()``.
  func responsePublisher(
    using session: URLSession = .shared,
    bearerToken: String? = nil
  ) -> AnyPublisher<Bool, Error> {
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
          let httpResponse = try handleResponse(
            data: data,
            response: response,
            request: request,
            treatingNotFoundAsSuccess: true
          )
          return httpResponse.statusCode != 404
        }
        .mapError { error in
          Logger.shared.logError(error)
          return error
        }
    }
    .eraseToAnyPublisher()
  }

  /// The inherited Void ``Endpoint/responsePublisher(using:bearerToken:)`` is
  /// unavailable so a discarded publisher cannot throw on 404.
  @available(*, unavailable, message: "Assign the Bool publisher result.")
  func responsePublisher(
    using _: URLSession = .shared,
    bearerToken _: String? = nil
  ) -> AnyPublisher<Void, Error> {
    fatalError()
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
          try handleResponse(
            data: data,
            response: response,
            request: request,
            treatingNotFoundAsSuccess: false
          )
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
