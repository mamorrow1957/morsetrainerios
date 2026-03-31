import Foundation

struct ArticleModel {
    let title: String
    let sentence: String
    let url: URL
}

// Decodable struct matching the Wikipedia REST API response
struct WikipediaSummary: Decodable {
    let title: String
    let extract: String
    let contentURLs: ContentURLs

    enum CodingKeys: String, CodingKey {
        case title
        case extract
        case contentURLs = "content_urls"
    }

    struct ContentURLs: Decodable {
        let mobile: MobileURL

        struct MobileURL: Decodable {
            let page: String
        }
    }
}
