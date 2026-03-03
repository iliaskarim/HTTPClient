import Foundation

public extension Endpoint {
  func url() throws -> URL {
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

    return url
  }
}

public extension Endpoint where Response: Decodable {
  var decoder: JSONDecoder {
    ((Response.self as? CustomDecodable.Type)?.decodingStrategies ?? [])
      .reduce(into: JSONDecoder()) { decoder, strategy in
        strategy.apply(to: decoder)
      }
  }
}
