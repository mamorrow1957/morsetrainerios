import XCTest
@testable import MorseTraineriOS

// MARK: - SentenceExtractor Tests

final class SentenceExtractorTests: XCTestCase {

    // MARK: Existing tests

    func testExtractsFirstSentence() {
        let text = "This is the first complete sentence here. This is the second sentence."
        XCTAssertEqual(SentenceExtractor.extract(from: text),
                       "This is the first complete sentence here.")
    }

    func testSkipsShortSentences() {
        let text = "Too short. This is a longer sentence that qualifies."
        XCTAssertEqual(SentenceExtractor.extract(from: text),
                       "This is a longer sentence that qualifies.")
    }

    func testDoesNotSplitOnAbbreviations() {
        let text = "Dr. Smith went to the store and bought some milk. Second sentence here."
        XCTAssertTrue(SentenceExtractor.extract(from: text).contains("Dr. Smith"),
                      "Should not split on Dr.")
    }

    func testDoesNotSplitOnInitials() {
        let text = "J. Edgar Hoover was the first director of the FBI. Second sentence."
        XCTAssertTrue(SentenceExtractor.extract(from: text).contains("J. Edgar"),
                      "Should not split on single initial")
    }

    func testStripsCitationBrackets() {
        let text = "This sentence has a citation[1] in it and is long enough."
        XCTAssertFalse(SentenceExtractor.extract(from: text).contains("[1]"))
    }

    func testFallbackTo250Chars() {
        let text = String(repeating: "word ", count: 100)
        XCTAssertLessThanOrEqual(SentenceExtractor.extract(from: text).count, 250)
    }

    // MARK: Terminator variants

    func testExtractsExclamationSentence() {
        let text = "What an incredible discovery this turned out to be! Second sentence follows here."
        XCTAssertTrue(SentenceExtractor.extract(from: text).hasSuffix("!"),
                      "Should extract sentence ending with !")
    }

    func testExtractsQuestionSentence() {
        let text = "How did this remarkable event come to pass in history? A second sentence follows here."
        XCTAssertTrue(SentenceExtractor.extract(from: text).hasSuffix("?"),
                      "Should extract sentence ending with ?")
    }

    // MARK: Abbreviation coverage

    func testDoesNotSplitOnInc() {
        let text = "Apple Inc. became the most valuable technology company in the entire world by market cap."
        XCTAssertTrue(SentenceExtractor.extract(from: text).contains("Inc."))
    }

    func testDoesNotSplitOnLtd() {
        let text = "Trading Ltd. was founded in London and became very well known worldwide for its services."
        XCTAssertTrue(SentenceExtractor.extract(from: text).contains("Ltd."))
    }

    func testDoesNotSplitOnCorp() {
        let text = "General Motors Corp. was one of the largest automakers in the world for many decades."
        XCTAssertTrue(SentenceExtractor.extract(from: text).contains("Corp."))
    }

    func testDoesNotSplitOnGov() {
        let text = "Gov. Smith announced the new policy during a press conference held in the capital city."
        XCTAssertTrue(SentenceExtractor.extract(from: text).contains("Gov."))
    }

    func testDoesNotSplitOnMonthAbbreviation() {
        let text = "The historic event took place on Jan. 15 and was attended by thousands of people worldwide."
        XCTAssertTrue(SentenceExtractor.extract(from: text).contains("Jan."))
    }

    func testDoesNotSplitOnDayAbbreviation() {
        let text = "The weekly meeting was held on Mon. afternoon and lasted several hours until everyone agreed."
        XCTAssertTrue(SentenceExtractor.extract(from: text).contains("Mon."))
    }

    func testDoesNotSplitOnVs() {
        let text = "The case of Smith vs. Jones was the most important legal battle in the history of the court."
        XCTAssertTrue(SentenceExtractor.extract(from: text).contains("vs."))
    }

    func testDoesNotSplitOnEtc() {
        let text = "The store sold apples, oranges, bananas, etc. and was open seven days a week all year long."
        XCTAssertTrue(SentenceExtractor.extract(from: text).contains("etc."))
    }

    // MARK: Edge cases

    func testSentenceTerminatedAtEndOfString() {
        let text = "This is a long enough sentence that ends right at the very end of the string."
        XCTAssertEqual(SentenceExtractor.extract(from: text), text)
    }

    func testMultipleShortSentencesBeforeQualifying() {
        let text = "Too short. Also short. This is a much longer sentence that definitely qualifies as valid."
        XCTAssertTrue(SentenceExtractor.extract(from: text).contains("longer sentence"))
    }

    func testStripsHTMLTags() {
        let text = "<b>Bold text</b> and this is a long enough sentence to qualify for extraction purposes."
        let result = SentenceExtractor.extract(from: text)
        XCTAssertFalse(result.contains("<b>"))
        XCTAssertFalse(result.contains("</b>"))
    }

    func testStripsCitationBracketsWithText() {
        let text = "This sentence has a citation[note 2] in it and is definitely long enough to qualify."
        XCTAssertFalse(SentenceExtractor.extract(from: text).contains("[note 2]"))
    }

    func testEmptyStringReturnsEmpty() {
        XCTAssertEqual(SentenceExtractor.extract(from: ""), "")
    }

    func testWhitespaceOnlyReturnsEmpty() {
        XCTAssertEqual(SentenceExtractor.extract(from: "   \n  \t  "), "")
    }
}

// MARK: - MorseEngine Tests

final class MorseEngineTests: XCTestCase {

    func testStopBeforePlayDoesNotCrash() {
        let engine = MorseEngine()
        engine.stop()
    }

    func testMultipleStopCallsDoNotCrash() {
        let engine = MorseEngine()
        engine.stop()
        engine.stop()
        engine.stop()
    }

    func testOnCompleteFiresAfterPlayback() async {
        let engine = MorseEngine()
        let done = XCTestExpectation(description: "onComplete fires")
        engine.onComplete = { done.fulfill() }
        engine.play(sentence: "E", cpmProvider: { 150 })   // single dot — very fast
        await fulfillment(of: [done], timeout: 5.0)
    }

    func testOnCharacterStartFiresForEachCharacter() async {
        let engine = MorseEngine()
        var firedIndices: [Int] = []
        let started = XCTestExpectation(description: "both characters started")
        started.expectedFulfillmentCount = 2
        let done = XCTestExpectation(description: "playback complete")

        engine.onCharacterStart = { index in
            firedIndices.append(index)
            started.fulfill()
        }
        engine.onComplete = { done.fulfill() }
        engine.play(sentence: "HI", cpmProvider: { 150 })

        await fulfillment(of: [started, done], timeout: 5.0)
        XCTAssertEqual(firedIndices.sorted(), [0, 1])
    }

    func testStopPreventsOnCompleteCallback() async {
        let engine = MorseEngine()
        var completedNaturally = false
        engine.onComplete = { completedNaturally = true }

        // Use slow speed so the sentence takes several seconds
        engine.play(sentence: "HELLO WORLD", cpmProvider: { 50 })

        // Stop almost immediately — well before playback could finish
        try? await Task.sleep(nanoseconds: 100_000_000)   // 0.1 s
        engine.stop()

        // Wait long enough to be certain onComplete has not fired
        try? await Task.sleep(nanoseconds: 1_000_000_000)  // 1.0 s
        XCTAssertFalse(completedNaturally, "onComplete must not fire after stop()")
    }

    func testRestartAfterStop() async {
        let engine = MorseEngine()
        engine.play(sentence: "HELLO WORLD", cpmProvider: { 50 })
        try? await Task.sleep(nanoseconds: 100_000_000)
        engine.stop()

        let done = XCTestExpectation(description: "second play completes")
        engine.onComplete = { done.fulfill() }
        engine.play(sentence: "E", cpmProvider: { 150 })
        await fulfillment(of: [done], timeout: 5.0)
    }
}

// MARK: - WikipediaSummary Decoding Tests

final class WikipediaSummaryDecodingTests: XCTestCase {

    private let validJSON = """
    {
        "title": "Albert Einstein",
        "extract": "Albert Einstein was a German-born theoretical physicist.",
        "content_urls": {
            "mobile": { "page": "https://en.m.wikipedia.org/wiki/Albert_Einstein" }
        }
    }
    """.data(using: .utf8)!

    func testDecodeValidJSON() throws {
        let summary = try JSONDecoder().decode(WikipediaSummary.self, from: validJSON)
        XCTAssertEqual(summary.title, "Albert Einstein")
        XCTAssertFalse(summary.extract.isEmpty)
        XCTAssertEqual(summary.contentURLs.mobile.page,
                       "https://en.m.wikipedia.org/wiki/Albert_Einstein")
    }

    func testDecodeMissingTitleFails() {
        let json = """
        {
            "extract": "Some text.",
            "content_urls": { "mobile": { "page": "https://example.com" } }
        }
        """.data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(WikipediaSummary.self, from: json))
    }

    func testDecodeMissingExtractFails() {
        let json = """
        {
            "title": "Test",
            "content_urls": { "mobile": { "page": "https://example.com" } }
        }
        """.data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(WikipediaSummary.self, from: json))
    }

    func testDecodeMissingContentURLsFails() {
        let json = """
        { "title": "Test", "extract": "Some text." }
        """.data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(WikipediaSummary.self, from: json))
    }
}

// MARK: - Mock URL Protocol

private final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

// MARK: - WikipediaService Mock Tests

final class WikipediaServiceMockTests: XCTestCase {

    private var mockSession: URLSession!

    private let validData = """
    {
        "title": "Test Article",
        "extract": "This is a test article extract with enough content.",
        "content_urls": { "mobile": { "page": "https://en.m.wikipedia.org/wiki/Test" } }
    }
    """.data(using: .utf8)!

    override func setUp() {
        super.setUp()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        mockSession = URLSession(configuration: config)
    }

    private func makeResponse(statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: URL(string: "https://example.com")!,
                        statusCode: statusCode,
                        httpVersion: nil,
                        headerFields: nil)!
    }

    func testFetchSuccessWithMockData() async throws {
        MockURLProtocol.requestHandler = { _ in (self.makeResponse(statusCode: 200), self.validData) }
        let summary = try await WikipediaService.fetchRandomArticle(session: mockSession)
        XCTAssertEqual(summary.title, "Test Article")
        XCTAssertFalse(summary.extract.isEmpty)
    }

    func testFetchThrowsHttpErrorOnNon200() async {
        MockURLProtocol.requestHandler = { _ in (self.makeResponse(statusCode: 404), Data()) }
        do {
            _ = try await WikipediaService.fetchRandomArticle(session: mockSession)
            XCTFail("Expected an error to be thrown")
        } catch let error as WikipediaError {
            guard case .httpError(let code) = error else {
                XCTFail("Expected httpError, got \(error)"); return
            }
            XCTAssertEqual(code, 404)
        } catch {
            XCTFail("Expected WikipediaError, got \(error)")
        }
    }

    func testFetchThrowsDecodingErrorOnMalformedJSON() async {
        MockURLProtocol.requestHandler = { _ in
            (self.makeResponse(statusCode: 200), "not json at all".data(using: .utf8)!)
        }
        do {
            _ = try await WikipediaService.fetchRandomArticle(session: mockSession)
            XCTFail("Expected an error to be thrown")
        } catch let error as WikipediaError {
            guard case .decodingError = error else {
                XCTFail("Expected decodingError, got \(error)"); return
            }
        } catch {
            XCTFail("Expected WikipediaError, got \(error)")
        }
    }

    func testFetchThrowsHttpErrorOn500() async {
        MockURLProtocol.requestHandler = { _ in (self.makeResponse(statusCode: 500), Data()) }
        do {
            _ = try await WikipediaService.fetchRandomArticle(session: mockSession)
            XCTFail("Expected an error to be thrown")
        } catch let error as WikipediaError {
            guard case .httpError(let code) = error else {
                XCTFail("Expected httpError, got \(error)"); return
            }
            XCTAssertEqual(code, 500)
        } catch {
            XCTFail("Expected WikipediaError, got \(error)")
        }
    }
}

// MARK: - WikipediaService Live Test

final class WikipediaServiceLiveTests: XCTestCase {

    func testFetchReturnsArticle() async throws {
        let summary = try await WikipediaService.fetchRandomArticle()
        XCTAssertFalse(summary.title.isEmpty)
        XCTAssertFalse(summary.extract.isEmpty)
        XCTAssertFalse(summary.contentURLs.mobile.page.isEmpty)
    }
}

// MARK: - MorseViewModel Tests

@MainActor
final class MorseViewModelTests: XCTestCase {

    func testInitialState() {
        let vm = MorseViewModel()
        XCTAssertEqual(vm.appState, .idle)
        XCTAssertEqual(vm.mode, .test)
        XCTAssertEqual(vm.cpm, 100)
        XCTAssertTrue(vm.displayText.isEmpty)
        XCTAssertFalse(vm.morseDone)
    }

    func testModeChangeRejectedDuringSending() {
        let vm = MorseViewModel()
        vm.mode = .test
        vm.appState = .sending
        vm.mode = .learn
        XCTAssertEqual(vm.mode, .test, "Mode must not change while sending")
    }

    func testModeChangeRejectedDuringLoading() {
        let vm = MorseViewModel()
        vm.mode = .test
        vm.appState = .loading
        vm.mode = .learn
        XCTAssertEqual(vm.mode, .test, "Mode must not change while loading")
    }

    func testModeChangeAllowedWhenIdle() {
        let vm = MorseViewModel()
        vm.appState = .idle
        vm.mode = .learn
        XCTAssertEqual(vm.mode, .learn)
    }

    func testModeChangeAllowedDuringReveal() {
        let vm = MorseViewModel()
        vm.appState = .reveal
        vm.mode = .learn
        XCTAssertEqual(vm.mode, .learn)
    }

    func testMorseDoneIsFalseOnInit() {
        XCTAssertFalse(MorseViewModel().morseDone)
    }

    func testRevealTitleIsNilInitially() {
        XCTAssertNil(MorseViewModel().revealTitle)
    }

    func testRevealSentenceIsNilInitially() {
        XCTAssertNil(MorseViewModel().revealSentence)
    }

    func testRevealURLIsNilInitially() {
        XCTAssertNil(MorseViewModel().revealURL)
    }

    func testDisplayTextIsEmptyOnInit() {
        XCTAssertTrue(MorseViewModel().displayText.isEmpty)
    }

    func testErrorTextIsNilOnInit() {
        XCTAssertNil(MorseViewModel().errorText)
    }
}
