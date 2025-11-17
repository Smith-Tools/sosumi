import XCTest
@testable import SosumiCore

final class SosumiCoreTests: XCTestCase {

    func testSearchFunctionality() throws {
        // Test search query processing
        let query = "SwiftUI animations"
        let processed = SosumiSearchEngine.processQuery(query)
        XCTAssertFalse(processed.isEmpty)
        XCTAssertTrue(processed.contains("swiftui"))
        XCTAssertTrue(processed.contains("animations"))
    }

    func testRelevanceScoring() throws {
        // Test relevance scoring algorithm
        let score = SosumiSearchEngine.calculateRelevanceScore(
            query: "SwiftUI",
            content: "Advanced SwiftUI animations",
            metadata: [:]
        )
        XCTAssertGreaterThan(score, 0)
        XCTAssertLessThanOrEqual(score, 1.0)
    }

    func testPerformanceTargets() throws {
        // Test that search performance meets targets
        let startTime = CFAbsoluteTimeGetCurrent()

        // Simulate search operation
        _ = SosumiSearchEngine.processQuery("test query")

        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        XCTAssertLessThan(timeElapsed, 0.01) // Should be under 10ms
    }

    func testExcerptGeneration() throws {
        // Test excerpt generation from content
        let content = "This is a long transcript about SwiftUI animations and how they work in modern iOS applications."
        let excerpt = SosumiSearchEngine.generateExcerpt(
            from: content,
            for: "SwiftUI"
        )
        XCTAssertFalse(excerpt.isEmpty)
        XCTAssertTrue(excerpt.contains("SwiftUI"))
    }

    func testCacheOperations() throws {
        // Test cache functionality
        let cache = SosumiCache()

        // Test setting and getting
        let key = "test_key"
        let value = "test_value"

        cache.set(key: key, value: value)
        let retrieved = cache.get(key: key)

        XCTAssertEqual(retrieved, value)
    }
}