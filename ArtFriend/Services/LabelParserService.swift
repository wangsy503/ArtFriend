import Foundation
import NaturalLanguage
#if canImport(FoundationModels)
import FoundationModels
#endif

struct ParsedLabel {
    var title: String
    var author: String
    var background: String
    var interpretation: String
}

#if canImport(FoundationModels)
struct ArtworkLabelInfo: Codable {
    let title: String?
    let author: String?
    let background: String?
    let interpretation: String?
}
#endif

actor LabelParserService {
    static let shared = LabelParserService()

    private init() {}

    func parseLabel(from textBlocks: [RecognizedTextBlock]) async -> ParsedLabel {
        guard !textBlocks.isEmpty else {
            return ParsedLabel(title: "", author: "", background: "", interpretation: "")
        }

        let sortedBlocks = textBlocks.sorted { $0.boundingBox.origin.y > $1.boundingBox.origin.y }
        let fullText = sortedBlocks.map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }.joined(separator: "\n")

        return await parseFullText(fullText)
    }

    func parseFullText(_ text: String) async -> ParsedLabel {
        guard !text.isEmpty else {
            return ParsedLabel(title: "", author: "", background: "", interpretation: "")
        }

        #if canImport(FoundationModels)
        // Use Apple Intelligence
        if let result = await parseWithFoundationModels(text) {
            return result
        }
        #endif

        // Fallback to heuristic parsing
        return parseWithHeuristics(text)
    }

    #if canImport(FoundationModels)
    private func parseWithFoundationModels(_ text: String) async -> ParsedLabel? {
        do {
            let model = SystemLanguageModel.default
            guard model.isAvailable else {
                return nil
            }

            let session = LanguageModelSession()

            let prompt = """
            Extract information from this museum artwork label. Return a JSON object with these fields:
            - title: the artwork title (may be in quotes or italics)
            - author: the artist's name (without birth/death dates)
            - background: historical context or description of the artwork
            - interpretation: how to understand or appreciate the artwork

            If a field cannot be determined, use null.

            Label text:
            \(text)

            Return only valid JSON, no other text.
            """

            let response = try await session.respond(to: prompt)
            let responseText = response.content

            if let jsonData = responseText.data(using: .utf8) {
                let decoder = JSONDecoder()
                let info = try decoder.decode(ArtworkLabelInfo.self, from: jsonData)

                return ParsedLabel(
                    title: info.title ?? "",
                    author: info.author ?? "",
                    background: info.background ?? "",
                    interpretation: info.interpretation ?? ""
                )
            }
        } catch {
            print("Foundation Models parsing failed: \(error)")
        }
        return nil
    }
    #endif

    private func parseWithHeuristics(_ text: String) -> ParsedLabel {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !lines.isEmpty else {
            return ParsedLabel(title: "", author: "", background: "", interpretation: "")
        }

        var authorIndex: Int? = nil
        var author = ""

        // First, look for author line with dates in parentheses (e.g., "Van Gogh (1853-1890)")
        for (index, line) in lines.enumerated() {
            if looksLikeAuthorLineWithParentheses(line) {
                authorIndex = index
                author = extractAuthorName(from: line)
                break
            }
        }

        // If not found, look for bio line pattern (e.g., "Enkhuizen 1625-1654 Amsterdam")
        // In this case, author is likely on the line before
        if author.isEmpty {
            for (index, line) in lines.enumerated() {
                if looksLikeBioLine(line) && index > 0 {
                    // Author is the line before the bio line
                    let authorLine = lines[index - 1]
                    if containsPersonName(authorLine) || authorLine.count < 50 {
                        authorIndex = index - 1
                        author = authorLine
                        break
                    }
                }
            }
        }

        // Fallback: look for any line with dates
        if author.isEmpty {
            for (index, line) in lines.enumerated() {
                if looksLikeAuthorLine(line) {
                    authorIndex = index
                    author = extractAuthorName(from: line)
                    break
                }
            }
        }

        // Last resort: look for person names
        if author.isEmpty {
            for (index, line) in lines.enumerated() {
                if line.count < 80 && containsPersonName(line) && !looksLikeTitleLine(line) {
                    authorIndex = index
                    author = extractAuthorName(from: line)
                    break
                }
            }
        }

        var title = ""
        var titleIndex: Int? = nil

        if let authIdx = authorIndex {
            if authIdx > 0 {
                let candidateLine = lines[authIdx - 1]
                if looksLikeTitleLine(candidateLine) {
                    title = cleanTitle(candidateLine)
                    titleIndex = authIdx - 1
                }
            }
            if title.isEmpty && authIdx < lines.count - 1 {
                let candidateLine = lines[authIdx + 1]
                if looksLikeTitleLine(candidateLine) {
                    title = cleanTitle(candidateLine)
                    titleIndex = authIdx + 1
                }
            }
        }

        if title.isEmpty {
            for (index, line) in lines.enumerated() {
                if index != authorIndex && looksLikeTitleLine(line) {
                    title = cleanTitle(line)
                    titleIndex = index
                    break
                }
            }
        }

        var backgroundParagraphs: [String] = []
        var interpretationParagraphs: [String] = []

        for (index, line) in lines.enumerated() {
            if index == authorIndex || index == titleIndex {
                continue
            }
            if line.count < 30 {
                continue
            }
            if backgroundParagraphs.count < 2 {
                backgroundParagraphs.append(line)
            } else {
                interpretationParagraphs.append(line)
            }
        }

        return ParsedLabel(
            title: title,
            author: author,
            background: backgroundParagraphs.joined(separator: "\n\n"),
            interpretation: interpretationParagraphs.joined(separator: "\n\n")
        )
    }

    private func looksLikeAuthorLine(_ text: String) -> Bool {
        let datePattern = #"\(\d{4}\s*[-–—]\s*\d{4}\)"#
        let birthDeathPattern = #"\d{4}\s*[-–—]\s*\d{4}"#
        let bornPattern = #"(?i)\b(born|b\.)\s*\d{4}"#
        let diedPattern = #"(?i)\b(died|d\.)\s*\d{4}"#

        return text.range(of: datePattern, options: .regularExpression) != nil ||
               text.range(of: birthDeathPattern, options: .regularExpression) != nil ||
               text.range(of: bornPattern, options: .regularExpression) != nil ||
               text.range(of: diedPattern, options: .regularExpression) != nil
    }

    // Matches "Name (1853-1890)" format specifically
    private func looksLikeAuthorLineWithParentheses(_ text: String) -> Bool {
        let datePattern = #"\(\d{4}\s*[-–—]\s*\d{4}\)"#
        return text.range(of: datePattern, options: .regularExpression) != nil
    }

    // Matches "Place 1625-1654 Place" format - biographical info line
    // e.g., "Enkhuizen 1625-1654 Amsterdam"
    private func looksLikeBioLine(_ text: String) -> Bool {
        // Pattern: word(s), dates, word(s) - dates NOT in parentheses
        let bioPattern = #"^[A-Z][a-z]+.*\d{4}\s*[-–—]\s*\d{4}.*[A-Z][a-z]+$"#
        if text.range(of: bioPattern, options: .regularExpression) != nil {
            // Make sure dates are NOT in parentheses
            let parenDatePattern = #"\(\d{4}\s*[-–—]\s*\d{4}\)"#
            return text.range(of: parenDatePattern, options: .regularExpression) == nil
        }
        return false
    }

    private func looksLikeTitleLine(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.count < 2 || trimmed.count > 120 {
            return false
        }
        if looksLikeAuthorLine(trimmed) {
            return false
        }

        let dimensionPattern = #"\d+\s*[x×]\s*\d+"#
        if trimmed.range(of: dimensionPattern, options: .regularExpression) != nil {
            return false
        }

        let excludeKeywords = ["oil on canvas", "acrylic", "watercolor", "bronze", "marble",
                               "photograph", "lithograph", "collection", "gift of", "bequest",
                               "museum", "gallery"]
        let lowercased = trimmed.lowercased()

        for keyword in excludeKeywords {
            if lowercased.contains(keyword) {
                return false
            }
        }

        return true
    }

    private func cleanTitle(_ text: String) -> String {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove surrounding quotes if present
        if (cleaned.hasPrefix("\"") && cleaned.hasSuffix("\"")) ||
           (cleaned.hasPrefix("'") && cleaned.hasSuffix("'")) {
            cleaned = String(cleaned.dropFirst().dropLast())
        }

        // Remove trailing year (e.g., ", 1652" or " 1889")
        let trailingYearPattern = #"[,\s]+\d{4}\s*$"#
        cleaned = cleaned.replacingOccurrences(of: trailingYearPattern, with: "", options: .regularExpression)

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func containsPersonName(_ text: String) -> Bool {
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text

        var foundName = false
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType) { tag, _ in
            if tag == .personalName {
                foundName = true
                return false
            }
            return true
        }

        return foundName
    }

    private func extractAuthorName(from text: String) -> String {
        var cleaned = text
        let patterns = [
            #"\s*\(\d{4}\s*[-–—]\s*(\d{4}|present)\)"#,
            #",?\s*\d{4}\s*[-–—]\s*(\d{4}|present)"#,
            #"(?i),?\s*(born|b\.)\s*\d{4}"#,
            #"\s*\([^)]*\)"#
        ]

        for pattern in patterns {
            cleaned = cleaned.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
        }

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
