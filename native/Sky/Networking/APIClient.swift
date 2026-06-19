import Foundation

// Talks to the existing Next.js backend (`app/api/*`). Dev points at localhost;
// later this base URL becomes the deployed Vercel origin so iPhone works remotely.

enum APIError: LocalizedError {
    case badURL
    case http(Int)
    case decoding(Error)
    case transport(Error)
    case server(String)

    var errorDescription: String? {
        switch self {
        case .badURL: return "Bad URL"
        case .http(let code): return "HTTP \(code)"
        case .decoding: return "Couldn't read the response"
        case .transport(let e): return e.localizedDescription
        case .server(let msg): return msg
        }
    }
}

enum APIConfig {
    /// Backend origin. Reads `SKY_API_BASE_URL` from Info.plist (set via build
    /// settings for a deployed Vercel origin); defaults to localhost for dev.
    static let baseURL: URL = {
        if let s = Bundle.main.object(forInfoDictionaryKey: "SKY_API_BASE_URL") as? String,
           !s.isEmpty, let url = URL(string: s) {
            return url
        }
        return URL(string: "http://localhost:3000")!
    }()

    /// Optional bearer token for a deployed/protected backend (nil in local dev).
    static let bearerToken: String? = {
        let t = Bundle.main.object(forInfoDictionaryKey: "SKY_API_TOKEN") as? String
        return (t?.isEmpty == false) ? t : nil
    }()
}

actor APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
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
        guard var comps = URLComponents(
            url: APIConfig.baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        ) else { throw APIError.badURL }

        if !query.isEmpty {
            comps.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = comps.url else { throw APIError.badURL }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = APIConfig.bearerToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
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
