import XCTest
@testable import SosumiDocs

final class RenderNodeParsingTests: XCTestCase {

    // MARK: - Content Type Classification Tests

    func testClassifySampleCode() {
        let documentation = AppleDocumentation(
            metadata: DocumentationMetadata(role: "sampleCode"),
            kind: "article"
        )

        let client = AppleDocumentationClient()
        let contentType = client.classifyContentType(documentation)

        XCTAssertEqual(contentType, .sampleCode, "Should classify as sample code when kind=article and role=sampleCode")
    }

    func testClassifyArticle() {
        let documentation = AppleDocumentation(
            metadata: DocumentationMetadata(role: "article"),
            kind: "article"
        )

        let client = AppleDocumentationClient()
        let contentType = client.classifyContentType(documentation)

        XCTAssertEqual(contentType, .article, "Should classify as article when kind=article and role != sampleCode")
    }

    func testClassifySymbol() {
        let documentation = AppleDocumentation(
            metadata: DocumentationMetadata(),
            kind: "symbol"
        )

        let client = AppleDocumentationClient()
        let contentType = client.classifyContentType(documentation)

        XCTAssertEqual(contentType, .symbol, "Should classify as symbol when kind=symbol")
    }

    func testClassifyTutorial() {
        let documentation = AppleDocumentation(
            metadata: DocumentationMetadata(),
            kind: "tutorial"
        )

        let client = AppleDocumentationClient()
        let contentType = client.classifyContentType(documentation)

        XCTAssertEqual(contentType, .tutorial, "Should classify as tutorial when kind=tutorial")
    }

    func testClassifyGeneric() {
        let documentation = AppleDocumentation(
            metadata: DocumentationMetadata(),
            kind: "unknown"
        )

        let client = AppleDocumentationClient()
        let contentType = client.classifyContentType(documentation)

        XCTAssertEqual(contentType, .generic, "Should classify as generic for unknown kinds")
    }

    // MARK: - Custom Metadata Extraction Tests

    func testExtractCustomMetadata() {
        let customMetadata = CustomMetadataValue(
            requirements: ["iOS 14+", "Xcode 12+"],
            estimatedTime: "15 minutes",
            skillLevel: "Beginner",
            prerequisites: ["Swift basics"],
            tags: ["SwiftUI", "iOS"]
        )

        let metadata = DocumentationMetadata(customMetadata: customMetadata)
        let client = AppleDocumentationClient()
        let result = client.extractCustomMetadata(metadata)

        XCTAssertEqual(result["requirements"] as? [String], ["iOS 14+", "Xcode 12+"])
        XCTAssertEqual(result["estimatedTime"] as? String, "15 minutes")
        XCTAssertEqual(result["skillLevel"] as? String, "Beginner")
        XCTAssertEqual(result["prerequisites"] as? [String], ["Swift basics"])
        XCTAssertEqual(result["tags"] as? [String], ["SwiftUI", "iOS"])
    }

    func testExtractCustomMetadataNil() {
        let client = AppleDocumentationClient()
        let result = client.extractCustomMetadata(nil)

        XCTAssertTrue(result.isEmpty, "Should return empty dictionary for nil metadata")
    }

    // MARK: - Relationship Extraction Tests

    func testExtractRelationships() {
        let relationshipsSection = RelationshipsSection(
            type: "conformances",
            identifiers: ["Identifiable", "ObservableObject"]
        )

        let client = AppleDocumentationClient()
        let result = client.extractRelationships([relationshipsSection])

        XCTAssertEqual(result["conformances"], ["Identifiable", "ObservableObject"])
        XCTAssertEqual(result.count, 1, "Should extract one relationship type")
    }

    func testExtractRelationshipsEmpty() {
        let client = AppleDocumentationClient()
        let result = client.extractRelationships([])

        XCTAssertTrue(result.isEmpty, "Should return empty dictionary for empty sections")
    }

    func testExtractRelationshipsNil() {
        let client = AppleDocumentationClient()
        let result = client.extractRelationships(nil)

        XCTAssertTrue(result.isEmpty, "Should return empty dictionary for nil sections")
    }

    // MARK: - Topic Extraction Tests

    func testExtractTopics() {
        let topicSection = TopicSection(
            title: "Related Topics",
            identifiers: ["doc://SwiftUI/View", "doc://SwiftUI/ViewModifier"]
        )

        let client = AppleDocumentationClient()
        let result = client.extractTopics([topicSection])

        XCTAssertEqual(result.count, 2, "Should extract two topics")
        XCTAssertTrue(result.contains("doc://SwiftUI/View"))
        XCTAssertTrue(result.contains("doc://SwiftUI/ViewModifier"))
    }

    func testExtractTopicsEmpty() {
        let client = AppleDocumentationClient()
        let result = client.extractTopics([])

        XCTAssertTrue(result.isEmpty, "Should return empty array for empty sections")
    }

    func testExtractTopicsNil() {
        let client = AppleDocumentationClient()
        let result = client.extractTopics(nil)

        XCTAssertTrue(result.isEmpty, "Should return empty array for nil sections")
    }

    // MARK: - Hierarchy Extraction Tests

    func testExtractHierarchy() {
        let hierarchy = Hierarchy(paths: [
            ["SwiftUI", "Views", "Controls", "Button"],
            ["SwiftUI", "Buttons", "Button"]
        ])

        let client = AppleDocumentationClient()
        let result = client.extractHierarchy(hierarchy)

        XCTAssertEqual(result, ["SwiftUI", "Views", "Controls", "Button"], "Should return first breadcrumb path")
    }

    func testExtractHierarchyEmpty() {
        let hierarchy = Hierarchy(paths: [])
        let client = AppleDocumentationClient()
        let result = client.extractHierarchy(hierarchy)

        XCTAssertTrue(result.isEmpty, "Should return empty array for empty paths")
    }

    func testExtractHierarchyNil() {
        let client = AppleDocumentationClient()
        let result = client.extractHierarchy(nil)

        XCTAssertTrue(result.isEmpty, "Should return empty array for nil hierarchy")
    }

    // MARK: - Platform Extraction Tests

    func testExtractPlatforms() {
        let platforms = [
            DocumentationPlatform(name: "iOS", introducedAt: "14.0"),
            DocumentationPlatform(name: "macOS", introducedAt: "11.0"),
            DocumentationPlatform(name: "watchOS", introducedAt: "7.0")
        ]

        let metadata = DocumentationMetadata(platforms: platforms)
        let client = AppleDocumentationClient()
        let result = client.extractPlatforms(metadata)

        XCTAssertEqual(result.count, 3)
        XCTAssertTrue(result.contains("iOS (14.0+)"))
        XCTAssertTrue(result.contains("macOS (11.0+)"))
        XCTAssertTrue(result.contains("watchOS (7.0+)"))
    }

    func testExtractPlatformsWithoutVersions() {
        let platforms = [
            DocumentationPlatform(name: "iOS"),
            DocumentationPlatform(name: "macOS")
        ]

        let metadata = DocumentationMetadata(platforms: platforms)
        let client = AppleDocumentationClient()
        let result = client.extractPlatforms(metadata)

        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.contains("iOS"))
        XCTAssertTrue(result.contains("macOS"))
    }

    func testExtractPlatformsNil() {
        let client = AppleDocumentationClient()
        let result = client.extractPlatforms(nil)

        XCTAssertTrue(result.isEmpty, "Should return empty array for nil metadata")
    }

    // MARK: - Full Metadata Extraction Tests

    func testExtractMetadataComplete() {
        let customMetadata = CustomMetadataValue(
            requirements: ["iOS 14+"],
            estimatedTime: "30 minutes"
        )

        let metadata = DocumentationMetadata(
            role: "sampleCode",
            roleHeading: "Sample Code",
            customMetadata: customMetadata,
            platforms: [DocumentationPlatform(name: "iOS", introducedAt: "14.0")]
        )

        let relationshipsSection = RelationshipsSection(
            type: "conformances",
            identifiers: ["View"]
        )

        let topicSection = TopicSection(
            title: "Related",
            identifiers: ["doc://SwiftUI/View"]
        )

        let hierarchy = Hierarchy(paths: [["SwiftUI", "Views", "Button"]])

        let documentation = AppleDocumentation(
            metadata: metadata,
            kind: "article",
            relationshipsSections: [relationshipsSection],
            topicSections: [topicSection],
            hierarchy: hierarchy
        )

        let client = AppleDocumentationClient()
        let result = client.extractMetadata(documentation)

        XCTAssertEqual(result.contentType, .sampleCode)
        XCTAssertEqual(result.roleHeading, "Sample Code")
        XCTAssertEqual(result.requirements, ["iOS 14+"])
        XCTAssertEqual(result.timeEstimate, "30 minutes")
        XCTAssertEqual(result.platforms, ["iOS (14.0+)"])
        XCTAssertEqual(result.relationships["conformances"], ["View"])
        XCTAssertEqual(result.relatedTopics, ["doc://SwiftUI/View"])
        XCTAssertEqual(result.breadcrumbs, ["SwiftUI", "Views", "Button"])
    }

    func testExtractMetadataMinimal() {
        let documentation = AppleDocumentation(
            kind: "symbol"
        )

        let client = AppleDocumentationClient()
        let result = client.extractMetadata(documentation)

        XCTAssertEqual(result.contentType, .symbol)
        XCTAssertNil(result.roleHeading)
        XCTAssertTrue(result.requirements.isEmpty)
        XCTAssertNil(result.timeEstimate)
        XCTAssertTrue(result.platforms.isEmpty)
        XCTAssertTrue(result.relationships.isEmpty)
        XCTAssertTrue(result.relatedTopics.isEmpty)
        XCTAssertTrue(result.breadcrumbs.isEmpty)
    }
}