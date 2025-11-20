import XCTest
@testable import SosumiDocs

final class ContentFilteringTests: XCTestCase {

    // MARK: - Content Type Filtering Tests

    func testFilterByContentType() {
        let filter = ContentTypeFilter(contentType: .sampleCode)

        let sampleCodeDoc = AppleDocumentation(
            metadata: DocumentationMetadata(role: "sampleCode"),
            kind: "article"
        )

        let articleDoc = AppleDocumentation(
            metadata: DocumentationMetadata(role: "article"),
            kind: "article"
        )

        let client = AppleDocumentationClient()
        let sampleCodeMetadata = client.extractMetadata(sampleCodeDoc)
        let articleMetadata = client.extractMetadata(articleDoc)

        let sampleCodeResult = DocumentationSearchResult(
            title: "Sample Code",
            url: "https://example.com/sample",
            type: "article"
        )

        let articleResult = DocumentationSearchResult(
            title: "Article",
            url: "https://example.com/article",
            type: "article"
        )

        // The filtering happens internally, but we can test the logic
        XCTAssertTrue(client.passesFilter(
            sampleCodeResult,
            metadata: sampleCodeMetadata,
            filter: filter
        ), "Sample code should pass sample code filter")

        XCTAssertFalse(client.passesFilter(
            articleResult,
            metadata: articleMetadata,
            filter: filter
        ), "Article should not pass sample code filter")
    }

    // MARK: - Platform Filtering Tests

    func testFilterByPlatform() {
        let filter = ContentTypeFilter(requiresPlatforms: ["iOS 15+"])

        let iOSDoc = AppleDocumentation(
            metadata: DocumentationMetadata(
                platforms: [DocumentationPlatform(name: "iOS", introducedAt: "15.0")]
            )
        )

        let macOSDoc = AppleDocumentation(
            metadata: DocumentationMetadata(
                platforms: [DocumentationPlatform(name: "macOS", introducedAt: "12.0")]
            )
        )

        let client = AppleDocumentationClient()
        let iOSMetadata = client.extractMetadata(iOSDoc)
        let macOSMetadata = client.extractMetadata(macOSDoc)

        let result = DocumentationSearchResult(
            title: "Test",
            url: "https://example.com",
            type: "symbol"
        )

        XCTAssertTrue(client.passesFilter(
            result,
            metadata: iOSMetadata,
            filter: filter
        ), "iOS 15+ should pass iOS 15+ filter")

        XCTAssertFalse(client.passesFilter(
            result,
            metadata: macOSMetadata,
            filter: filter
        ), "macOS should not pass iOS 15+ filter")
    }

    func testFilterByMultiplePlatforms() {
        let filter = ContentTypeFilter(requiresPlatforms: ["iOS", "macOS"])

        let multiPlatformDoc = AppleDocumentation(
            metadata: DocumentationMetadata(
                platforms: [
                    DocumentationPlatform(name: "iOS", introducedAt: "14.0"),
                    DocumentationPlatform(name: "macOS", introducedAt: "11.0")
                ]
            )
        )

        let iOSOnlyDoc = AppleDocumentation(
            metadata: DocumentationMetadata(
                platforms: [DocumentationPlatform(name: "iOS", introducedAt: "14.0")]
            )
        )

        let client = AppleDocumentationClient()
        let multiPlatformMetadata = client.extractMetadata(multiPlatformDoc)
        let iOSOnlyMetadata = client.extractMetadata(iOSOnlyDoc)

        let result = DocumentationSearchResult(
            title: "Test",
            url: "https://example.com",
            type: "symbol"
        )

        XCTAssertTrue(client.passesFilter(
            result,
            metadata: multiPlatformMetadata,
            filter: filter
        ), "Multi-platform should pass iOS/macOS filter")

        // Note: The current implementation requires at least one platform match
        XCTAssertTrue(client.passesFilter(
            result,
            metadata: iOSOnlyMetadata,
            filter: filter
        ), "iOS-only should pass iOS/macOS filter")
    }

    // MARK: - Time Estimate Filtering Tests

    func testFilterByTimeEstimate() {
        let filter = ContentTypeFilter(maxTimeEstimate: 30)

        let quickDoc = AppleDocumentation(
            metadata: DocumentationMetadata(
                customMetadata: CustomMetadataValue(estimatedTime: "15 minutes")
            )
        )

        let longDoc = AppleDocumentation(
            metadata: DocumentationMetadata(
                customMetadata: CustomMetadataValue(estimatedTime: "45 minutes")
            )
        )

        let client = AppleDocumentationClient()
        let quickMetadata = client.extractMetadata(quickDoc)
        let longMetadata = client.extractMetadata(longDoc)

        let result = DocumentationSearchResult(
            title: "Test",
            url: "https://example.com",
            type: "tutorial"
        )

        XCTAssertTrue(client.passesFilter(
            result,
            metadata: quickMetadata,
            filter: filter
        ), "15 minutes should pass 30 minute max filter")

        XCTAssertFalse(client.passesFilter(
            result,
            metadata: longMetadata,
            filter: filter
        ), "45 minutes should not pass 30 minute max filter")
    }

    func testFilterByComplexTimeEstimate() {
        let filter = ContentTypeFilter(maxTimeEstimate: 90)

        let doc = AppleDocumentation(
            metadata: DocumentationMetadata(
                customMetadata: CustomMetadataValue(estimatedTime: "1 hour 30 minutes")
            )
        )

        let client = AppleDocumentationClient()
        let metadata = client.extractMetadata(doc)

        let result = DocumentationSearchResult(
            title: "Test",
            url: "https://example.com",
            type: "tutorial"
        )

        XCTAssertTrue(client.passesFilter(
            result,
            metadata: metadata,
            filter: filter
        ), "1 hour 30 minutes should pass 90 minute max filter")
    }

    // MARK: - Relevance Scoring Tests

    func testRelevanceScoring() {
        let client = AppleDocumentationClient()

        let exactMatch = DocumentationSearchResult(
            title: "Button",
            url: "https://example.com/documentation/swiftui/button",
            type: "symbol",
            description: "A control that performs an action"
        )

        let partialMatch = DocumentationSearchResult(
            title: "CustomButton",
            url: "https://example.com",
            type: "symbol",
            description: "A custom button implementation"
        )

        let noMatch = DocumentationSearchResult(
            title: "TextField",
            url: "https://example.com",
            type: "symbol",
            description: "A text input control"
        )

        let exactScore = client.calculateBaseRelevance(exactMatch, query: "Button")
        let partialScore = client.calculateBaseRelevance(partialMatch, query: "Button")
        let noMatchScore = client.calculateBaseRelevance(noMatch, query: "Button")

        XCTAssertGreaterThan(exactScore, partialScore, "Exact match should score higher than partial")
        XCTAssertGreaterThan(partialScore, noMatchScore, "Partial match should score higher than no match")
        XCTAssertGreaterThan(noMatchScore, 0, "No match should still have some base score")
    }

    func testContentTypeBoost() {
        let client = AppleDocumentationClient()

        // Sample code boost for "example" query
        let sampleCodeBoost = client.calculateContentTypeBoost(contentType: .sampleCode, query: "example")
        let articleBoost = client.calculateContentTypeBoost(contentType: .article, query: "example")

        XCTAssertGreaterThan(sampleCodeBoost, articleBoost, "Sample code should get boost for 'example' query")

        // Tutorial boost for "tutorial" query
        let tutorialBoost = client.calculateContentTypeBoost(contentType: .tutorial, query: "tutorial")
        let symbolBoost = client.calculateContentTypeBoost(contentType: .symbol, query: "tutorial")

        XCTAssertGreaterThan(tutorialBoost, symbolBoost, "Tutorial should get boost for 'tutorial' query")
    }

    // MARK: - Time Parsing Tests

    func testParseTimeEstimate() {
        let client = AppleDocumentationClient()

        // Test minutes
        XCTAssertEqual(client.parseTimeEstimate("15 minutes"), 15)
        XCTAssertEqual(client.parseTimeEstimate("30 minute"), 30)

        // Test hours
        XCTAssertEqual(client.parseTimeEstimate("1 hour"), 60)
        XCTAssertEqual(client.parseTimeEstimate("2 hours"), 120)

        // Test combined
        XCTAssertEqual(client.parseTimeEstimate("1 hour 30 minutes"), 90)
        XCTAssertEqual(client.parseTimeEstimate("2 hours 15 minutes"), 135)

        // Test fallback
        XCTAssertEqual(client.parseTimeEstimate("unknown format"), 30)
    }

    // MARK: - URL Path Extraction Tests

    func testExtractDocumentationPath() {
        let client = AppleDocumentationClient()

        let url1 = "https://developer.apple.com/documentation/swiftui/button"
        let path1 = client.extractDocumentationPath(from: url1)
        XCTAssertEqual(path1, "swiftui/button")

        let url2 = "https://developer.apple.com/documentation/uikit/uiviewcontroller"
        let path2 = client.extractDocumentationPath(from: url2)
        XCTAssertEqual(path2, "uikit/uiviewcontroller")

        // Test fallback
        let url3 = "https://example.com/some/path"
        let path3 = client.extractDocumentationPath(from: url3)
        XCTAssertEqual(path3, "https://example.com/some/path")
    }

    // MARK: - Combined Filter Tests

    func testCombinedFiltering() {
        let filter = ContentTypeFilter(
            contentType: .tutorial,
            requiresPlatforms: ["iOS"],
            maxTimeEstimate: 45
        )

        let matchingDoc = AppleDocumentation(
            metadata: DocumentationMetadata(
                role: "tutorial",
                platforms: [DocumentationPlatform(name: "iOS", introducedAt: "14.0")],
                customMetadata: CustomMetadataValue(estimatedTime: "30 minutes")
            )
        )

        let nonMatchingDoc = AppleDocumentation(
            metadata: DocumentationMetadata(
                role: "article",
                platforms: [DocumentationPlatform(name: "macOS", introducedAt: "11.0")],
                customMetadata: CustomMetadataValue(estimatedTime: "60 minutes")
            )
        )

        let client = AppleDocumentationClient()
        let matchingMetadata = client.extractMetadata(matchingDoc)
        let nonMatchingMetadata = client.extractMetadata(nonMatchingDoc)

        let result = DocumentationSearchResult(
            title: "Test",
            url: "https://example.com",
            type: "tutorial"
        )

        XCTAssertTrue(client.passesFilter(
            result,
            metadata: matchingMetadata,
            filter: filter
        ), "Matching doc should pass all filters")

        XCTAssertFalse(client.passesFilter(
            result,
            metadata: nonMatchingMetadata,
            filter: filter
        ), "Non-matching doc should fail filters")
    }

    // MARK: - Edge Cases Tests

    func testFilterWithNilMetadata() {
        let filter = ContentTypeFilter(contentType: .sampleCode)

        let result = DocumentationSearchResult(
            title: "Test",
            url: "https://example.com",
            type: "symbol"
        )

        let client = AppleDocumentationClient()

        // Should handle nil metadata gracefully
        XCTAssertTrue(client.passesFilter(
            result,
            metadata: nil,
            filter: filter
        ), "Should pass filter with nil metadata when filter requires metadata")
    }

    func testEmptyFilter() {
        let emptyFilter = ContentTypeFilter()

        let doc = AppleDocumentation()
        let client = AppleDocumentationClient()
        let metadata = client.extractMetadata(doc)

        let result = DocumentationSearchResult(
            title: "Test",
            url: "https://example.com",
            type: "symbol"
        )

        // Empty filter should pass everything
        XCTAssertTrue(client.passesFilter(
            result,
            metadata: metadata,
            filter: emptyFilter
        ), "Empty filter should pass all results")
    }
}