# HTTPClient

A lightweight Swift package providing a generic, protocol-driven HTTP client. It offers a simple `Endpoint` abstraction, automatic JSON encoding/decoding with customizable strategies, and built-in logging for requests and responses.

## Features

* Define endpoints by conforming to `Endpoint` (or `JSONRequestEndpoint` for POST/PUT with a JSON body).
* Automatic construction of `URLRequest` from endpoint properties.
* Async/await and Combine publisher support for executing requests.
* Configurable JSON encoder/decoder strategies via the `CustomEncodable`/`CustomDecodable` protocols.
* Structured `HTTPError` payload handling.
* Built-in logger with levels (`none`, `error`, `info`, `debug`, `trace`) controllable via `LOG_LEVEL` environment variable or Info.plist entry.

## Getting Started

Add the package to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/iliaskarim/HTTPClient.git", from: "1.0.0")
]
```

Then import the module:

```swift
import HTTPClient
```

### Defining an Endpoint

```swift
struct UserEndpoint: Endpoint {
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

For requests with a JSON body, use `JSONRequestEndpoint`:

```swift
struct CreateUserEndpoint: JSONRequestEndpoint {
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

Request/response details and bodies are written to stdout; all error-level messages are sent to the system logging facility via `os.Logger` so they appear in Console.app and respect system privacy settings.

## Testing

Run the test suite with:

```bash
swift test
```

## License

MIT © Ilias Karim
