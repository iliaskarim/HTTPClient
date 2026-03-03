import AsyncHTTPClient
import Foundation
import HTTPClientCore
import NIOFoundationCompat

public extension Endpoint where Response: Decodable {
  func response(using client: NIOClient = .shared, bearerToken: String? = nil) async throws -> Response {
    try await decoder.decode(Response.self, from: responseData(using: client, bearerToken: bearerToken))
  }
}

public extension Endpoint where Response == Void {
  func response(using client: NIOClient = .shared, bearerToken: String? = nil) async throws {
    _ = try await responseData(using: client, bearerToken: bearerToken)
  }
}

private extension Endpoint {
  @discardableResult
  func responseData(using client: NIOClient, bearerToken: String? = nil) async throws -> Data {
    let request = try request(bearerToken: bearerToken)
    do {
      return try await handleResponse(response: client.execute(request: request), request: request)
    } catch {
      Logger.shared.logError(error)
      throw error
    }
  }
}
