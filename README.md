# HTTPClient

A lightweight Swift package providing a generic, protocol-driven HTTP client. It offers a simple `Endpoint` abstraction (finished URL, method, headers, body), a `ComponentEndpoint` for assembling a URL from pieces, automatic JSON encoding/decoding with customizable strategies, and built-in logging for requests and responses.

## Features

* Define endpoints by conforming to `Endpoint` with a finished `URL`.
* Conform to `ComponentEndpoint` when the URL should be assembled from host, path, port, query, and scheme.
* Automatic construction of `URLRequest` from endpoint properties.
* Async/await support for executing requests on Apple platforms and Linux.
* Combine publisher support for executing requests on Apple platforms.
* Configurable JSON encoder/decoder strategies via the `CustomEncodable`/`CustomDecodable` protocols.
* Structured `HTTPError` payload handling.
* Built-in logger with levels (`none`, `error`, `info`, `debug`, `trace`) controllable via `LOG_LEVEL` environment variable or Info.plist entry.

## Getting Started

Add the package to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/iliaskarim/HTTPClient.git", from: "2.1.0")
]
```

Then import the module:

```swift
import HTTPClient
```

### Defining an Endpoint

When the caller already has a finished URL, store it on `Endpoint`:

```swift
struct FetchFileEndpoint: Endpoint {
    typealias Response = Data

    let url: URL
}
```

When the URL should be assembled from pieces, conform to `ComponentEndpoint`:

```swift
struct UserEndpoint: ComponentEndpoint {
    struct Response: Decodable {
        let id: Int
        let name: String
    }

    var urlHost: String {
        "api.example.com"
    }

    var urlPath: String {
        "/users/\(userID)"
    }

    let userID: Int
}
```

For requests with a JSON body, use `Endpoint` with `Request: Encodable` and `let request: Request`.

```swift
struct CreateUserEndpoint: ComponentEndpoint {
    struct Request: Encodable {
        let name: String
    }

    typealias Response = User

    var urlHost: String {
        "api.example.com"
    }

    var urlPath: String {
        "/users"
    }

    let request: Request
}
```

### Executing Requests

Async/await:

```swift
let user: User = try await UserEndpoint(userID: 42).response()
```

Combine:

```swift
let cancellable = UserEndpoint(userID: 42)
    .responsePublisher()
    .sink(receiveCompletion: { print($0) }, receiveValue: { user in
        print(user.name)
    })
```

### Custom Encoding/Decoding Strategies

Conform types to `CustomEncodable`/`CustomDecodable` and provide an array of strategies such as `SnakeCaseKeyEncodingStrategy.shared` or `ISO8601DateDecodingStrategy.shared`.

```swift
struct Item: CustomDecodable {
    static var decodingStrategies: [DecodingStrategy] = [ISO8601DateDecodingStrategy.shared]
    // ...
}
```

### Logging

Verbosity is controlled via a `LOG_LEVEL` setting. The implementation looks first for a `LOG_LEVEL` environment variable, then falls back to an entry with that key in your app’s Info.plist. If neither is present, logging defaults to `none` (no output).

The environment variable takes precedence over the Info.plist value, making it easy to override behaviour at runtime without rebuilding. Accepted values are `none`, `error`, `info`, `debug` and `trace`.

For example:

```bash
export LOG_LEVEL=trace
```

Request/response details and bodies are written to stdout. On Apple platforms, error-level messages are sent to the system logging facility via `os.Logger` so they appear in Console.app and respect system privacy settings. On Linux, error-level messages are written directly to `stderr`.

## Documentation

API documentation is available at [httpclient.iliaskarim.org](https://httpclient.iliaskarim.org/).

## Migrating from 1.x

2.0 is a breaking release. `Endpoint` now requires a finished `URL`. Adopt `ComponentEndpoint` if you still build the URL from host, path, port, query, and scheme.

| 1.x | 2.0 |
|-----|-----|
| Conform to `Endpoint` and supply `urlHost` | Conform to `ComponentEndpoint` (same pieces, default `url`) |
| Split a finished URL into host / path / port / query / scheme | Store `url` on `Endpoint` |
| `PagedEndpoint` / `SortedEndpoint` wrap `Endpoint` pieces | Stay `ComponentEndpoint`; do not wrap URL-only endpoints |

Existing 1.x `Endpoint` conformers that only provided URL pieces will not compile until they adopt `ComponentEndpoint`.

## Testing

Run the test suite with:

```bash
swift test
```

CI runs the same command on Linux (Swift 6.0) and macOS for every pull request.

## Contributing

Contributions are welcome. Please open an issue before large changes so we can align on approach.

1. Fork the repository and create a branch for your change.
2. Run `swiftformat --lint .` and `swiftlint lint --strict .` to match CI style checks.
3. Run `swift build` and `swift test` to confirm everything passes.
4. Match existing code style and add doc comments for new public API.
5. Open a pull request with a short description of what changed and why.

See [ROADMAP.md](ROADMAP.md) for planned changes.

## Platform Support

HTTPClient supports Apple platforms and Linux.

On Linux, the async/await request APIs are supported. Combine-based APIs are available only on Apple platforms.

## License

MIT © Ilias Karim
