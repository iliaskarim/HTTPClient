import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension Endpoint {
  /// Validate an HTTP response and throw an ``HTTPError`` if the status code is
  /// non-2xx.
  ///
  /// Logs the response details and parses error payloads if available.
  /// When ``treatingNotFoundAsSuccess`` is `true`, a 404 is accepted and
  /// logged as a successful response rather than an error.
  ///
  /// - Parameters:
  ///   - data: The response body data.
  ///   - response: The HTTP response.
  ///   - request: The original request associated with the response.
  ///   - treatingNotFoundAsSuccess: When `true`, HTTP 404 does not throw.
  /// - Returns: The HTTP response when the status is accepted.
  /// - Throws: ``HTTPError`` for non-2xx status codes (except 404 when
  ///   ``treatingNotFoundAsSuccess`` is `true`), ``URLError`` if the
  ///   response is not a valid HTTP response.
  @discardableResult
  func handleResponse(
    data: Data,
    response: URLResponse,
    request: URLRequest,
    treatingNotFoundAsSuccess: Bool
  ) throws -> HTTPURLResponse {
    guard let httpResponse = response as? HTTPURLResponse else {
      throw URLError(.badServerResponse)
    }

    let isAccepted404 = treatingNotFoundAsSuccess && httpResponse.statusCode == 404
    Logger.shared.logResponse(httpResponse, data: data, for: request, isAccepted404: isAccepted404)

    guard httpResponse.isOK || isAccepted404 else {
      throw HTTPError(
        payload: try? JSONDecoder().decode(HTTPError.Payload.self, from: data),
        statusCode: httpResponse.statusCode
      )
    }

    return httpResponse
  }

  /// Construct a ``URLRequest`` from the endpoint's properties.
  ///
  /// Uses ``Endpoint/url``, sets headers, attaches the body, and optionally
  /// adds a bearer token for authentication.
  ///
  /// Logs the request details.
  ///
  /// - Parameter bearerToken: An optional bearer token for the
  ///   `Authorization` header.
  /// - Returns: A fully constructed ``URLRequest`` ready to be executed.
  /// - Throws: Any error thrown from ``httpBody()``.
  func request(bearerToken: String? = nil) throws -> URLRequest {
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

extension Endpoint where Response: Decodable {
  /// A ``JSONDecoder`` with custom ``DecodingStrategy`` instances applied if
  /// the response type conforms to ``CustomDecodable``.
  var decoder: JSONDecoder {
    ((Response.self as? CustomDecodable.Type)?.decodingStrategies ?? [])
      .reduce(into: JSONDecoder()) { decoder, strategy in
        strategy.apply(to: decoder)
      }
  }
}
