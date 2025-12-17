import Testing
@testable import SosumiDocs

@Suite("Intent-Based Search Tests")
struct IntentBasedSearchTests {

    // MARK: - Intent Detection Tests

    @Test("Detect intent from example queries")
    func detectIntentFromExampleQueries() {
        let client = AppleDocumentationClient()

        // Example intent patterns
        #expect(client.detectIntent(from: "show me example code") == .example)
        #expect(client.detectIntent(from: "how to implement animation") == .example)
        #expect(client.detectIntent(from: "Button sample code") == .example)
        #expect(client.detectIntent(from: "demo of URLSession") == .example)
        #expect(client.detectIntent(from: "implement this feature") == .example)
    }

    @Test("Detect intent from explain queries")
    func detectIntentFromExplainQueries() {
        let client = AppleDocumentationClient()

        // Explain intent patterns
        #expect(client.detectIntent(from: "explain SwiftUI animations") == .explain)
        #expect(client.detectIntent(from: "understand this API") == .explain)
        #expect(client.detectIntent(from: "overview of Combine") == .explain)
        #expect(client.detectIntent(from: "what is async/await") == .explain)
        #expect(client.detectIntent(from: "how does this work") == .explain)
    }

    @Test("Detect intent from reference queries")
    func detectIntentFromReferenceQueries() {
        let client = AppleDocumentationClient()

        // Reference intent patterns
        #expect(client.detectIntent(from: "API reference for Button") == .reference)
        #expect(client.detectIntent(from: "method signatures") == .reference)
        #expect(client.detectIntent(from: "class documentation") == .reference)
        #expect(client.detectIntent(from: "protocol requirements") == .reference)
    }

    @Test("Detect intent from learn queries")
    func detectIntentFromLearnQueries() {
        let client = AppleDocumentationClient()

        // Learn intent patterns
        #expect(client.detectIntent(from: "learn SwiftUI") == .learn)
        #expect(client.detectIntent(from: "tutorial for animations") == .learn)
        #expect(client.detectIntent(from: "step by step guide") == .learn)
        #expect(client.detectIntent(from: "getting started with Combine") == .learn)
        #expect(client.detectIntent(from: "beginner tutorial") == .learn)
    }

    @Test("Detect intent default")
    func detectIntentDefault() {
        let client = AppleDocumentationClient()

        // Default to all for general queries
        #expect(client.detectIntent(from: "SwiftUI") == .all)
        #expect(client.detectIntent(from: "animation") == .all)
        #expect(client.detectIntent(from: "Button") == .all)
    }

    // MARK: - Intent String Parsing Tests

    @Test("Search intent from string")
    func searchIntentFromString() {
        #expect(SearchIntent.from(string: "example") == .example)
        #expect(SearchIntent.from(string: "examples") == .example)
        #expect(SearchIntent.from(string: "code") == .example)
        #expect(SearchIntent.from(string: "demo") == .example)

        #expect(SearchIntent.from(string: "explain") == .explain)
        #expect(SearchIntent.from(string: "understand") == .explain)
        #expect(SearchIntent.from(string: "overview") == .explain)

        #expect(SearchIntent.from(string: "reference") == .reference)
        #expect(SearchIntent.from(string: "api") == .reference)
        #expect(SearchIntent.from(string: "technical") == .reference)

        #expect(SearchIntent.from(string: "learn") == .learn)
        #expect(SearchIntent.from(string: "tutorial") == .learn)
        #expect(SearchIntent.from(string: "guide") == .learn)

        #expect(SearchIntent.from(string: "all") == .all)
        #expect(SearchIntent.from(string: "everything") == .all)

        #expect(SearchIntent.from(string: "invalid") == nil)
        #expect(SearchIntent.from(string: "unknown") == nil)
    }

    // MARK: - Intent-to-Content-Type Mapping Tests

    @Test("Intent preferred content types")
    func intentPreferredContentTypes() {
        // Example intent prioritizes sample code and tutorials
        let exampleTypes = SearchIntent.example.preferredContentTypes
        #expect(exampleTypes.contains { $0.0 == .sampleCode && $0.1 == 1.0 })
        #expect(exampleTypes.contains { $0.0 == .tutorial && $0.1 == 0.7 })
        #expect(exampleTypes.contains { $0.0 == .article && $0.1 == 0.3 })

        // Explain intent prioritizes articles and symbols
        let explainTypes = SearchIntent.explain.preferredContentTypes
        #expect(explainTypes.contains { $0.0 == .article && $0.1 == 1.0 })
        #expect(explainTypes.contains { $0.0 == .symbol && $0.1 == 0.8 })
        #expect(explainTypes.contains { $0.0 == .tutorial && $0.1 == 0.4 })

        // Reference intent prioritizes symbols
        let referenceTypes = SearchIntent.reference.preferredContentTypes
        #expect(referenceTypes.contains { $0.0 == .symbol && $0.1 == 1.0 })
        #expect(referenceTypes.contains { $0.0 == .article && $0.1 == 0.3 })

        // Learn intent prioritizes tutorials
        let learnTypes = SearchIntent.learn.preferredContentTypes
        #expect(learnTypes.contains { $0.0 == .tutorial && $0.1 == 1.0 })
        #expect(learnTypes.contains { $0.0 == .sampleCode && $0.1 == 0.6 })
        #expect(learnTypes.contains { $0.0 == .article && $0.1 == 0.5 })

        // All intent gives equal weight to everything
        let allTypes = SearchIntent.all.preferredContentTypes
        #expect(allTypes.count == 4)
        #expect(allTypes.allSatisfy { $0.1 == 1.0 })
    }

    // MARK: - Intent-Based Relevance Tests

    @Test("Calculate intent relevance")
    func calculateIntentRelevance() {
        let client = AppleDocumentationClient()

        // Example intent should heavily boost sample code
        let exampleBoost = client.calculateIntentRelevance(contentType: .sampleCode, intent: .example)
        #expect(exampleBoost == 100) // 1.0 * 100

        let articleBoostForExample = client.calculateIntentRelevance(contentType: .article, intent: .example)
        #expect(articleBoostForExample == 30) // 0.3 * 100

        // Explain intent should heavily boost articles
        let explainBoost = client.calculateIntentRelevance(contentType: .article, intent: .explain)
        #expect(explainBoost == 100) // 1.0 * 100

        let symbolBoostForExplain = client.calculateIntentRelevance(contentType: .symbol, intent: .explain)
        #expect(symbolBoostForExplain == 80) // 0.8 * 100

        // No boost for non-matching combinations
        let noBoost = client.calculateIntentRelevance(contentType: .tutorial, intent: .reference)
        #expect(noBoost == 0)
    }

    // MARK: - Filter Integration Tests

    @Test("Content type filter with intent")
    func contentTypeFilterWithIntent() {
        var filter = ContentTypeFilter(intent: .example)

        #expect(filter.intent != nil)
        #expect(filter.intent == .example)

        // Should still support other options
        filter.contentType = .article
        filter.requiresPlatforms = ["iOS 15+"]
        filter.maxTimeEstimate = 30

        #expect(filter.contentType == .article)
        #expect(filter.requiresPlatforms == ["iOS 15+"])
        #expect(filter.maxTimeEstimate == 30)
        #expect(filter.intent == .example)
    }

    @Test("Intent overrides content type")
    func intentOverridesContentType() {
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

        #expect(symbolRelevance > articleRelevance)
        #expect(symbolRelevance > exampleRelevance)
    }

    // MARK: - Edge Cases Tests

    @Test("Empty intent detection")
    func emptyIntentDetection() {
        let client = AppleDocumentationClient()

        // Empty or whitespace queries should default to all
        #expect(client.detectIntent(from: "") == .all)
        #expect(client.detectIntent(from: "   ") == .all)
        #expect(client.detectIntent(from: "abcxyz") == .all)
    }

    @Test("Case insensitive intent detection")
    func caseInsensitiveIntentDetection() {
        let client = AppleDocumentationClient()

        // Should be case insensitive
        #expect(client.detectIntent(from: "EXAMPLE code") == .example)
        #expect(client.detectIntent(from: "EXPLAIN this") == .explain)
        #expect(client.detectIntent(from: "LEARN SwiftUI") == .learn)
        #expect(client.detectIntent(from: "REFERENCE docs") == .reference)
    }

    @Test("Mixed intent keywords")
    func mixedIntentKeywords() {
        let client = AppleDocumentationClient()

        // Should prioritize earlier patterns in the detection logic
        #expect(client.detectIntent(from: "how to example code") == .example) // "how to" also matches example
        #expect(client.detectIntent(from: "learn example") == .example) // "learn" matches learn, but "example" is earlier
    }

    // MARK: - Integration Tests

    @Test("Complete intent workflow")
    func completeIntentWorkflow() {
        // Test the complete workflow from query to intent to relevance
        let query = "show me example code for animations"
        let client = AppleDocumentationClient()

        // 1. Detect intent
        let detectedIntent = client.detectIntent(from: query)
        #expect(detectedIntent == .example)

        // 2. Calculate relevance for different content types
        let sampleCodeRelevance = client.calculateIntentRelevance(contentType: .sampleCode, intent: detectedIntent)
        let articleRelevance = client.calculateIntentRelevance(contentType: .article, intent: detectedIntent)
        let symbolRelevance = client.calculateIntentRelevance(contentType: .symbol, intent: detectedIntent)

        // 3. Verify ranking preferences
        #expect(sampleCodeRelevance > articleRelevance)
        #expect(sampleCodeRelevance > symbolRelevance)

        // 4. Test filter creation
        let filter = ContentTypeFilter(intent: detectedIntent)
        #expect(filter.intent == .example)
    }
}