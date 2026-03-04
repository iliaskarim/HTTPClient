import Foundation

public extension Endpoint where Response: Decodable {
  /// Obtain a decoded response by executing the request asynchronously.
  ///
  /// - Parameters:
  ///   - session: The ``URLSession`` to use for the request. Defaults to the
  ///     shared session.
  ///   - bearerToken: An optional bearer token for the `Authorization`
  ///     header.
  /// - Returns: The decoded response body.
  /// - Throws: ``HTTPError`` if the status code is non-2xx, ``URLError`` for
  ///   transport failures, a decoding error if the response body cannot be
  ///   decoded as the expected type, or any error thrown from ``httpBody()``.
  func response(using session: URLSession = .shared, bearerToken: String? = nil) async throws -> Response {
    try await decoder.decode(Response.self, from: responseData(using: session, bearerToken: bearerToken))
  }
}

public extension Endpoint where Response == Void {
  /// Execute the request asynchronously and discard the response body.
  ///
  /// - Parameters:
  ///   - session: The ``URLSession`` to use for the request. Defaults to the
  ///     shared session.
  ///   - bearerToken: An optional bearer token for the `Authorization`
  ///     header.
  /// - Throws: ``HTTPError`` if the status code is non-2xx, ``URLError`` for
  ///   transport failures, or any error thrown from ``httpBody()``.
  func response(using session: URLSession = .shared, bearerToken: String? = nil) async throws {
    _ = try await responseData(using: session, bearerToken: bearerToken)
  }
}

private extension Endpoint {
  /// Execute the request and return the raw response data.
  ///
  /// Builds and logs the request, logs and validates the HTTP response, and
  /// propagates errors.
  ///
  /// - Parameters:
  ///   - session: The ``URLSession`` to use for the request. Defaults to the
  ///     shared session.
  ///   - bearerToken: An optional bearer token for the `Authorization`
  ///     header.
  /// - Returns: The raw response body data.
  /// - Throws: ``HTTPError`` if the status code is non-2xx, ``URLError`` for
  ///   transport failures, or any error thrown from ``httpBody()``.
  @discardableResult
  func responseData(using session: URLSession = .shared, bearerToken: String? = nil) async throws -> Data {
    let request = try request(bearerToken: bearerToken)
    do {
      let (data, response) = try await session.data(for: request)
      try handleResponse(data: data, response: response, request: request)
      return data
    } catch {
      Logger.shared.logError(error)
      throw error
    }
  }
}
