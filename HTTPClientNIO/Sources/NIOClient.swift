import AsyncHTTPClient

public actor NIOClient {
	public enum Error: Swift.Error {
		case clientShutDown
	}

	public static let shared = NIOClient()

	private let client: HTTPClient

	private var isShutDown = false

	public init(eventLoopGroupProvider: HTTPClient.EventLoopGroupProvider = .singleton) {
		client = HTTPClient(eventLoopGroupProvider: eventLoopGroupProvider)
	}

	public func execute(request: HTTPClient.Request) async throws -> HTTPClient.Response {
		guard !isShutDown else {
			throw Error.clientShutDown
		}

		return try await client.execute(request: request).get()
	}

	public func shutdown() async throws {
		guard !isShutDown else {
			return
		}

		isShutDown = true
		try await client.shutdown()
	}
}
