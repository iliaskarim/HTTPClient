/// An HTTP error that exposes its response status code.
///
/// Existential casting (`as? any HTTPFailure`) works across ``HTTPError``
/// specializations so callers can handle status without knowing the payload
/// type.
public protocol HTTPFailure: Error {
  /// The HTTP status code of the error response.
  var statusCode: Int { get }
}
