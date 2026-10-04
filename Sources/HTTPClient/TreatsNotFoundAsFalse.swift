/// An ``Endpoint`` that treats HTTP 404 as a successful negative (`false`).
///
/// Conforming types must use ``Endpoint/Response`` of `Void`. Use this for
/// existence checks and idempotent deletes where the server uses 404 to mean
/// “already absent.” A 404 is not logged as an error.
///
/// ``response(using:bearerToken:)`` returns `true` on 2xx and `false` on 404.
/// Assign the result; discarding it is unavailable so the inherited Void
/// ``Endpoint/response(using:bearerToken:)`` cannot throw on 404 by accident.
public protocol TreatsNotFoundAsFalse: Endpoint where Response == Void {}
