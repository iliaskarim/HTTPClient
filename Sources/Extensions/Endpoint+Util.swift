import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension Endpoint {
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
