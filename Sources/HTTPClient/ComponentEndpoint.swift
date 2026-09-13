import Foundation

/// An ``Endpoint`` whose URL is assembled from components.
///
/// Conforming types supply ``urlHost`` and optionally path, port, query items,
/// and scheme. The default ``url`` builds a ``URL`` from those pieces so
/// REST-style endpoints do not need a finished URL.
public protocol ComponentEndpoint: Endpoint {
  /// The host component of the URL (e.g., "api.example.com").
  ///
  /// This property has no default value and must be provided.
  var urlHost: String { get }

  /// The path component of the URL (e.g., "/users/123").
  ///
  /// Default is `"/"`.
  var urlPath: String { get }

  /// The optional port number for the URL.
  ///
  /// Default is `nil` (uses the default port for the scheme).
  var urlPort: Int? { get }

  /// The query parameters to append to the URL.
  ///
  /// Default is an empty dictionary.
  var urlQueryItems: [String: String] { get }

  /// The scheme component of the URL (e.g., "https", "http").
  ///
  /// Default is `"https"`.
  var urlScheme: String { get }
}

public extension ComponentEndpoint {
  /// The path component of the URL.
  ///
  /// Default is `"/"`.
  var urlPath: String {
    "/"
  }

  /// The optional port number for the URL.
  ///
  /// Default is `nil` (uses the default port for the scheme).
  var urlPort: Int? {
    nil
  }

  /// The query parameters to append to the URL.
  ///
  /// Default is an empty dictionary.
  var urlQueryItems: [String: String] {
    [:]
  }

  /// The scheme component of the URL.
  ///
  /// Default is `"https"`.
  var urlScheme: String {
    "https"
  }

  /// The URL assembled from the endpoint's URL components.
  ///
  /// Builds a ``URL`` from ``urlScheme``, ``urlHost``, ``urlPort``,
  /// ``urlPath``, and ``urlQueryItems``.
  ///
  /// - Important: Traps if the components do not form a valid ``URL``.
  var url: URL {
    var components = URLComponents()
    components.host = urlHost
    components.port = urlPort
    components.path = urlPath
    components.queryItems = urlQueryItems.isEmpty ? nil : urlQueryItems.map {
      URLQueryItem(name: $0.key, value: $0.value)
    }
    components.scheme = urlScheme

    guard let url = components.url else {
      preconditionFailure("ComponentEndpoint properties do not form a valid URL")
    }
    return url
  }
}
