import Foundation

enum WikipediaError: LocalizedError {
    case invalidURL
    case httpError(Int)
    case decodingError
    case timeout
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:       return "Invalid URL"
        case .httpError(let c): return "HTTP \(c)"
        case .decodingError:    return "Could not parse response"
        case .timeout:          return "Request timed out"
        case .unknown(let msg): return msg
        }
    }
}

struct WikipediaService {
    private static let endpoint = "https://en.wikipedia.org/api/rest_v1/page/random/summary"

    static func fetchRandomArticle(session: URLSession = .shared) async throws -> WikipediaSummary {
        guard let url = URL(string: endpoint) else { throw WikipediaError.invalidURL }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError where urlError.code == .timedOut {
            throw WikipediaError.timeout
        } catch {
            throw WikipediaError.unknown(error.localizedDescription)
        }

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw WikipediaError.httpError(http.statusCode)
        }

        do {
            return try JSONDecoder().decode(WikipediaSummary.self, from: data)
        } catch {
            throw WikipediaError.decodingError
        }
    }
}
