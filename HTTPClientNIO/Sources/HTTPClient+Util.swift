import AsyncHTTPClient
import Foundation
import HTTPClientCore
import NIOFoundationCompat

extension Endpoint {
  func handleResponse(response: HTTPClient.Response, request: HTTPClient.Request) throws -> Data {
    guard var body = response.body, let data = body.readData(length: body.readableBytes) else {
      throw URLError(.badServerResponse)
    }

    Logger.shared.logResponse(.init(response: response), data: data, for: .init(request: request))

    guard response.isOK else {
      throw HTTPError(
        payload: try? JSONDecoder().decode(HTTPError.Payload.self, from: data),
        statusCode: Int(response.status.code)
      )
    }

    return data
  }

  func request(bearerToken: String? = nil) throws -> HTTPClient.Request {
    let httpBody = try httpBody()

    var request = try HTTPClient.Request(url: url(), method: .RAW(value: httpMethod))
    httpHeaderFields.forEach {
      request.headers.add(name: $0.key, value: $0.value)
    }
    request.body = httpBody.map { .data($0) }

    if let bearerToken {
      request.headers.add(name: "Authorization", value: "Bearer \(bearerToken)")
    }

    Logger.shared.logRequest(.init(request: request), httpBody: httpBody)

    return request
  }
}