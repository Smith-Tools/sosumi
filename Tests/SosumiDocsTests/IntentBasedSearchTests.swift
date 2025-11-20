import XCTest
@testable import SosumiDocs

final class IntentBasedSearchTests: XCTestCase {

    // MARK: - Intent Detection Tests

    func testDetectIntentFromExampleQueries() {
        let client = AppleDocumentationClient()

        // Example intent patterns
        XCTAssertEqual(client.detectIntent(from: "show me example code"), .example)
        XCTAssertEqual(client.detectIntent(from: "how to implement animation"), .example)
        XCTAssertEqual(client.detectIntent(from: "Button sample code"), .example)
        XCTAssertEqual(client.detectIntent(from: "demo of URLSession"), .example)
        XCTAssertEqual(client.detectIntent(from: "implement this feature"), .example)
    }

    func testDetectIntentFromExplainQueries() {
        let client = AppleDocumentationClient()

        // Explain intent patterns
        XCTAssertEqual(client.detectIntent(from: "explain SwiftUI animations"), .explain)
        XCTAssertEqual(client.detectIntent(from: "understand this API"), .explain)
        XCTAssertEqual(client.detectIntent(from: "overview of Combine"), .explain)
        XCTAssertEqual(client.detectIntent(from: "what is async/await"), .explain)
        XCTAssertEqual(client.detectIntent(from: "how does this work"), .explain)
    }

    func testDetectIntentFromReferenceQueries() {
        let client = AppleDocumentationClient()

        // Reference intent patterns
        XCTAssertEqual(client.detectIntent(from: "API reference for Button"), .reference)
        XCTAssertEqual(client.detectIntent(from: "method signatures"), .reference)
        XCTAssertEqual(client.detectIntent(from: "class documentation"), .reference)
        XCTAssertEqual(client.detectIntent(from: "protocol requirements"), .reference)
    }

    func testDetectIntentFromLearnQueries() {
        let client = AppleDocumentationClient()

        // Learn intent patterns
        XCTAssertEqual(client.detectIntent(from: "learn SwiftUI"), .learn)
        XCTAssertEqual(client.detectIntent(from: "tutorial for animations"), .learn)
        XCTAssertEqual(client.detectIntent(from: "step by step guide"), .learn)
        XCTAssertEqual(client.detectIntent(from: "getting started with Combine"), .learn)
        XCTAssertEqual(client.detectIntent(from: "beginner tutorial"), .learn)
    }

    func testDetectIntentDefault() {
        let client = AppleDocumentationClient()

        // Default to all for general queries
        XCTAssertEqual(client.detectIntent(from: "SwiftUI"), .all)
        XCTAssertEqual(client.detectIntent(from: "animation"), .all)
        XCTAssertEqual(client.detectIntent(from: "Button"), .all)
    }

    // MARK: - Intent String Parsing Tests

    func testSearchIntentFromString() {
        XCTAssertEqual(SearchIntent.from(string: "example"), .example)
        XCTAssertEqual(SearchIntent.from(string: "examples"), .example)
        XCTAssertEqual(SearchIntent.from(string: "code"), .example)
        XCTAssertEqual(SearchIntent.from(string: "demo"), .example)

        XCTAssertEqual(SearchIntent.from(string: "explain"), .explain)
        XCTAssertEqual(SearchIntent.from(string: "understand"), .explain)
        XCTAssertEqual(SearchIntent.from(string: "overview"), .explain)

        XCTAssertEqual(SearchIntent.from(string: "reference"), .reference)
        XCTAssertEqual(SearchIntent.from(string: "api"), .reference)
        XCTAssertEqual(SearchIntent.from(string: "technical"), .reference)

        XCTAssertEqual(SearchIntent.from(string: "learn"), .learn)
        XCTAssertEqual(SearchIntent.from(string: "tutorial"), .learn)
        XCTAssertEqual(SearchIntent.from(string: "guide"), .learn)

        XCTAssertEqual(SearchIntent.from(string: "all"), .all)
        XCTAssertEqual(SearchIntent.from(string: "everything"), .all)

        XCTAssertNil(SearchIntent.from(string: "invalid"))
        XCTAssertNil(SearchIntent.from(string: "unknown"))
    }

    // MARK: - Intent-to-Content-Type Mapping Tests

    func testIntentPreferredContentTypes() {
        // Example intent prioritizes sample code and tutorials
        let exampleTypes = SearchIntent.example.preferredContentTypes
        XCTAssertTrue(exampleTypes.contains { $0.0 == .sampleCode && $0.1 == 1.0 })
        XCTAssertTrue(exampleTypes.contains { $0.0 == .tutorial && $0.1 == 0.7 })
        XCTAssertTrue(exampleTypes.contains { $0.0 == .article && $0.1 == 0.3 })

        // Explain intent prioritizes articles and symbols
        let explainTypes = SearchIntent.explain.preferredContentTypes
        XCTAssertTrue(explainTypes.contains { $0.0 == .article && $0.1 == 1.0 })
        XCTAssertTrue(explainTypes.contains { $0.0 == .symbol && $0.1 == 0.8 })
        XCTAssertTrue(explainTypes.contains { $0.0 == .tutorial && $0.1 == 0.4 })

        // Reference intent prioritizes symbols
        let referenceTypes = SearchIntent.reference.preferredContentTypes
        XCTAssertTrue(referenceTypes.contains { $0.0 == .symbol && $0.1 == 1.0 })
        XCTAssertTrue(referenceTypes.contains { $0.0 == .article && $0.1 == 0.3 })

        // Learn intent prioritizes tutorials
        let learnTypes = SearchIntent.learn.preferredContentTypes
        XCTAssertTrue(learnTypes.contains { $0.0 == .tutorial && $0.1 == 1.0 })
        XCTAssertTrue(learnTypes.contains { $0.0 == .sampleCode && $0.1 == 0.6 })
        XCTAssertTrue(learnTypes.contains { $0.0 == .article && $0.1 == 0.5 })

        // All intent gives equal weight to everything
        let allTypes = SearchIntent.all.preferredContentTypes
        XCTAssertEqual(allTypes.count, 4)
        XCTAssertTrue(allTypes.allSatisfy { $0.1 == 1.0 })
    }

    // MARK: - Intent-Based Relevance Tests

    func testCalculateIntentRelevance() {
        let client = AppleDocumentationClient()

        // Example intent should heavily boost sample code
        let exampleBoost = client.calculateIntentRelevance(contentType: .sampleCode, intent: .example)
        XCTAssertEqual(exampleBoost, 100) // 1.0 * 100

        let articleBoostForExample = client.calculateIntentRelevance(contentType: .article, intent: .example)
        XCTAssertEqual(articleBoostForExample, 30) // 0.3 * 100

        // Explain intent should heavily boost articles
        let explainBoost = client.calculateIntentRelevance(contentType: .article, intent: .explain)
        XCTAssertEqual(explainBoost, 100) // 1.0 * 100

        let symbolBoostForExplain = client.calculateIntentRelevance(contentType: .symbol, intent: .explain)
        XCTAssertEqual(symbolBoostForExplain, 80) // 0.8 * 100

        // No boost for non-matching combinations
        let noBoost = client.calculateIntentRelevance(contentType: .tutorial, intent: .reference)
        XCTAssertEqual(noBoost, 0)
    }

    // MARK: - Filter Integration Tests

    func testContentTypeFilterWithIntent() {
        var filter = ContentTypeFilter(intent: .example)

        XCTAssertNotNil(filter.intent)
        XCTAssertEqual(filter.intent, .example)

        // Should still support other options
        filter.contentType = .article
        filter.requiresPlatforms = ["iOS 15+"]
        filter.maxTimeEstimate = 30

        XCTAssertEqual(filter.contentType, .article)
        XCTAssertEqual(filter.requiresPlatforms, ["iOS 15+"])
        XCTAssertEqual(filter.maxTimeEstimate, 30)
        XCTAssertEqual(filter.intent, .example)
    }

    func testIntentOverridesContentType() {
        let exampleDoc = AppleDocumentation(
            metadata: DocumentationMetadata(role: "sampleCode"),
            kind: "article"
        )

        let articleDoc = AppleDocumentation(
            metadata: DocumentationMetadata(role: "article"),
            kind: "article"
        )

        let client = AppleDocumentationClient()
        let exampleMetadata = client.extractMetadata(exampleDoc)
        let articleMetadata = client.extractMetadata(articleDoc)

        let filter = ContentTypeFilter(intent: .reference)

        let result = DocumentationSearchResult(
            title: "Test",
            url: "https://example.com",
            type: "symbol"
        )

        // With reference intent, symbols get boosted
        let exampleRelevance = client.calculateIntentRelevance(contentType: .sampleCode, intent: .reference)
        let articleRelevance = client.calculateIntentRelevance(contentType: .article, intent: .reference)
        let symbolRelevance = client.calculateIntentRelevance(contentType: .symbol, intent: .reference)

        XCTAssertGreaterThan(symbolRelevance, articleRelevance)
        XCTAssertGreaterThan(symbolRelevance, exampleRelevance)
    }

    // MARK: - Edge Cases Tests

    func testEmptyIntentDetection() {
        let client = AppleDocumentationClient()

        // Empty or whitespace queries should default to all
        XCTAssertEqual(client.detectIntent(from: ""), .all)
        XCTAssertEqual(client.detectIntent(from: "   "), .all)
        XCTAssertEqual(client.detectIntent(from: "abcxyz"), .all)
    }

    func testCaseInsensitiveIntentDetection() {
        let client = AppleDocumentationClient()

        // Should be case insensitive
        XCTAssertEqual(client.detectIntent(from: "EXAMPLE code"), .example)
        XCTAssertEqual(client.detectIntent(from: "EXPLAIN this"), .explain)
        XCTAssertEqual(client.detectIntent(from: "LEARN SwiftUI"), .learn)
        XCTAssertEqual(client.detectIntent(from: "REFERENCE docs"), .reference)
    }

    func testMixedIntentKeywords() {
        let client = AppleDocumentationClient()

        // Should prioritize earlier patterns in the detection logic
        XCTAssertEqual(client.detectIntent(from: "how to example code"), .example) // "how to" also matches example
        XCTAssertEqual(client.detectIntent(from: "learn example"), .example) // "learn" matches learn, but "example" is earlier
    }

    // MARK: - Integration Tests

    func testCompleteIntentWorkflow() {
        // Test the complete workflow from query to intent to relevance
        let query = "show me example code for animations"
        let client = AppleDocumentationClient()

        // 1. Detect intent
        let detectedIntent = client.detectIntent(from: query)
        XCTAssertEqual(detectedIntent, .example)

        // 2. Calculate relevance for different content types
        let sampleCodeRelevance = client.calculateIntentRelevance(contentType: .sampleCode, intent: detectedIntent)
        let articleRelevance = client.calculateIntentRelevance(contentType: .article, intent: detectedIntent)
        let symbolRelevance = client.calculateIntentRelevance(contentType: .symbol, intent: detectedIntent)

        // 3. Verify ranking preferences
        XCTAssertGreaterThan(sampleCodeRelevance, articleRelevance)
        XCTAssertGreaterThan(sampleCodeRelevance, symbolRelevance)

        // 4. Test filter creation
        let filter = ContentTypeFilter(intent: detectedIntent)
        XCTAssertEqual(filter.intent, .example)
    }
}