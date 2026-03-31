import Foundation
import SwiftUI

enum AppState {
    case idle, loading, sending, reveal
}

enum Mode {
    case test, learn
}

@MainActor
final class MorseViewModel: ObservableObject {

    // MARK: - Published state

    @Published var appState: AppState = .idle
    @Published var mode: Mode = .test
    @Published var cpm: Int = 100
    @Published var displayText: String = ""
    @Published var morseDone: Bool = false
    @Published var errorText: String? = nil

    // Article data stored after fetch
    private(set) var article: ArticleModel?

    // MARK: - Private

    private let engine = MorseEngine()
    private var learnChars: [Character] = []

    // MARK: - Button action

    func buttonTapped() {
        switch appState {
        case .idle:   findArticle()
        case .sending: stopSending()
        case .reveal:  reveal()
        case .loading: break
        }
    }

    // MARK: - State transitions

    private func findArticle() {
        appState = .loading
        morseDone = false
        displayText = ""
        errorText = nil
        article = nil

        Task {
            do {
                let summary = try await WikipediaService.fetchRandomArticle()
                guard let url = URL(string: summary.contentURLs.mobile.page) else {
                    throw WikipediaError.invalidURL
                }
                let sentence = SentenceExtractor.extract(from: summary.extract)
                article = ArticleModel(title: summary.title, sentence: sentence, url: url)
                beginPlayback(sentence: sentence)
            } catch {
                let reason = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                displayText = "Error fetching article: \(reason)"
                errorText = reason
                appState = .idle
                morseDone = true
            }
        }
    }

    private func beginPlayback(sentence: String) {
        appState = .sending
        morseDone = false

        if mode == .test {
            displayText = "Sending …"
        } else {
            displayText = ""
            learnChars = Array(sentence.uppercased())
        }

        engine.onCharacterStart = { [weak self] index in
            guard let self, self.mode == .learn else { return }
            let chars = self.learnChars
            guard index < chars.count else { return }
            let ch = chars[index]
            if ch == " " {
                self.displayText += " "
            } else {
                self.displayText += String(ch)
            }
        }

        engine.onComplete = { [weak self] in
            guard let self else { return }
            self.displayText = "Send complete…"
            self.morseDone = true
            self.appState = .reveal
        }

        engine.play(sentence: sentence, cpmProvider: { [weak self] in
            self?.cpm ?? 100
        })
    }

    private func stopSending() {
        engine.stop()
        displayText = "Stopped …"
        morseDone = true
        appState = .reveal
    }

    private func reveal() {
        guard let article else {
            appState = .idle
            displayText = ""
            return
        }
        // displayText is set to a structured value the view uses for rendering
        displayText = "Title: \(article.title)\nSentence: \(article.sentence)\nSource: \(article.url.absoluteString)"
        appState = .idle
    }

    // MARK: - Reveal data (for structured display)

    var revealTitle: String? {
        guard appState == .idle, let article else { return nil }
        // Only expose after reveal action has been taken
        if displayText.hasPrefix("Title:") { return article.title }
        return nil
    }

    var revealSentence: String? {
        guard displayText.hasPrefix("Title:"), let article else { return nil }
        return article.sentence
    }

    var revealURL: URL? {
        guard displayText.hasPrefix("Title:"), let article else { return nil }
        return article.url
    }
}
