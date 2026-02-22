import SwiftUI
import UIKit

struct LabelParserTestView: View {
    @State private var testResults: [TestResult] = []
    @State private var isRunning = false
    @State private var ocrResult: OCRTestResult?

    var body: some View {
        NavigationStack {
            List {
                // OCR Test Section
                Section("OCR Test (Real Image)") {
                    if let ocr = ocrResult {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: ocr.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(ocr.success ? .green : .red)
                                Text("OCR + Parse Test")
                                    .font(.headline)
                            }

                            if !ocr.rawText.isEmpty {
                                Text("Raw OCR Text:")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Text(ocr.rawText)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Divider()

                            Text("Parsed Result:")
                                .font(.caption)
                                .fontWeight(.medium)
                            Text("Title: \(ocr.parsedTitle.isEmpty ? "(empty)" : ocr.parsedTitle)")
                                .font(.caption)
                            Text("Author: \(ocr.parsedAuthor.isEmpty ? "(empty)" : ocr.parsedAuthor)")
                                .font(.caption)

                            if !ocr.error.isEmpty {
                                Text("Error: \(ocr.error)")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }
                        .padding(.vertical, 4)
                    } else if isRunning {
                        HStack {
                            ProgressView()
                            Text("Running OCR...")
                        }
                    } else {
                        Text("Tap 'Run Tests' to test OCR")
                            .foregroundStyle(.secondary)
                    }
                }

                // Parser Tests Section
                Section("Parser Tests (Sample Text)") {
                    if isRunning && ocrResult != nil {
                        HStack {
                            ProgressView()
                            Text("Running parser tests...")
                        }
                    }

                    ForEach(testResults) { result in
                        TestResultRow(result: result)
                    }
                }
            }
            .navigationTitle("Parser Tests")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Run Tests") {
                        runTests()
                    }
                    .disabled(isRunning)
                }
            }
            .onAppear {
                if testResults.isEmpty && ocrResult == nil {
                    runTests()
                }
            }
        }
    }

    private func runTests() {
        isRunning = true
        testResults = []
        ocrResult = nil

        Task {
            // First run OCR test on real image
            let ocrTestResult = await performOCRTest()
            await MainActor.run {
                ocrResult = ocrTestResult
            }

            // Then run parser tests
            let results = await performTests()
            await MainActor.run {
                testResults = results
                isRunning = false
            }
        }
    }

    private func performOCRTest() async -> OCRTestResult {
        // Load the test image from app bundle
        guard let imagePath = Bundle.main.path(forResource: "test_label", ofType: "jpg"),
              let image = UIImage(contentsOfFile: imagePath) else {
            return OCRTestResult(
                success: false,
                rawText: "",
                parsedTitle: "",
                parsedAuthor: "",
                error: "Could not load test_label.jpg from bundle"
            )
        }

        do {
            // Run OCR
            let textBlocks = try await OCRService.shared.recognizeText(from: image)
            let rawText = textBlocks
                .sorted { $0.boundingBox.origin.y > $1.boundingBox.origin.y }
                .map { $0.text }
                .joined(separator: "\n")

            // Parse the result
            let parsed = await LabelParserService.shared.parseLabel(from: textBlocks)

            return OCRTestResult(
                success: !parsed.title.isEmpty || !parsed.author.isEmpty,
                rawText: rawText,
                parsedTitle: parsed.title,
                parsedAuthor: parsed.author,
                error: ""
            )
        } catch {
            return OCRTestResult(
                success: false,
                rawText: "",
                parsedTitle: "",
                parsedAuthor: "",
                error: error.localizedDescription
            )
        }
    }

    private func performTests() async -> [TestResult] {
        var results: [TestResult] = []

        // Test 1: Author with dates first
        let sample1 = """
        Vincent van Gogh (1853-1890)
        The Starry Night
        Oil on canvas, 1889
        73.7 cm × 92.1 cm
        This painting depicts the view from Van Gogh's asylum room at Saint-Rémy-de-Provence.
        """
        let result1 = await LabelParserService.shared.parseFullText(sample1)
        results.append(TestResult(
            name: "Author first format",
            expectedTitle: "The Starry Night",
            expectedAuthor: "Vincent van Gogh",
            actualTitle: result1.title,
            actualAuthor: result1.author
        ))

        // Test 2: Title first
        let sample2 = """
        Mona Lisa
        Leonardo da Vinci (1452-1519)
        Oil on poplar panel, c. 1503-1519
        The Mona Lisa is a half-length portrait painting.
        """
        let result2 = await LabelParserService.shared.parseFullText(sample2)
        results.append(TestResult(
            name: "Title first format",
            expectedTitle: "Mona Lisa",
            expectedAuthor: "Leonardo da Vinci",
            actualTitle: result2.title,
            actualAuthor: result2.author
        ))

        // Test 3: Author with nationality
        let sample3 = """
        Pablo Picasso (Spanish, 1881-1973)
        Guernica
        1937, Oil on canvas
        Guernica shows the tragedies of war.
        """
        let result3 = await LabelParserService.shared.parseFullText(sample3)
        results.append(TestResult(
            name: "Author with nationality",
            expectedTitle: "Guernica",
            expectedAuthor: "Pablo Picasso",
            actualTitle: result3.title,
            actualAuthor: result3.author
        ))

        // Test 4: Born format
        let sample4 = """
        Yayoi Kusama
        Born 1929, Japan
        Infinity Mirror Room
        Mixed media installation, 1965
        """
        let result4 = await LabelParserService.shared.parseFullText(sample4)
        results.append(TestResult(
            name: "Born format",
            expectedTitle: "Infinity Mirror Room",
            expectedAuthor: "Yayoi Kusama",
            actualTitle: result4.title,
            actualAuthor: result4.author
        ))

        // Test 5: Nationality on separate line
        let sample5 = """
        Water Lilies
        Claude Monet
        French, 1840-1926
        Oil on canvas, 1906
        """
        let result5 = await LabelParserService.shared.parseFullText(sample5)
        results.append(TestResult(
            name: "Nationality separate line",
            expectedTitle: "Water Lilies",
            expectedAuthor: "Claude Monet",
            actualTitle: result5.title,
            actualAuthor: result5.author
        ))

        // Test 6: Real museum label - Dutch format (Author first, dates on separate line)
        let sample6 = """
        Paulus Potter
        Enkhuizen 1625-1654 Amsterdam
        Cattle in a Meadow, 1652
        Oil on panel
        Acquired by Prince William V, 1768 (inv. no. 138)
        """
        let result6 = await LabelParserService.shared.parseFullText(sample6)
        results.append(TestResult(
            name: "Dutch museum format",
            expectedTitle: "Cattle in a Meadow",
            expectedAuthor: "Paulus Potter",
            actualTitle: result6.title,
            actualAuthor: result6.author
        ))

        return results
    }
}

struct TestResult: Identifiable {
    let id = UUID()
    let name: String
    let expectedTitle: String
    let expectedAuthor: String
    let actualTitle: String
    let actualAuthor: String

    var titlePassed: Bool { actualTitle == expectedTitle }
    var authorPassed: Bool { actualAuthor == expectedAuthor }
    var allPassed: Bool { titlePassed && authorPassed }
}

struct OCRTestResult {
    let success: Bool
    let rawText: String
    let parsedTitle: String
    let parsedAuthor: String
    let error: String
}

struct TestResultRow: View {
    let result: TestResult
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation { isExpanded.toggle() }
            } label: {
                HStack {
                    Image(systemName: result.allPassed ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(result.allPassed ? .green : .red)
                    Text(result.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    // Title section
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("Title:")
                                .fontWeight(.medium)
                            Image(systemName: result.titlePassed ? "checkmark" : "xmark")
                                .foregroundStyle(result.titlePassed ? .green : .red)
                        }
                        Text("Expected: \(result.expectedTitle)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Actual: \(result.actualTitle.isEmpty ? "(empty)" : result.actualTitle)")
                            .font(.caption)
                            .foregroundColor(result.titlePassed ? .secondary : .red)
                    }

                    // Author section
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("Author:")
                                .fontWeight(.medium)
                            Image(systemName: result.authorPassed ? "checkmark" : "xmark")
                                .foregroundStyle(result.authorPassed ? .green : .red)
                        }
                        Text("Expected: \(result.expectedAuthor)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Actual: \(result.actualAuthor.isEmpty ? "(empty)" : result.actualAuthor)")
                            .font(.caption)
                            .foregroundColor(result.authorPassed ? .secondary : .red)
                    }
                }
                .padding(.leading)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    LabelParserTestView()
}
