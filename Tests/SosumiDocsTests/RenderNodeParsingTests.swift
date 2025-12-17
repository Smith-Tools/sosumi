import Testing
@testable import SosumiDocs

@Suite("RenderNode Parsing Tests")
struct RenderNodeParsingTests {

    // MARK: - Content Type Classification Tests

    @Test("Classify sample code")
    func classifySampleCode() {
        let documentation = AppleDocumentation(
            metadata: DocumentationMetadata(role: "sampleCode"),
            kind: "article"
        )

        let client = AppleDocumentationClient()
        let contentType = client.classifyContentType(documentation)

        #expect(contentType == .sampleCode, "Should classify as sample code when kind=article and role=sampleCode")
    }

    @Test("Classify article")
    func classifyArticle() {
        let documentation = AppleDocumentation(
            metadata: DocumentationMetadata(role: "article"),
            kind: "article"
        )

        let client = AppleDocumentationClient()
        let contentType = client.classifyContentType(documentation)

        #expect(contentType == .article, "Should classify as article when kind=article and role != sampleCode")
    }

    @Test("Classify symbol")
    func classifySymbol() {
        let documentation = AppleDocumentation(
            metadata: DocumentationMetadata(),
            kind: "symbol"
        )

        let client = AppleDocumentationClient()
        let contentType = client.classifyContentType(documentation)

        #expect(contentType == .symbol, "Should classify as symbol when kind=symbol")
    }

    @Test("Classify tutorial")
    func classifyTutorial() {
        let documentation = AppleDocumentation(
            metadata: DocumentationMetadata(),
            kind: "tutorial"
        )

        let client = AppleDocumentationClient()
        let contentType = client.classifyContentType(documentation)

        #expect(contentType == .tutorial, "Should classify as tutorial when kind=tutorial")
    }

    @Test("Classify generic")
    func classifyGeneric() {
        let documentation = AppleDocumentation(
            metadata: DocumentationMetadata(),
            kind: "unknown"
        )

        let client = AppleDocumentationClient()
        let contentType = client.classifyContentType(documentation)

        #expect(contentType == .generic, "Should classify as generic for unknown kinds")
    }

    // MARK: - Custom Metadata Extraction Tests

    @Test("Extract custom metadata")
    func extractCustomMetadata() {
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

        #expect(result["requirements"] as? [String] == ["iOS 14+", "Xcode 12+"])
        #expect(result["estimatedTime"] as? String == "15 minutes")
        #expect(result["skillLevel"] as? String == "Beginner")
        #expect(result["prerequisites"] as? [String] == ["Swift basics"])
        #expect(result["tags"] as? [String] == ["SwiftUI", "iOS"])
    }

    @Test("Extract custom metadata nil")
    func extractCustomMetadataNil() {
        let client = AppleDocumentationClient()
        let result = client.extractCustomMetadata(nil)

        #expect(result.isEmpty, "Should return empty dictionary for nil metadata")
    }

    // MARK: - Relationship Extraction Tests

    @Test("Extract relationships")
    func extractRelationships() {
        let relationshipsSection = RelationshipsSection(
            type: "conformances",
            identifiers: ["Identifiable", "ObservableObject"]
        )

        let client = AppleDocumentationClient()
        let result = client.extractRelationships([relationshipsSection])

        #expect(result["conformances"] == ["Identifiable", "ObservableObject"])
        #expect(result.count == 1, "Should extract one relationship type")
    }

    @Test("Extract relationships empty")
    func extractRelationshipsEmpty() {
        let client = AppleDocumentationClient()
        let result = client.extractRelationships([])

        #expect(result.isEmpty, "Should return empty dictionary for empty sections")
    }

    @Test("Extract relationships nil")
    func extractRelationshipsNil() {
        let client = AppleDocumentationClient()
        let result = client.extractRelationships(nil)

        #expect(result.isEmpty, "Should return empty dictionary for nil sections")
    }

    // MARK: - Topic Extraction Tests

    @Test("Extract topics")
    func extractTopics() {
        let topicSection = TopicSection(
            title: "Related Topics",
            identifiers: ["doc://SwiftUI/View", "doc://SwiftUI/ViewModifier"]
        )

        let client = AppleDocumentationClient()
        let result = client.extractTopics([topicSection])

        #expect(result.count == 2, "Should extract two topics")
        #expect(result.contains("doc://SwiftUI/View"))
        #expect(result.contains("doc://SwiftUI/ViewModifier"))
    }

    @Test("Extract topics empty")
    func extractTopicsEmpty() {
        let client = AppleDocumentationClient()
        let result = client.extractTopics([])

        #expect(result.isEmpty, "Should return empty array for empty sections")
    }

    @Test("Extract topics nil")
    func extractTopicsNil() {
        let client = AppleDocumentationClient()
        let result = client.extractTopics(nil)

        #expect(result.isEmpty, "Should return empty array for nil sections")
    }

    // MARK: - Hierarchy Extraction Tests

    @Test("Extract hierarchy")
    func extractHierarchy() {
        let hierarchy = Hierarchy(paths: [
            ["SwiftUI", "Views", "Controls", "Button"],
            ["SwiftUI", "Buttons", "Button"]
        ])

        let client = AppleDocumentationClient()
        let result = client.extractHierarchy(hierarchy)

        #expect(result == ["SwiftUI", "Views", "Controls", "Button"], "Should return first breadcrumb path")
    }

    @Test("Extract hierarchy empty")
    func extractHierarchyEmpty() {
        let hierarchy = Hierarchy(paths: [])
        let client = AppleDocumentationClient()
        let result = client.extractHierarchy(hierarchy)

        #expect(result.isEmpty, "Should return empty array for empty paths")
    }

    @Test("Extract hierarchy nil")
    func extractHierarchyNil() {
        let client = AppleDocumentationClient()
        let result = client.extractHierarchy(nil)

        #expect(result.isEmpty, "Should return empty array for nil hierarchy")
    }

    // MARK: - Platform Extraction Tests

    @Test("Extract platforms")
    func extractPlatforms() {
        let platforms = [
            DocumentationPlatform(name: "iOS", introducedAt: "14.0"),
            DocumentationPlatform(name: "macOS", introducedAt: "11.0"),
            DocumentationPlatform(name: "watchOS", introducedAt: "7.0")
        ]

        let metadata = DocumentationMetadata(platforms: platforms)
        let client = AppleDocumentationClient()
        let result = client.extractPlatforms(metadata)

        #expect(result.count == 3)
        #expect(result.contains("iOS (14.0+)"))
        #expect(result.contains("macOS (11.0+)"))
        #expect(result.contains("watchOS (7.0+)"))
    }

    @Test("Extract platforms without versions")
    func extractPlatformsWithoutVersions() {
        let platforms = [
            DocumentationPlatform(name: "iOS"),
            DocumentationPlatform(name: "macOS")
        ]

        let metadata = DocumentationMetadata(platforms: platforms)
        let client = AppleDocumentationClient()
        let result = client.extractPlatforms(metadata)

        #expect(result.count == 2)
        #expect(result.contains("iOS"))
        #expect(result.contains("macOS"))
    }

    @Test("Extract platforms nil")
    func extractPlatformsNil() {
        let client = AppleDocumentationClient()
        let result = client.extractPlatforms(nil)

        #expect(result.isEmpty, "Should return empty array for nil metadata")
    }

    // MARK: - Full Metadata Extraction Tests

    @Test("Extract metadata complete")
    func extractMetadataComplete() {
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

        #expect(result.contentType == .sampleCode)
        #expect(result.roleHeading == "Sample Code")
        #expect(result.requirements == ["iOS 14+"])
        #expect(result.timeEstimate == "30 minutes")
        #expect(result.platforms == ["iOS (14.0+)"])
        #expect(result.relationships["conformances"] == ["View"])
        #expect(result.relatedTopics == ["doc://SwiftUI/View"])
        #expect(result.breadcrumbs == ["SwiftUI", "Views", "Button"])
    }

    @Test("Extract metadata minimal")
    func extractMetadataMinimal() {
        let documentation = AppleDocumentation(
            kind: "symbol"
        )

        let client = AppleDocumentationClient()
        let result = client.extractMetadata(documentation)

        #expect(result.contentType == .symbol)
        #expect(result.roleHeading == nil)
        #expect(result.requirements.isEmpty)
        #expect(result.timeEstimate == nil)
        #expect(result.platforms.isEmpty)
        #expect(result.relationships.isEmpty)
        #expect(result.relatedTopics.isEmpty)
        #expect(result.breadcrumbs.isEmpty)
    }
}