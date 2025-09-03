import Foundation

public protocol JSONRequestEndpoint: Endpoint {
  associatedtype Request

  var request: Request { get }
}

public extension JSONRequestEndpoint {
  var httpHeaderFields: [String: String] {
    ["Accept": "application/json", "Content-Type": "application/json"]
  }

  var httpMethod: String {
    "POST"
  }
}

public extension JSONRequestEndpoint where Request: Encodable {
  func httpBody() throws -> Data? {
    let encoder = ((Request.self as? CustomEncodable.Type)?.encodingStrategies ?? [])
      .reduce(into: JSONEncoder()) { encoder, strategy in
        strategy.apply(to: encoder)
      }

    return try encoder.encode(request)
  }
}
