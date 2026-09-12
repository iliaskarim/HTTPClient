# HTTPClient roadmap

This document outlines planned evolution of the package. **1.0** shipped the
endpoint-first API with URL pieces on `Endpoint`. **2.0** is the breaking
URL-first split: `Endpoint` requires a finished `URL`, and `ComponentEndpoint`
owns host / path / port / query / scheme. **3.0** adds an optional execution
context for shared configuration, authentication, and error hooks, without
taking over concerns that belong in API packages (base URLs, path conventions)
or apps (Keychain, UI session state).

## 1.0 (shipped)

Stable, endpoint-driven API:

- Conform to `Endpoint` to describe URL pieces (host, path, port, query,
  scheme), method, headers, and optional JSON body.
- Execute with `endpoint.response()` / `endpoint.responsePublisher()`.
- Pass `bearerToken` and `URLSession` per call when needed.
- Custom JSON strategies via `CustomEncodable` / `CustomDecodable`.
- Structured failures via `HTTPError` and built-in request/response logging.

`JSONRequestEndpoint` was merged into `Endpoint` (`Request` associated type +
defaults for encodable bodies). That was the breaking change that justified
1.0.

## 2.0 (current)

Breaking protocol split so finished-URL callers and piece-based REST callers
no longer share the same required surface.

- `Endpoint` requires `url`, method, headers, and optional body.
- `ComponentEndpoint` owns `urlHost`, `urlPath`, `urlPort`, `urlQueryItems`,
  and `urlScheme`, with a default `url` that assembles them.
- `request()` builds `URLRequest` from `url` instead of reassembling from
  pieces.

### Migration

| 1.x | 2.0 |
|-----|-----|
| Conform to `Endpoint` and supply `urlHost` | Conform to `ComponentEndpoint` (same pieces, default `url`) |
| Split a finished URL into host / path / port / query / scheme | Store `url` on `Endpoint` |
| `PagedEndpoint` / `SortedEndpoint` wrap `Endpoint` pieces | Stay `ComponentEndpoint`; do not wrap URL-only endpoints |

Existing 1.x `Endpoint` conformers that only provided URL pieces will not
compile until they adopt `ComponentEndpoint`.

## 3.0 (planned)

Introduce a small **coordinator type** (working name `Client`, alternatives
`APIClient` or `Session`) that owns shared request context and centralizes
execution. Endpoints remain the primary abstraction. The coordinator is
optional sugar for apps that today wrap every call (e.g.,
`UserSession.response(for:)` + manual `bearerToken` threading).

### Goals

- Inject **bearer token** (or a token provider) once instead of on every
  `response(bearerToken:)`.
- Own a **`URLSession`** instance for testing and configuration.
- Invoke **`onHTTPError`** / **`onUnauthorized`** hooks so apps can react to
  non-2xx responses (logout, refresh, analytics) without reimplementing
  try/catch around every call.
- Provide **`response(for:)`** (and Combine equivalents) mirroring today’s
  `Endpoint` extensions.
- Keep **2.x call sites working**: `Endpoint.response(bearerToken:)` remains
  available. Migration is opt-in.

### Out of scope for HTTPClient

These stay in downstream packages or the app layer (see
[GitHubClient](https://github.com/iliaskarim/GitHubClient) usage):

| Concern | Example in the wild |
|--------|---------------------|
| API base URL / host | `GitHubEndpoint.urlHost` → `"api.github.com"` |
| Path prefixes and API shape | `GitHubReposEndpoint`, `GitHubCurrentUserEndpoint` |
| Pagination wrappers | `PagedEndpoint` in GitHubAPI |
| Token persistence | `AccessTokenStore` (Keychain) |
| Session UI and lifecycle | `@MainActor` `UserSession`, `sessionExpired`, `@Published` user |
| App-specific HTTP semantics | Void overload treating 404 as `false`, markdown rendering helpers |
| DEBUG delays / fault injection | `DEBUG_HTTP_DELAY_SECONDS`, etc. |

### Proposed API (draft)

```swift
public struct Client: Sendable {
  public var session: URLSession
  public var bearerToken: String?
  /// Called for every non-2xx response after ``HTTPError`` is constructed.
  public var onHTTPError: (@Sendable (HTTPError) -> Void)?
  /// Called when ``HTTPError``.``statusCode`` is 401 (convenience over filtering in ``onHTTPError``).
  public var onUnauthorized: (@Sendable (HTTPError) -> Void)?

  public init(
    session: URLSession = .shared,
    bearerToken: String? = nil,
    onHTTPError: (@Sendable (HTTPError) -> Void)? = nil,
    onUnauthorized: (@Sendable (HTTPError) -> Void)? = nil
  )

  public func response<E: Endpoint>(for endpoint: E) async throws -> E.Response
    where E.Response: Decodable

  public func response<E: Endpoint>(for endpoint: E) async throws
    where E.Response == Void

  // Combine mirrors when canImport(Combine)
}
```

**Hook behavior (intended):**

1. Response is received. If status is non-2xx, build `HTTPError` (same as today).
2. If `onHTTPError` is set, call it with the error (before rethrowing).
3. If status is 401 and `onUnauthorized` is set, call it in addition to or instead of filtering in app code. Exact order is TBD. Likely both fire for 401 when both are set.
4. Rethrow `HTTPError` so callers can still handle errors locally.

Apps wire logout without the library touching Keychain:

```swift
let client = Client(
  bearerToken: accessToken,
  onUnauthorized: { _ in
    accessTokenStore.deleteAccessToken()
    sessionExpired.send()
  }
)

let user = try await client.response(for: FetchCurrentUserDetailEndpoint())
```

### Optional follow-ups (3.0 or later)

- **`bearerToken` as `@Sendable () -> String?`** for refresh flows without recreating the client.
- **Default URL components** on the client (host/scheme/port) merged with endpoint properties, for staging vs production without duplicating every endpoint. Not required if API packages keep host defaults (e.g., `GitHubEndpoint`).
- **Deprecate** per-call `bearerToken` on `Endpoint.response` in favor of `Client` only if we want a single recommended style (soft deprecation in 3.0, removal in 4.0).

### Migration (GitHubClient-shaped)

| Today | After 3.0 |
|-------|-----------|
| `GitHubEndpoint` provides `urlHost` | Unchanged (`ComponentEndpoint` in GitHubAPI) |
| `UserSession.response(for:)` + 401 handling | Thin wrapper (Keychain + UI), delegating to `Client` |
| `endpoint.response(bearerToken:)` | `client.response(for: endpoint)` or keep 2.x API |

## Versioning

| Version | Theme |
|---------|--------|
| **1.0** | Stable `Endpoint`-first API with URL pieces, Linux and Apple, docs and logging |
| **2.0** | URL-first `Endpoint` + `ComponentEndpoint` |
| **3.0** | Optional `Client`, shared token/session, `onHTTPError` / `onUnauthorized` |
| **4.0** | Only if we remove per-call `bearerToken` or make other breaking changes |

## Open questions

1. **Type name:** `Client` (`HTTPClient.Client`) vs `APIClient` vs `Session`.
2. **Hook order:** Call `onHTTPError` for all non-2xx, then `onUnauthorized` only for 401, or document that 401 triggers both.
3. **Combine:** Same hooks on the publisher path, and ensure the hook runs on failure before downstream `sink`.
4. **Sendable / actors:** `Client` as a `Sendable` struct. Document that hooks must not assume main actor unless the app dispatches internally.
