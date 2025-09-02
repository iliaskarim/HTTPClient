import Foundation

public protocol JSONRequestEndpoint: Endpoint {
  associatedtype Request

  static var encodingStrategies: [EncodingStrategy] { get }

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
    let jsonEncoder = Self.encodingStrategies.reduce(into: JSONEncoder()) { encoder, strategy in
      strategy.apply(to: encoder)
    }

    return try jsonEncoder.encode(request)
  }
}
