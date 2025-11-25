import Foundation

/// Swift port of Apple documentation JSON to Markdown renderer
/// Based on sosumi.ai TypeScript rendering implementation
public class AppleDocumentationRenderer {

    // MARK: - Initialization

    public init() {}

    // MARK: - Properties

    private let baseURL = "https://developer.apple.com/documentation"

    // MARK: - Rendering Methods

    /// Renders Apple documentation to Markdown format
    public func renderToMarkdown(_ documentation: AppleDocumentation) -> String {
        var markdown = ""

        // Add frontmatter
        markdown += renderFrontmatter(documentation)

        // Add title
        if let title = documentation.metadata?.title {
            markdown += "# \(title)\n\n"
        }

        // Add abstract
        if let abstract = documentation.abstract {
            markdown += renderTextFragments(abstract)
            markdown += "\n"
        }

        // Add deprecated notice (from ContentItem)
        if let sections = documentation.sections {
            for section in sections {
                if let deprecatedSummary = section.deprecationSummary {
                    markdown += "!!! DEPRECATED\n"
                    markdown += renderTextFragments(deprecatedSummary)
                    markdown += "\n"
                }
            }
        }

        // Add availability information (from ContentItem)
        if let sections = documentation.sections {
            for section in sections {
                if let availability = section.availability {
                    markdown += renderAvailability(availability)
                }
            }
        }

        // Add primary content sections
        if let sections = documentation.primaryContentSections {
            for section in sections {
                markdown += renderPrimaryContentSection(section)
            }
        }

        // Add parameters section (from metadata)
        if let platforms = documentation.metadata?.platforms, !platforms.isEmpty {
            markdown += "\n## Availability\n"
            for platform in platforms {
                markdown += "- \(formatPlatform(platform))\n"
            }
            markdown += "\n"
        }

        // Add topic sections
        if let topicSections = documentation.topicSections {
            for section in topicSections {
                markdown += renderTopicSection(section)
            }
        }

        // Add see also sections
        if let seeAlsoSections = documentation.seeAlsoSections {
            for section in seeAlsoSections {
                markdown += renderSeeAlsoSection(section)
            }
        }

        // Check if content is suspiciously short
        if markdown.count < 400 && !(documentation.metadata?.title?.lowercased().contains("overview") ?? false) {
            markdown += """

⚠️ **Limited Content**

This page has minimal content in the API response. For complete details:
- Visit the full documentation: \(documentation.url ?? "developer.apple.com")
- Try: `sosumi docs "\(extractFramework(documentation.metadata?.title ?? ""))"` to browse the parent framework
"""
        }

        return markdown
    }

    // Add helper function to extract framework name
    private func extractFramework(_ title: String) -> String {
        let parts = title.split(separator: " ")
        return String(parts.first ?? "")
    }

    /// Renders a search result to a brief Markdown format
    public func renderSearchResult(_ result: DocumentationSearchResult) -> String {
        var markdown = "## [\(result.title)](\(result.url))\n\n"

        if let description = result.description {
            let truncated = description.count > 150
                ? String(description.prefix(150)) + "..."
                : description
            markdown += "\(truncated)\n\n"
        }

        markdown += "**Type:** \(result.type)\n\n"

        return markdown
    }

    /// Renders multiple search results
    public func renderSearchResults(_ response: DocumentationSearchResponse) -> String {
        var markdown = "# Search Results for \"\(response.query)\"\n\n"

        if response.results.isEmpty {
            markdown += "No results found.\n"
            return markdown
        }

        markdown += "**Found \(response.totalFound) results**\n\n"

        // Group results by type if metadata is available
        let groupedResults = Dictionary(grouping: response.results) { $0.type.capitalized }

        for (type, results) in groupedResults.sorted(by: { $0.key < $1.key }) {
            markdown += "## \(type)\n\n"
            for result in results {
                markdown += "- [\(result.title)](\(result.url))"
                if let description = result.description {
                    let truncated = description.count > 150
                        ? String(description.prefix(150)) + "..."
                        : description
                    markdown += " - \(truncated)"
                }
                markdown += "\n"
            }
            markdown += "\n"
        }

        return markdown
    }

    /// Renders search results in compact format for agent efficiency
    public func renderSearchResultsCompact(_ response: DocumentationSearchResponse) -> String {
        var markdown = ""

        if response.results.isEmpty {
            return "No results found."
        }

        // Simple flat list without grouping or descriptions for maximum efficiency
        for (index, result) in response.results.enumerated() {
            markdown += "\(index + 1). [\(result.title)](\(result.url))\n"
        }

        return markdown
    }

    /// Renders search results in compact format with match scores for ranking visibility
    public func renderSearchResultsCompactWithScores(_ response: DocumentationSearchResponse) -> String {
        var markdown = ""

        if response.results.isEmpty {
            return "No results found."
        }

        // Simple flat list with relevance scores for better ranking visibility
        // Calculate approximate scores based on ranking position since original scores are lost
        let totalResults = response.results.count
        for (index, result) in response.results.enumerated() {
            let score = calculateRankingScore(position: index, total: totalResults)
            markdown += "\(index + 1). [\(result.title)](\(result.url)) (\(score)% match)\n"
        }

        return markdown
    }

    /// Calculate approximate relevance score based on ranking position
    private func calculateRankingScore(position: Int, total: Int) -> String {
        // Top results get higher scores, decreasing linearly
        let maxScore = 95.0
        let minScore = 25.0
        let score = maxScore - (Double(position) / Double(total - 1)) * (maxScore - minScore)
        return String(format: "%.0f", score)
    }

    // MARK: - Private Rendering Methods

    /// Renders YAML frontmatter
    private func renderFrontmatter(_ documentation: AppleDocumentation) -> String {
        var frontmatter = "---\n"

        if let title = documentation.metadata?.title {
            frontmatter += "title: \(escapeYAML(title))\n"
        }

        if let kind = documentation.kind {
            frontmatter += "kind: \(escapeYAML(kind))\n"
        }

        if let role = documentation.metadata?.role {
            frontmatter += "role: \(escapeYAML(role))\n"
        }

        if let roleHeading = documentation.metadata?.roleHeading {
            frontmatter += "role_heading: \(escapeYAML(roleHeading))\n"
        }

        if let platforms = documentation.metadata?.platforms, !platforms.isEmpty {
            frontmatter += "platforms:\n"
            for platform in platforms {
                frontmatter += "  - \(escapeYAML(formatPlatform(platform)))\n"
            }
        }

        if let url = documentation.url {
            frontmatter += "url: \(escapeYAML(url))\n"
        }

        if let identifier = documentation.identifier {
            if let url = identifier.url {
                frontmatter += "identifier_url: \(escapeYAML(url))\n"
            }
            if let language = identifier.interfaceLanguage {
                frontmatter += "identifier_interface_language: \(escapeYAML(language))\n"
            }
        }

        frontmatter += "---\n\n"
        return frontmatter
    }

    /// Renders text fragments to Markdown
    private func renderTextFragments(_ fragments: [TextFragment], level: Int = 0) -> String {
        return fragments.map { renderTextFragment($0, level: level) }.joined()
    }

    /// Formats platform metadata into human-readable text
    private func formatPlatform(_ platform: DocumentationPlatform) -> String {
        var components: [String] = []
        if let name = platform.name {
            components.append(name)
        }

        var details: [String] = []
        if let introduced = platform.introducedAt {
            details.append("introduced \(introduced)")
        }
        if let current = platform.current {
            details.append("current \(current)")
        }

        if !details.isEmpty {
            components.append("(\(details.joined(separator: ", ")))")
        }

        if components.isEmpty {
            return "Unknown Platform"
        }

        return components.joined(separator: " ")
    }

    /// Renders a single text fragment
    private func renderTextFragment(_ fragment: TextFragment, level: Int = 0) -> String {
        var output = ""

        switch fragment.type {
        case "text":
            if let text = fragment.text {
                output += text
            }

        case "heading":
            if let heading = fragment.heading {
                let prefix = String(repeating: "#", count: min(level + 1, 6))
                output += "\(prefix) \(heading)\n\n"
            }

        case "code":
            if let codeValue = fragment.code {
                let code = codeValue.text
                if code.contains("\n") {
                    output += "```swift\n\(code)\n```\n\n"
                } else {
                    output += "`\(code)`"
                }
            }

        case "inlineCode":
            if let inlineCode = fragment.inlineCode {
                output += "`\(inlineCode)`"
            }

        case "emphasis":
            if let emphasis = fragment.emphasis {
                let rendered = renderTextFragments(emphasis, level: level)
                output += "*\(rendered.trimmingCharacters(in: .whitespacesAndNewlines))*"
            }

        case "strong":
            if let strong = fragment.strong {
                let rendered = renderTextFragments(strong, level: level)
                output += "**\(rendered.trimmingCharacters(in: .whitespacesAndNewlines))**"
            }

        case "link":
            if let url = fragment.url {
                let normalizedURL = normalizedURLString(url)
                if let text = fragment.text {
                    output += "[\(text)](\(normalizedURL))"
                } else {
                    output += "<\(normalizedURL)>"
                }
            }

        case "image":
            if let imageURL = fragment.imageURL, let caption = fragment.caption {
                let captionText = renderTextFragments(caption, level: level).trimmingCharacters(in: .whitespacesAndNewlines)
                output += "![\(captionText)](\(imageURL))"
                if let aspectRatio = fragment.aspectRatio {
                    output += " (aspect ratio: \(aspectRatio))"
                }
                output += "\n\n"
            }

        case "listItem":
            if let content = fragment.content {
                let rendered = renderTextFragments(content, level: level).trimmingCharacters(in: .whitespacesAndNewlines)
                output += "- \(rendered)\n"
            }

        case "table":
            if let content = fragment.content {
                output += renderTextFragments(content, level: level)
            }

        case "parameter":
            if let name = fragment.parameters?.first?.name, let content = fragment.content {
                let rendered = renderTextFragments(content, level: level).trimmingCharacters(in: .whitespacesAndNewlines)
                output += "- **\(name)**: \(rendered)\n"
            }

        case "returns":
            if fragment.returns != nil, let content = fragment.content {
                let rendered = renderTextFragments(content, level: level).trimmingCharacters(in: .whitespacesAndNewlines)
                output += "- **Returns**: \(rendered)\n"
            }

        case "throws":
            if fragment.thrown != nil, let content = fragment.content {
                let rendered = renderTextFragments(content, level: level).trimmingCharacters(in: .whitespacesAndNewlines)
                output += "- **Throws**: \(rendered)\n"
            }

        default:
            // Handle unknown types by rendering text if available
            if let text = fragment.text {
                output += text
            }
        }

        // Handle newlines
        if let newlines = fragment.newlines, newlines > 0 {
            output += String(repeating: "\n", count: newlines)
        }

        return output
    }

    /// Renders a primary content section
    private func renderPrimaryContentSection(_ section: PrimaryContentSection) -> String {
        var markdown = ""

        if let title = section.title {
            markdown += "## \(title)\n\n"
        }

        if let content = section.content {
            markdown += renderTextFragments(content)
            markdown += "\n"
        }

        return markdown
    }

    /// Renders a topic section
    private func renderTopicSection(_ section: TopicSection) -> String {
        var markdown = "## \(section.title)\n\n"

        for identifier in section.identifiers {
            let url = normalizedURLString(identifier, defaultPathPrefix: baseURL)
            markdown += "- [\(identifier)](\(url))\n"
        }

        markdown += "\n"
        return markdown
    }

    /// Renders a see also section
    private func renderSeeAlsoSection(_ section: SeeAlsoSection) -> String {
        var markdown = ""

        if let title = section.title {
            markdown += "## \(title)\n\n"
        } else {
            markdown += "## See Also\n\n"
        }

        if let destinations = section.destinations {
            for destination in destinations {
                if let title = destination.title {
                    if let url = destination.url {
                        markdown += "- [\(title)](\(normalizedURLString(url)))\n"
                    } else if let identifier = destination.identifier {
                        let url = normalizedURLString(identifier, defaultPathPrefix: baseURL)
                        markdown += "- [\(title)](\(url))\n"
                    }
                }
            }
        }

        markdown += "\n"
        return markdown
    }

    /// Renders availability information
    private func renderAvailability(_ availability: [AvailabilityInfo]) -> String {
        var markdown = "\n## Platform Availability\n\n"

        for item in availability {
            var line = ""
            if let name = item.name {
                line += "**\(name)**"
                if let introduced = item.introduced {
                    line += " (introduced: \(introduced))"
                }
                if item.deprecated == true {
                    line += " ⚠️ **Deprecated**"
                    if let message = item.message {
                        line += " - \(message)"
                    }
                }
            }
            if !line.isEmpty {
                markdown += "- \(line)\n"
            }
        }

        return markdown + "\n"
    }

    // MARK: - Utility Methods

    /// Escapes strings for YAML output
    private func escapeYAML(_ string: String) -> String {
        var escaped = string

        // Escape special characters
        escaped = escaped.replacingOccurrences(of: "\"", with: "\\\"")
        escaped = escaped.replacingOccurrences(of: "\n", with: "\\n")
        escaped = escaped.replacingOccurrences(of: "\r", with: "\\r")
        escaped = escaped.replacingOccurrences(of: "\t", with: "\\t")

        // Add quotes if string contains special characters that need quoting
        let needsQuotes = escaped.contains(":") || escaped.contains("{") || escaped.contains("}") ||
                          escaped.contains("[") || escaped.contains("]") || escaped.contains(",") ||
                          escaped.contains("&") || escaped.contains("*") || escaped.contains("#") ||
                          escaped.contains("|") || escaped.contains(">") || escaped.contains("'") ||
                          escaped.contains("\"") || escaped.isEmpty || escaped.first == " " || escaped.last == " "

        return needsQuotes ? "\"\(escaped)\"" : escaped
    }

    /// Sanitizes filenames for file system use
    public func sanitizeFilename(_ title: String) -> String {
        return title
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "\\", with: "_")
            .replacingOccurrences(of: ":", with: "_")
            .replacingOccurrences(of: "*", with: "_")
            .replacingOccurrences(of: "?", with: "_")
            .replacingOccurrences(of: "\"", with: "_")
            .replacingOccurrences(of: "<", with: "_")
            .replacingOccurrences(of: ">", with: "_")
            .replacingOccurrences(of: "|", with: "_")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Gets a filename for documentation based on title and identifier
    public func getDocumentationFilename(_ documentation: AppleDocumentation) -> String {
        let title = documentation.metadata?.title ?? "untitled"
        let identifierComponent = documentation.identifier?.url ?? documentation.identifier?.interfaceLanguage ?? "unknown"
        let sanitizedTitle = sanitizeFilename(title)
        let sanitizedIdentifier = sanitizeFilename(identifierComponent)
        return "\(sanitizedTitle)_\(sanitizedIdentifier).md"
    }

    private func normalizedURLString(_ url: String, defaultPathPrefix: String? = nil) -> String {
        if let normalized = DocURLUtilities.toWebURL(url) {
            return normalized
        }
        if let prefix = defaultPathPrefix {
            return "\(prefix)/\(url)"
        }
        return url
    }
}

// MARK: - Extensions

extension AppleDocumentationRenderer {

    /// Renders framework index to Markdown
    public func renderFrameworkIndex(_ items: [FrameworkIndex], frameworkName: String) -> String {
        var markdown = "# \(frameworkName.capitalized) Documentation Index\n\n"

        // Group by kind
        let groupedItems = Dictionary(grouping: items) { $0.kind.capitalized }

        for (kind, items) in groupedItems.sorted(by: { $0.key < $1.key }) {
            markdown += "## \(kind)\n\n"

            for item in items.sorted(by: { $0.name < $1.name }) {
                markdown += "### [\(item.name)](\(item.url))\n\n"

                if let abstract = item.abstract {
                    let abstractText = abstract.compactMap { fragment in
                        if fragment.type == "text" { return fragment.text }
                        return nil
                    }.joined(separator: " ")

                    if !abstractText.isEmpty {
                        markdown += "\(abstractText)\n\n"
                    }
                }

                markdown += "**Role:** \(item.role)\n\n"
            }
        }

        return markdown
    }

    /// Creates a summary of search metadata
    public func renderSearchMetadata(_ metadata: [String: Int]) -> String {
        var markdown = "## Search Summary\n\n"

        if metadata.isEmpty {
            markdown += "No search metadata available.\n\n"
            return markdown
        }

        let total = metadata.values.reduce(0, +)
        markdown += "**Total Results:** \(total)\n\n"

        for (source, count) in metadata.sorted(by: { $0.key < $1.key }) {
            markdown += "- **\(source):** \(count) results\n"
        }

        markdown += "\n"
        return markdown
    }
}

// MARK: - Content Type Specific Rendering

public extension AppleDocumentationRenderer {

    /// Main dispatcher that renders by content type using extracted metadata
    func renderByContentType(_ documentation: AppleDocumentation, metadata: ExtractedMetadata) -> String {
        switch metadata.contentType {
        case .sampleCode:
            return renderSampleCode(documentation, metadata: metadata)
        case .article:
            return renderArticle(documentation, metadata: metadata)
        case .symbol:
            return renderSymbol(documentation, metadata: metadata)
        case .tutorial:
            return renderTutorial(documentation, metadata: metadata)
        case .generic:
            return renderGeneric(documentation, metadata: metadata)
        }
    }

    /// Renders sample code with requirements, time estimates, and related content
    private func renderSampleCode(_ documentation: AppleDocumentation, metadata: ExtractedMetadata) -> String {
        var output = ""

        // Header with sample code badge
        if let title = documentation.metadata?.title {
            output += "# 💻 \(title)\n"
        } else {
            output += "# 💻 Sample Code\n"
        }

        if let roleHeading = metadata.roleHeading {
            output += "*\(roleHeading)*\n\n"
        }

        // Requirements section
        if !metadata.requirements.isEmpty {
            output += "## Requirements\n"
            for req in metadata.requirements {
                output += "- \(req)\n"
            }
            output += "\n"
        }

        // Time estimate
        if let time = metadata.timeEstimate {
            output += "**Estimated Time:** \(time)\n\n"
        }

        // Platform availability
        if !metadata.platforms.isEmpty {
            output += "## Platforms\n"
            for platform in metadata.platforms {
                output += "- \(platform)\n"
            }
            output += "\n"
        }

        // Abstract
        if let abstract = documentation.abstract {
            output += renderTextFragments(abstract)
            output += "\n\n"
        }

        // Main content sections
        if let sections = documentation.primaryContentSections {
            for section in sections {
                output += renderPrimaryContentSection(section)
            }
        }

        // Related sample code
        if !metadata.relatedTopics.isEmpty {
            output += "## See Also\n"
            for topic in metadata.relatedTopics {
                output += "- \(topic)\n"
            }
            output += "\n"
        }

        return output
    }

    /// Renders articles with breadcrumbs, prerequisites, and learning paths
    private func renderArticle(_ documentation: AppleDocumentation, metadata: ExtractedMetadata) -> String {
        var output = ""

        // Header with article badge
        if let title = documentation.metadata?.title {
            output += "# 📝 \(title)\n"
        } else {
            output += "# 📝 Article\n"
        }

        // Breadcrumbs for context
        output += formatBreadcrumbs(metadata.breadcrumbs) + "\n"

        // Prerequisites if any
        if !metadata.requirements.isEmpty {
            output += "## Prerequisites\n"
            for req in metadata.requirements {
                output += "- \(req)\n"
            }
            output += "\n"
        }

        // Learning time
        if let time = metadata.timeEstimate {
            output += "**Learning Time:** \(time)\n\n"
        }

        // Abstract
        if let abstract = documentation.abstract {
            output += renderTextFragments(abstract)
            output += "\n\n"
        }

        // Main content
        if let sections = documentation.primaryContentSections {
            for section in sections {
                output += renderPrimaryContentSection(section)
            }
        }

        // Related learning paths
        if !metadata.relatedTopics.isEmpty {
            output += "## Learn More\n"
            for topic in metadata.relatedTopics {
                output += "- \(topic)\n"
            }
            output += "\n"
        }

        return output
    }

    /// Renders symbols with platform availability, conformances, and technical details
    private func renderSymbol(_ documentation: AppleDocumentation, metadata: ExtractedMetadata) -> String {
        var output = ""

        // Header with symbol badge
        if let title = documentation.metadata?.title {
            output += "# ⚙️ \(title)\n"
        } else {
            output += "# ⚙️ Symbol\n"
        }

        // Platform availability with version info
        if !metadata.platforms.isEmpty {
            output += "**Availability:**\n"
            for platform in metadata.platforms {
                output += "- \(platform)\n"
            }
            output += "\n"
        }

        // Conformances / relationships
        output += formatRelationships(metadata.relationships) + "\n"

        // Abstract
        if let abstract = documentation.abstract {
            output += renderTextFragments(abstract)
            output += "\n\n"
        }

        // Declaration/signature (from primary content sections)
        if let sections = documentation.primaryContentSections {
            for section in sections {
                output += renderPrimaryContentSection(section)
            }
        }

        // Related symbols
        if !metadata.relatedTopics.isEmpty {
            output += "## Related\n"
            for topic in metadata.relatedTopics {
                output += "- \(topic)\n"
            }
            output += "\n"
        }

        return output
    }

    /// Renders tutorials with step-by-step guidance and learning objectives
    private func renderTutorial(_ documentation: AppleDocumentation, metadata: ExtractedMetadata) -> String {
        var output = ""

        // Header with tutorial badge
        if let title = documentation.metadata?.title {
            output += "# 🎓 \(title)\n"
        } else {
            output += "# 🎓 Tutorial\n"
        }

        // Role heading
        if let roleHeading = metadata.roleHeading {
            output += "*\(roleHeading)*\n\n"
        }

        // Time estimate (important for tutorials)
        if let time = metadata.timeEstimate {
            output += "**⏱️ Duration:** \(time)\n\n"
        }

        // Difficulty level if available
        if let customMeta = metadata.customMetadata["skillLevel"] as? String {
            output += "**📊 Difficulty:** \(customMeta)\n\n"
        }

        // Abstract
        if let abstract = documentation.abstract {
            output += renderTextFragments(abstract)
            output += "\n\n"
        }

        // Main tutorial content
        if let sections = documentation.primaryContentSections {
            for section in sections {
                output += renderPrimaryContentSection(section)
            }
        }

        // What's next
        if !metadata.relatedTopics.isEmpty {
            output += "## What's Next\n"
            for topic in metadata.relatedTopics {
                output += "- \(topic)\n"
            }
            output += "\n"
        }

        return output
    }

    /// Generic fallback renderer for unknown content types
    private func renderGeneric(_ documentation: AppleDocumentation, metadata: ExtractedMetadata) -> String {
        var output = ""

        // Standard header
        if let title = documentation.metadata?.title {
            output += "# \(title)\n"
        }

        // Role heading if available
        if let roleHeading = metadata.roleHeading {
            output += "*\(roleHeading)*\n\n"
        }

        // Abstract
        if let abstract = documentation.abstract {
            output += renderTextFragments(abstract)
            output += "\n\n"
        }

        // Main content
        if let sections = documentation.primaryContentSections {
            for section in sections {
                output += renderPrimaryContentSection(section)
            }
        }

        // Basic metadata
        if !metadata.platforms.isEmpty {
            output += "## Platforms\n"
            for platform in metadata.platforms {
                output += "- \(platform)\n"
            }
            output += "\n"
        }

        return output
    }

    /// Formats breadcrumb navigation
    private func formatBreadcrumbs(_ crumbs: [String]) -> String {
        guard !crumbs.isEmpty else { return "" }
        return "📍 " + crumbs.joined(separator: " > ") + "\n"
    }

    /// Formats relationship information (conformances, inheritance, etc.)
    private func formatRelationships(_ relationships: [String: [String]]) -> String {
        guard !relationships.isEmpty else { return "" }

        var output = "## Details\n"
        for (type, items) in relationships {
            output += "**\(type.capitalized):**\n"
            for item in items {
                output += "- \(item)\n"
            }
            output += "\n"
        }
        return output
    }
}
