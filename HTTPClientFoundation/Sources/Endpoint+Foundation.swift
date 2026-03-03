import Foundation
import HTTPClientCore

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public extension Endpoint where Response: Decodable {
  func response(using session: URLSession = .shared, bearerToken: String? = nil) async throws -> Response {
    try await decoder.decode(Response.self, from: responseData(using: session, bearerToken: bearerToken))
  }
}

public extension Endpoint where Response == Void {
  func response(using session: URLSession = .shared, bearerToken: String? = nil) async throws {
    _ = try await responseData(using: session, bearerToken: bearerToken)
  }
}

private extension Endpoint {
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
