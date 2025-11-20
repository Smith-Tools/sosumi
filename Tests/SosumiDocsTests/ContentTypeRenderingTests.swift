import XCTest
@testable import SosumiDocs

final class ContentTypeRenderingTests: XCTestCase {

    // MARK: - Sample Code Rendering Tests

    func testRenderSampleCodeMarkdown() {
        let customMetadata = CustomMetadataValue(
            requirements: ["iOS 14+", "Xcode 12+"],
            estimatedTime: "15 minutes"
        )

        let metadata = DocumentationMetadata(
            role: "sampleCode",
            roleHeading: "SwiftUI Button Sample",
            customMetadata: customMetadata,
            platforms: [DocumentationPlatform(name: "iOS", introducedAt: "14.0")]
        )

        let documentation = AppleDocumentation(
            metadata: metadata,
            kind: "article",
            abstract: [TextFragment(text: "A sample code showing how to create a custom button.", type: "text")],
            primaryContentSections: [
                PrimaryContentSection(
                    kind: "content",
                    title: "Implementation",
                    content: [TextFragment(text: "Here's the code implementation:", type: "text")]
                )
            ]
        )

        let renderer = AppleDocumentationRenderer()
        let extractedMetadata = AppleDocumentationClient().extractMetadata(documentation)
        let result = renderer.renderByContentType(documentation, metadata: extractedMetadata)

        XCTAssertTrue(result.contains("# 💻"))
        XCTAssertTrue(result.contains("Requirements"))
        XCTAssertTrue(result.contains("iOS 14+"))
        XCTAssertTrue(result.contains("Xcode 12+"))
        XCTAssertTrue(result.contains("Estimated Time: 15 minutes"))
        XCTAssertTrue(result.contains("Platforms"))
        XCTAssertTrue(result.contains("iOS (14.0+)"))
        XCTAssertTrue(result.contains("Implementation"))
        XCTAssertTrue(result.contains("Here's the code implementation"))
    }

    // MARK: - Article Rendering Tests

    func testRenderArticleMarkdown() {
        let metadata = DocumentationMetadata(
            role: "article",
            roleHeading: "Understanding SwiftUI Layout",
            platforms: [DocumentationPlatform(name: "iOS", introducedAt: "13.0")]
        )

        let hierarchy = Hierarchy(paths: [["SwiftUI", "Layout", "Stacks"]])

        let documentation = AppleDocumentation(
            metadata: metadata,
            kind: "article",
            hierarchy: hierarchy,
            abstract: [TextFragment(text: "Learn about SwiftUI's layout system.", type: "text")],
            primaryContentSections: [
                PrimaryContentSection(
                    kind: "content",
                    title: "Introduction",
                    content: [TextFragment(text: "SwiftUI provides powerful layout tools.", type: "text")]
                )
            ]
        )

        let renderer = AppleDocumentationRenderer()
        let extractedMetadata = AppleDocumentationClient().extractMetadata(documentation)
        let result = renderer.renderByContentType(documentation, metadata: extractedMetadata)

        XCTAssertTrue(result.contains("# 📝"))
        XCTAssertTrue(result.contains("📍 SwiftUI > Layout > Stacks"))
        XCTAssertTrue(result.contains("Learn about SwiftUI's layout system"))
        XCTAssertTrue(result.contains("Introduction"))
        XCTAssertTrue(result.contains("SwiftUI provides powerful layout tools"))
    }

    func testRenderArticleWithPrerequisites() {
        let customMetadata = CustomMetadataValue(
            prerequisites: ["Basic Swift knowledge", "UI development experience"],
            estimatedTime: "20 minutes"
        )

        let metadata = DocumentationMetadata(
            role: "article",
            roleHeading: "Advanced SwiftUI Animations",
            customMetadata: customMetadata
        )

        let documentation = AppleDocumentation(
            metadata: metadata,
            kind: "article"
        )

        let renderer = AppleDocumentationRenderer()
        let extractedMetadata = AppleDocumentationClient().extractMetadata(documentation)
        let result = renderer.renderByContentType(documentation, metadata: extractedMetadata)

        XCTAssertTrue(result.contains("# 📝"))
        XCTAssertTrue(result.contains("Prerequisites"))
        XCTAssertTrue(result.contains("Basic Swift knowledge"))
        XCTAssertTrue(result.contains("UI development experience"))
        XCTAssertTrue(result.contains("Learning Time: 20 minutes"))
    }

    // MARK: - Symbol Rendering Tests

    func testRenderSymbolMarkdown() {
        let relationshipsSection = RelationshipsSection(
            type: "conformances",
            identifiers: ["View", "Identifiable"]
        )

        let metadata = DocumentationMetadata(
            role: "symbol",
            platforms: [
                DocumentationPlatform(name: "iOS", introducedAt: "13.0"),
                DocumentationPlatform(name: "macOS", introducedAt: "10.15")
            ]
        )

        let documentation = AppleDocumentation(
            metadata: metadata,
            kind: "symbol",
            abstract: [TextFragment(text: "A custom view that displays content.", type: "text")],
            relationshipsSections: [relationshipsSection]
        )

        let renderer = AppleDocumentationRenderer()
        let extractedMetadata = AppleDocumentationClient().extractMetadata(documentation)
        let result = renderer.renderByContentType(documentation, metadata: extractedMetadata)

        XCTAssertTrue(result.contains("# ⚙️"))
        XCTAssertTrue(result.contains("Availability"))
        XCTAssertTrue(result.contains("iOS (13.0+)"))
        XCTAssertTrue(result.contains("macOS (10.15+)"))
        XCTAssertTrue(result.contains("Details"))
        XCTAssertTrue(result.contains("Conformances"))
        XCTAssertTrue(result.contains("View"))
        XCTAssertTrue(result.contains("Identifiable"))
        XCTAssertTrue(result.contains("A custom view that displays content"))
    }

    // MARK: - Tutorial Rendering Tests

    func testRenderTutorialMarkdown() {
        let customMetadata = CustomMetadataValue(
            estimatedTime: "45 minutes",
            skillLevel: "Intermediate"
        )

        let metadata = DocumentationMetadata(
            role: "tutorial",
            roleHeading: "Build Your First SwiftUI App",
            customMetadata: customMetadata
        )

        let documentation = AppleDocumentation(
            metadata: metadata,
            kind: "tutorial",
            abstract: [TextFragment(text: "Step-by-step guide to building a SwiftUI app.", type: "text")],
            primaryContentSections: [
                PrimaryContentSection(
                    kind: "content",
                    title: "Getting Started",
                    content: [TextFragment(text: "Let's start by creating a new project.", type: "text")]
                )
            ]
        )

        let renderer = AppleDocumentationRenderer()
        let extractedMetadata = AppleDocumentationClient().extractMetadata(documentation)
        let result = renderer.renderByContentType(documentation, metadata: extractedMetadata)

        XCTAssertTrue(result.contains("# 🎓"))
        XCTAssertTrue(result.contains("⏱️ Duration: 45 minutes"))
        XCTAssertTrue(result.contains("📊 Difficulty: Intermediate"))
        XCTAssertTrue(result.contains("Step-by-step guide to building a SwiftUI app"))
        XCTAssertTrue(result.contains("Getting Started"))
        XCTAssertTrue(result.contains("Let's start by creating a new project"))
    }

    // MARK: - Generic Rendering Tests

    func testRenderGenericMarkdown() {
        let metadata = DocumentationMetadata(
            platforms: [DocumentationPlatform(name: "iOS", introducedAt: "14.0")]
        )

        let documentation = AppleDocumentation(
            metadata: metadata,
            kind: "unknown",
            abstract: [TextFragment(text: "Generic content description.", type: "text")]
        )

        let renderer = AppleDocumentationRenderer()
        let extractedMetadata = AppleDocumentationClient().extractMetadata(documentation)
        let result = renderer.renderByContentType(documentation, metadata: extractedMetadata)

        XCTAssertTrue(result.contains("# "))  // Has title header
        XCTAssertTrue(result.contains("Generic content description"))
        XCTAssertTrue(result.contains("Platforms"))
        XCTAssertTrue(result.contains("iOS (14.0+)"))
    }

    // MARK: - Rendering Method Selection Tests

    func testRenderByContentTypeDispatcher() {
        // Test that the dispatcher correctly routes to the right renderer

        // Sample code
        let sampleCodeDoc = AppleDocumentation(
            metadata: DocumentationMetadata(role: "sampleCode"),
            kind: "article"
        )
        var renderer = AppleDocumentationRenderer()
        var extractedMetadata = AppleDocumentationClient().extractMetadata(sampleCodeDoc)
        var result = renderer.renderByContentType(sampleCodeDoc, metadata: extractedMetadata)
        XCTAssertTrue(result.contains("# 💻"))

        // Article
        let articleDoc = AppleDocumentation(
            metadata: DocumentationMetadata(role: "article"),
            kind: "article"
        )
        extractedMetadata = AppleDocumentationClient().extractMetadata(articleDoc)
        result = renderer.renderByContentType(articleDoc, metadata: extractedMetadata)
        XCTAssertTrue(result.contains("# 📝"))

        // Symbol
        let symbolDoc = AppleDocumentation(
            metadata: DocumentationMetadata(),
            kind: "symbol"
        )
        extractedMetadata = AppleDocumentationClient().extractMetadata(symbolDoc)
        result = renderer.renderByContentType(symbolDoc, metadata: extractedMetadata)
        XCTAssertTrue(result.contains("# ⚙️"))

        // Tutorial
        let tutorialDoc = AppleDocumentation(
            metadata: DocumentationMetadata(),
            kind: "tutorial"
        )
        extractedMetadata = AppleDocumentationClient().extractMetadata(tutorialDoc)
        result = renderer.renderByContentType(tutorialDoc, metadata: extractedMetadata)
        XCTAssertTrue(result.contains("# 🎓"))
    }

    // MARK: - Edge Cases Tests

    func testRenderWithMinimalData() {
        let documentation = AppleDocumentation(
            metadata: nil,
            abstract: nil,
            primaryContentSections: nil
        )

        let renderer = AppleDocumentationRenderer()
        let extractedMetadata = AppleDocumentationClient().extractMetadata(documentation)
        let result = renderer.renderByContentType(documentation, metadata: extractedMetadata)

        // Should not crash and should produce some output
        XCTAssertFalse(result.isEmpty)
    }

    func testRenderSampleCodeWithEmptyMetadata() {
        let documentation = AppleDocumentation(
            metadata: DocumentationMetadata(role: "sampleCode"),
            kind: "article"
        )

        let renderer = AppleDocumentationRenderer()
        let extractedMetadata = AppleDocumentationClient().extractMetadata(documentation)
        let result = renderer.renderByContentType(documentation, metadata: extractedMetadata)

        XCTAssertTrue(result.contains("# 💻"))
        // Should handle empty metadata gracefully without crashing
    }
}