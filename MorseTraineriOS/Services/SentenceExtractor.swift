import Foundation

struct SentenceExtractor {

    // Abbreviations that must not be treated as sentence terminators
    private static let abbreviations: Set<String> = [
        // Titles
        "Dr", "Mr", "Mrs", "Ms", "Prof",
        // Common
        "vs", "etc", "Jr", "Sr", "Fig", "No", "St", "Ave", "Blvd",
        "Dept", "Est", "Approx",
        // Corporate
        "Inc", "Ltd", "Corp",
        // Honorifics
        "Gov", "Gen", "Col", "Sgt", "Cpl", "Pvt", "Rep", "Sen", "Rev",
        // Months
        "Jan", "Feb", "Mar", "Apr", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
        // Days
        "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun",
        // Academic / Latin
        "Vol", "pp", "ed", "al", "ie", "eg", "op", "ca", "cf", "et"
    ]

    static func extract(from text: String) -> String {
        let cleaned = clean(text)
        if let sentence = firstSentence(from: cleaned) {
            return sentence
        }
        // Fallback: first 250 characters
        return String(cleaned.prefix(250))
    }

    // MARK: - Private

    private static func clean(_ text: String) -> String {
        var result = text
        // Strip citation brackets like [1], [note 2]
        result = result.replacingOccurrences(of: #"\[\d+\]"#, with: "", options: .regularExpression)
        result = result.replacingOccurrences(of: #"\[.*?\]"#, with: "", options: .regularExpression)
        // Strip HTML tags
        result = result.replacingOccurrences(of: #"<[^>]+>"#, with: "", options: .regularExpression)
        // Collapse extra whitespace
        result = result.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func firstSentence(from text: String) -> String? {
        let terminatorSet: Set<Character> = [".", "!", "?"]
        var start = text.startIndex
        var i = text.startIndex

        while i < text.endIndex {
            let ch = text[i]
            if terminatorSet.contains(ch) {
                // Check it's not an abbreviation
                if ch == "." && isAbbreviationEnd(text: text, dotIndex: i) {
                    i = text.index(after: i)
                    continue
                }
                // Must be followed by space, newline, or end of string
                let next = text.index(after: i)
                let isEnd = next == text.endIndex
                let isFollowedBySpace = !isEnd && (text[next] == " " || text[next] == "\n")

                if isEnd || isFollowedBySpace {
                    let candidate = String(text[start...i]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let wordCount = candidate.split(separator: " ").count
                    if wordCount > 5 {
                        return candidate
                    }
                    // Sentence too short — keep scanning
                    if !isEnd {
                        start = text.index(after: next)
                    }
                }
            }
            i = text.index(after: i)
        }
        return nil
    }

    private static func isAbbreviationEnd(text: String, dotIndex: String.Index) -> Bool {
        // Walk backwards to find the word before the dot
        var j = dotIndex
        var word = ""
        while j > text.startIndex {
            let prev = text.index(before: j)
            let ch = text[prev]
            if ch.isLetter {
                word = String(ch) + word
                j = prev
            } else {
                break
            }
        }
        guard !word.isEmpty else { return false }

        // Single capital letter initial (e.g. "J.")
        if word.count == 1 && word.first!.isUppercase {
            return true
        }

        return abbreviations.contains(word)
    }
}

