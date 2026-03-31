import XCTest
@testable import MorseTraineriOS

final class SentenceExtractorTests: XCTestCase {

    func testExtractsFirstSentence() {
        let text = "This is the first sentence. This is the second sentence."
        let result = SentenceExtractor.extract(from: text)
        XCTAssertEqual(result, "This is the first sentence.")
    }

    func testSkipsShortSentences() {
        let text = "Too short. This is a longer sentence that qualifies."
        let result = SentenceExtractor.extract(from: text)
        XCTAssertEqual(result, "This is a longer sentence that qualifies.")
    }

    func testDoesNotSplitOnAbbreviations() {
        let text = "Dr. Smith went to the store and bought some milk. Second sentence here."
        let result = SentenceExtractor.extract(from: text)
        XCTAssertTrue(result.contains("Dr. Smith"), "Should not split on Dr.")
    }

    func testDoesNotSplitOnInitials() {
        let text = "J. Edgar Hoover was the first director of the FBI. Second sentence."
        let result = SentenceExtractor.extract(from: text)
        XCTAssertTrue(result.contains("J. Edgar"), "Should not split on single initial")
    }

    func testStripsCitationBrackets() {
        let text = "This sentence has a citation[1] in it and is long enough."
        let result = SentenceExtractor.extract(from: text)
        XCTAssertFalse(result.contains("[1]"))
    }

    func testFallbackTo250Chars() {
        // No sentence ending punctuation — should return first 250 chars
        let text = String(repeating: "word ", count: 100)
        let result = SentenceExtractor.extract(from: text)
        XCTAssertLessThanOrEqual(result.count, 250)
    }
}

final class WikipediaServiceTests: XCTestCase {

    func testFetchReturnsArticle() async throws {
        // Live network test — requires internet access
        let summary = try await WikipediaService.fetchRandomArticle()
        XCTAssertFalse(summary.title.isEmpty)
        XCTAssertFalse(summary.extract.isEmpty)
        XCTAssertFalse(summary.contentURLs.mobile.page.isEmpty)
    }
}
