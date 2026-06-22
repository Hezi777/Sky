import Foundation

// Talks to the bundled localhost-only Next.js backend (`app/api/*`) on macOS.

enum APIError: LocalizedError {
    case badURL
    case backendUnavailable
    case http(Int)
    case decoding(Error)
    case transport(Error)
    case server(String)

    var errorDescription: String? {
        switch self {
        case .badURL: return "Bad URL"
        case .backendUnavailable: return "Sky's local service is unavailable"
        case .http(let code): return "HTTP \(code)"
        case .decoding: return "Couldn't read the response"
        case .transport(let e): return e.localizedDescription
        case .server(let msg): return msg
        }
    }
}

actor APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let decoder: JSONDecoder
    private nonisolated(unsafe) var baseURL: URL?
    private nonisolated let configurationLock = NSLock()

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }

    nonisolated func configure(baseURL: URL?) {
        configurationLock.withLock {
            self.baseURL = baseURL
        }
    }

    func get<T: Decodable>(_ path: String, query: [String: String] = [:]) async throws -> T {
        try await request(path, method: "GET", query: query, body: Optional<Never>.none)
    }

    func post<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> T {
        try await request(path, method: "POST", query: [:], body: body)
    }

    private func request<T: Decodable, B: Encodable>(
        _ path: String,
        method: String,
        query: [String: String],
        body: B?
    ) async throws -> T {
        let configuredBaseURL = configurationLock.withLock { baseURL }
        guard let baseURL = configuredBaseURL else { throw APIError.backendUnavailable }
        guard var comps = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        ) else { throw APIError.badURL }

        if !query.isEmpty {
            comps.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = comps.url else { throw APIError.badURL }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONEncoder().encode(body)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: req)
        } catch {
            throw APIError.transport(error)
        }

        guard let http = response as? HTTPURLResponse else { throw APIError.http(-1) }
        guard (200..<300).contains(http.statusCode) else {
            if let body = try? decoder.decode(APIErrorBody.self, from: data) {
                throw APIError.server(body.error)
            }
            throw APIError.http(http.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }
}
