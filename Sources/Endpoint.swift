import Combine
import Foundation

/// Defines an HTTP endpoint that can be requested and decoded.
///
/// Conforming types describe the details of an HTTP request (URL, method,
/// headers, body) and the desired response type. The conforming type provides
/// convenience methods to execute the request either asynchronously or via
/// Combine publishers.
public protocol Endpoint: Sendable {
  /// The type of the decoded response body.
  associatedtype Response

  /// HTTP header fields to include in every request to this endpoint.
  ///
  /// Default is `["Accept": "application/json"]`.
  var httpHeaderFields: [String: String] { get }

  /// The HTTP method for the request (e.g., "GET", "POST").
  ///
  /// Default is `"GET"`.
  var httpMethod: String { get }

  /// The host component of the URL (e.g., "api.example.com").
  ///
  /// This property has no default value and must be provided by conforming
  /// types.
  var urlHost: String { get }

  /// The path component of the URL (e.g., "/users/123").
  ///
  /// Default is `"/"`.
  var urlPath: String { get }

  /// Optional port number for the URL.
  ///
  /// Default is `nil` (uses the default port for the scheme).
  var urlPort: Int? { get }

  /// Query parameters to append to the URL.
  ///
  /// Default is an empty dictionary.
  var urlQueryItems: [String: String] { get }

  /// The scheme component of the URL (e.g., "https", "http").
  ///
  /// Default is `"https"`.
  var urlScheme: String { get }

  /// Produce the HTTP body data for the request, if any.
  ///
  /// Default returns `nil` (no body).
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

  /// Default returns `nil` (no body).
  func httpBody() throws -> Data? {
    nil
  }
}

public extension Endpoint where Response: Decodable {
  /// A ``JSONDecoder`` with custom ``DecodingStrategy`` instances applied if
  /// the response type conforms to ``CustomDecodable``.
  private var decoder: JSONDecoder {
    ((Response.self as? CustomDecodable.Type)?.decodingStrategies ?? [])
      .reduce(into: JSONDecoder()) { decoder, strategy in
        strategy.apply(to: decoder)
      }
  }

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

  /// Validate an HTTP response and throw an ``HTTPError`` if the status
  /// code is non-2xx.
  ///
  /// Logs the response details and parses error payloads if available.
  ///
  /// - Parameters:
  ///   - data: The response body data.
  ///   - response: The HTTP response.
  ///   - request: The original request associated with the response.
  /// - Throws: ``HTTPError`` for non-2xx status codes, ``URLError`` if the
  ///   response is not a valid HTTP response.
  func handleResponse(data: Data, response: URLResponse, request: URLRequest) throws {
    guard let httpResponse = response as? HTTPURLResponse else {
      throw URLError(.badServerResponse)
    }

    Logger.shared.logResponse(httpResponse, data: data, for: request)

    guard httpResponse.isOK else {
      throw HTTPError(
        payload: try? JSONDecoder().decode(HTTPError.Payload.self, from: data),
        statusCode: httpResponse.statusCode
      )
    }
  }

  /// Construct a ``URLRequest`` from the endpoint's properties.
  ///
  /// Builds the URL from components, sets headers, attaches the body, and
  /// optionally adds a bearer token for authentication.
  ///
  /// Logs the request details.
  ///
  /// - Parameter bearerToken: An optional bearer token for the
  ///   `Authorization` header.
  /// - Returns: A fully constructed ``URLRequest`` ready to be executed.
  /// - Throws: ``URLError`` if the URL cannot be constructed from the
  ///   endpoint's properties, or any error thrown from ``httpBody()``.
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
