import Testing
@testable import SosumiDocs

@Suite("Content Type Rendering Tests")
struct ContentTypeRenderingTests {

    // MARK: - Sample Code Rendering Tests

    @Test("Render sample code markdown")
    func renderSampleCodeMarkdown() {
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

        #expect(result.contains("# 💻"))
        #expect(result.contains("Requirements"))
        #expect(result.contains("iOS 14+"))
        #expect(result.contains("Xcode 12+"))
        #expect(result.contains("Estimated Time: 15 minutes"))
        #expect(result.contains("Platforms"))
        #expect(result.contains("iOS (14.0+)"))
        #expect(result.contains("Implementation"))
        #expect(result.contains("Here's the code implementation"))
    }

    // MARK: - Article Rendering Tests

    @Test("Render article markdown")
    func renderArticleMarkdown() {
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

        #expect(result.contains("# 📝"))
        #expect(result.contains("📍 SwiftUI > Layout > Stacks"))
        #expect(result.contains("Learn about SwiftUI's layout system"))
        #expect(result.contains("Introduction"))
        #expect(result.contains("SwiftUI provides powerful layout tools"))
    }

    @Test("Render article with prerequisites")
    func renderArticleWithPrerequisites() {
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

        #expect(result.contains("# 📝"))
        #expect(result.contains("Prerequisites"))
        #expect(result.contains("Basic Swift knowledge"))
        #expect(result.contains("UI development experience"))
        #expect(result.contains("Learning Time: 20 minutes"))
    }

    // MARK: - Symbol Rendering Tests

    @Test("Render symbol markdown")
    func renderSymbolMarkdown() {
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

        #expect(result.contains("# ⚙️"))
        #expect(result.contains("Availability"))
        #expect(result.contains("iOS (13.0+)"))
        #expect(result.contains("macOS (10.15+)"))
        #expect(result.contains("Details"))
        #expect(result.contains("Conformances"))
        #expect(result.contains("View"))
        #expect(result.contains("Identifiable"))
        #expect(result.contains("A custom view that displays content"))
    }

    // MARK: - Tutorial Rendering Tests

    @Test("Render tutorial markdown")
    func renderTutorialMarkdown() {
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

        #expect(result.contains("# 🎓"))
        #expect(result.contains("⏱️ Duration: 45 minutes"))
        #expect(result.contains("📊 Difficulty: Intermediate"))
        #expect(result.contains("Step-by-step guide to building a SwiftUI app"))
        #expect(result.contains("Getting Started"))
        #expect(result.contains("Let's start by creating a new project"))
    }

    // MARK: - Generic Rendering Tests

    @Test("Render generic markdown")
    func renderGenericMarkdown() {
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

        #expect(result.contains("# "))  // Has title header
        #expect(result.contains("Generic content description"))
        #expect(result.contains("Platforms"))
        #expect(result.contains("iOS (14.0+)"))
    }

    // MARK: - Rendering Method Selection Tests

    @Test("Render by content type dispatcher")
    func renderByContentTypeDispatcher() {
        let renderer = AppleDocumentationRenderer()
        let client = AppleDocumentationClient()

        // Sample code
        let sampleCodeDoc = AppleDocumentation(
            metadata: DocumentationMetadata(role: "sampleCode"),
            kind: "article"
        )
        var extractedMetadata = client.extractMetadata(sampleCodeDoc)
        var result = renderer.renderByContentType(sampleCodeDoc, metadata: extractedMetadata)
        #expect(result.contains("# 💻"))

        // Article
        let articleDoc = AppleDocumentation(
            metadata: DocumentationMetadata(role: "article"),
            kind: "article"
        )
        extractedMetadata = client.extractMetadata(articleDoc)
        result = renderer.renderByContentType(articleDoc, metadata: extractedMetadata)
        #expect(result.contains("# 📝"))

        // Symbol
        let symbolDoc = AppleDocumentation(
            metadata: DocumentationMetadata(),
            kind: "symbol"
        )
        extractedMetadata = client.extractMetadata(symbolDoc)
        result = renderer.renderByContentType(symbolDoc, metadata: extractedMetadata)
        #expect(result.contains("# ⚙️"))

        // Tutorial
        let tutorialDoc = AppleDocumentation(
            metadata: DocumentationMetadata(),
            kind: "tutorial"
        )
        extractedMetadata = client.extractMetadata(tutorialDoc)
        result = renderer.renderByContentType(tutorialDoc, metadata: extractedMetadata)
        #expect(result.contains("# 🎓"))
    }

    // MARK: - Edge Cases Tests

    @Test("Render with minimal data")
    func renderWithMinimalData() {
        let documentation = AppleDocumentation(
            metadata: nil,
            abstract: nil,
            primaryContentSections: nil
        )

        let renderer = AppleDocumentationRenderer()
        let extractedMetadata = AppleDocumentationClient().extractMetadata(documentation)
        let result = renderer.renderByContentType(documentation, metadata: extractedMetadata)

        // Should not crash and should produce some output
        #expect(!result.isEmpty)
    }

    @Test("Render sample code with empty metadata")
    func renderSampleCodeWithEmptyMetadata() {
        let documentation = AppleDocumentation(
            metadata: DocumentationMetadata(role: "sampleCode"),
            kind: "article"
        )

        let renderer = AppleDocumentationRenderer()
        let extractedMetadata = AppleDocumentationClient().extractMetadata(documentation)
        let result = renderer.renderByContentType(documentation, metadata: extractedMetadata)

        #expect(result.contains("# 💻"))
        // Should handle empty metadata gracefully without crashing
    }
}