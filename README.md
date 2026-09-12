# HTTPClient

A lightweight Swift package providing a generic, protocol-driven HTTP client. It offers a simple `Endpoint` abstraction, automatic JSON encoding/decoding with customizable strategies, and built-in logging for requests and responses.

## Features

* Define endpoints by conforming to `Endpoint`.
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

For requests with a JSON body, use `Endpoint` with `Request: Encodable` and
`let request: Request`.

```swift
struct CreateUserEndpoint: Endpoint {
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

## Testing

Run the test suite with:

```bash
swift test
```

## Contributing

Contributions are welcome. Please open an issue before large changes so we can align on approach.

1. Fork the repository and create a branch for your change.
2. Run `swift build` and `swift test` to confirm everything passes.
3. Match existing code style and add doc comments for new public API.
4. Open a pull request with a short description of what changed and why.

See [ROADMAP.md](ROADMAP.md) for planned changes.

## Documentation

The public API is hosted at [httpclient.iliaskarim.org](https://httpclient.iliaskarim.org/). Merges (and pushes) to `main` run [`.github/workflows/deploy-docs.yml`](.github/workflows/deploy-docs.yml), which builds DocC and uploads it to S3. You can also trigger **Deploy docs** manually from the Actions tab.

To rebuild the site locally (macOS with Xcode installed):

```bash
./scripts/build-docs
```

Output is written to `./docs` (not committed). Serve it with:

```bash
python3 -m http.server --directory ./docs
```

To publish a local build (requires the [AWS CLI](https://aws.amazon.com/cli/) and credentials that can write the bucket):

```bash
./scripts/upload-docs
```

Defaults to `s3://httpclient.iliaskarim.org` and CloudFront distribution `E3ELNGKSYELRW6` (invalidates `/*` after each sync). Override with `HTTPCLIENT_S3_BUCKET`, `CLOUDFRONT_DISTRIBUTION_ID`, or `AWS_PROFILE` if needed.

### One-time GitHub → AWS setup (OIDC)

1. In IAM, create an identity provider for GitHub OIDC if you do not already have one:
   - Provider URL: `https://token.actions.githubusercontent.com`
   - Audience: `sts.amazonaws.com`
2. Create an IAM role trusted by that provider, or add this repository to an existing GitHub OIDC role. Trust policy (adjust account as needed):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:iliaskarim/HTTPClient:*"
        }
      }
    }
  ]
}
```

3. Attach a policy that allows syncing the docs bucket and invalidating CloudFront, for example:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": "arn:aws:s3:::httpclient.iliaskarim.org"
    },
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"],
      "Resource": "arn:aws:s3:::httpclient.iliaskarim.org/*"
    },
    {
      "Effect": "Allow",
      "Action": ["cloudfront:CreateInvalidation"],
      "Resource": "arn:aws:cloudfront::ACCOUNT_ID:distribution/E3ELNGKSYELRW6"
    }
  ]
}
```

4. In this GitHub repo, add secret `AWS_ROLE_ARN` with that role’s ARN.
5. Optional: set repository variable `AWS_REGION` (defaults to `us-east-1`).

## Platform Support

HTTPClient supports Apple platforms and Linux.

On Linux, the async/await request APIs are supported. Combine-based APIs are available only on Apple platforms.

## License

MIT © Ilias Karim
