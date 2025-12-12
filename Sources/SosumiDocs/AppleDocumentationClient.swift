import Foundation

import SmithDocExtractor

// MARK: - Compatibility Aliases
// These allow existing code to continue working while we transition to generic types
public typealias AppleDocumentation = DocCRenderNode
public typealias DocumentationSearchResult = DocCSearchResult
// Helper aliases (though simple import should suffice if names match)

/// URLSession-based client for accessing Apple Developer JSON documentation APIs
/// Based on sosumi.ai implementation for accessing undocumented Apple endpoints
public class AppleDocumentationClient {

    // MARK: - Properties

    private let fetcher: DocCJSONFetcher
    private let session: URLSession // Restored for non-standard endpoints
    private let baseURL = "https://developer.apple.com/tutorials/data"
    // Keep internal legacy URL handling for now until fully refactored
    private let documentationBaseURL = "https://developer.apple.com"
    private let userAgentPool: [String]
    
    public enum DocumentationSource {
        case documentation(String)
        case humanInterfaceGuidelines(String)
        case humanInterfaceGuidelinesTableOfContents
    }

    // MARK: - Constants

    /// List of Safari user agents for rotation (from sosumi.ai)
    private static let safariUserAgents = [
        "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
        "Mozilla/5.0 (iPad; CPU OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15",
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Safari/605.1.15",
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.6.1 Safari/605.1.15",
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.6 Safari/605.1.15",
        "Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1",
        "Mozilla/5.0 (iPad; CPU OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1"
    ]

    // MARK: - Errors

    public enum ClientError: Error, LocalizedError {
        case invalidURL(String)
        case networkError(Error)
        case decodingError(Error)
        case notFound
        case invalidResponse

        public var errorDescription: String? {
            switch self {
            case .invalidURL(let url):
                return "Invalid URL: \(url)"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .decodingError(let error):
                return "Decoding error: \(error.localizedDescription)"
            case .notFound:
                return "Documentation not found"
            case .invalidResponse:
                return "Invalid response from server"
            }
        }
    }

    // MARK: - Initialization

    public init() {
        self.fetcher = DocCJSONFetcher(baseURL: "https://developer.apple.com")
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: configuration)
        // Hardcoded pool for now or use the one from Fetcher if accessible (simpler to duplicate for now)
        self.userAgentPool = [
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
            "Mozilla/5.0 (iPad; CPU OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        ]
    }

    // MARK: - Public Methods

    /// Resolves the appropriate documentation source (regular doc vs HIG)
    public func resolveSource(for path: String) -> DocumentationSource {
        if let higPath = extractHIGPath(from: path) {
            if higPath.isEmpty {
                return .humanInterfaceGuidelinesTableOfContents
            } else {
                return .humanInterfaceGuidelines(higPath)
            }
        }

        let normalized = normalizeDocumentationPath(path)
        return .documentation(normalized)
    }

    /// Fetches framework documentation index
    public func fetchFrameworkIndex(framework: String) async throws -> [FrameworkIndex] {
        let url = "\(baseURL)/index/\(framework)"
        let response: FrameworkIndexTreeResponse = try await performRequest(url: url)

        let interfaceNodes = response.interfaceLanguages.values.flatMap { $0 }
        let flattened = interfaceNodes.flatMap { flattenFrameworkNodes($0) }

        // Deduplicate by URL while preserving order
        var seen = Set<String>()
        var deduplicated: [FrameworkIndex] = []
        for entry in flattened {
            if seen.insert(entry.url).inserted {
                deduplicated.append(entry)
            }
        }

        return deduplicated
    }

    /// Fetches documentation for a specific path
    public func fetchDocumentation(path: String) async throws -> AppleDocumentation {
        // Delegate to generic fetcher which handles normalization and fetching
        // Note: The generic fetcher returns DocCRenderNode which is aliased to AppleDocumentation
        return try await fetcher.fetchDocumentation(path: path)
    }

    /// Fetches HIG table of contents
    public func fetchHIGTableOfContents() async throws -> HIGTableOfContents {
        let url = "\(baseURL)/index/design--human-interface-guidelines"
        return try await performRequest(url: url)
    }

    /// Fetches a specific HIG page by path (e.g. "shareplay")
    public func fetchHIGPage(path: String) async throws -> HIGPage {
        let slug = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let url = "\(baseURL)/design/human-interface-guidelines/\(slug).json"
        return try await performRequest(url: url)
    }

    /// Searches for documentation matching a query
    public func searchDocumentation(query: String, frameworks: [String]? = nil) async throws -> [DocumentationSearchResult] {
        var results: [DocumentationSearchResult] = []

        let targetFrameworks = frameworks ?? [
            "swiftui", "swiftdata", "combine", "async-await", "concurrency",
            "uikit", "appkit", "coredata", "metal", "arkit", "visionos",
            "widgetkit", "eventkit", "coreml", "avfoundation", "mapkit",
            "bundleresources"
        ]

        for framework in targetFrameworks {
            do {
                let indexItems = try await fetchFrameworkIndex(framework: framework)
                let matchingItems = indexItems.filter { item in
                    item.name.localizedCaseInsensitiveContains(query) ||
                    item.url.localizedCaseInsensitiveContains(query)
                }

                let searchResults = matchingItems.map { item in
                    DocumentationSearchResult(
                        title: item.name,
                        url: item.url,
                        type: item.kind,
                        description: item.abstract?.compactMap { $0.text }.joined(separator: " "),
                        identifier: extractIdentifier(from: item.url)
                    )
                }

                results.append(contentsOf: searchResults)
            } catch {
                // Continue with other frameworks if one fails
                continue
            }
        }

        return results.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    /// Searches HIG (Human Interface Guidelines) matching a query
    public func searchHumanInterfaceGuidelines(query: String) async throws -> [DocumentationSearchResult] {
        var results: [DocumentationSearchResult] = []

        do {
            // Extract HIG path from URL if provided
            var searchQuery = query
            if let higPath = extractHIGPath(from: query) {
                // If it's a HIG URL, search for the last path component
                searchQuery = higPath.split(separator: "/").last.map(String.init) ?? higPath
            }

            let toc = try await fetchHIGTableOfContents()

            // Flatten the TOC structure and search for matches
            if let items = toc.interfaceLanguages?.swift {
                let flattenedItems = flattenHIGTocItems(items)
                let matchingItems = flattenedItems.filter { item in
                    (item.title?.localizedCaseInsensitiveContains(searchQuery) ?? false) ||
                    (item.path?.localizedCaseInsensitiveContains(searchQuery) ?? false)
                }

                let searchResults = matchingItems.compactMap { item -> DocumentationSearchResult? in
                    guard let path = item.path else { return nil }
                    let title = item.title ?? path
                    let url = "\(documentationBaseURL)\(path)"
                    return DocumentationSearchResult(
                        title: title,
                        url: url,
                        type: "Human Interface Guideline",
                        description: nil,
                        identifier: extractIdentifier(from: path)
                    )
                }

                results.append(contentsOf: searchResults)
            }
        } catch {
            // If HIG search fails, return empty results
            return []
        }

        return results.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    /// Flattens HIG TOC items into a searchable list
    private func flattenHIGTocItems(_ items: [HIGTocItem]) -> [HIGTocItem] {
        var flattened: [HIGTocItem] = []
        for item in items {
            flattened.append(item)
            if let children = item.children {
                flattened.append(contentsOf: flattenHIGTocItems(children))
            }
        }
        return flattened
    }

    // MARK: - Private Methods

    /// Performs a network request and decodes the response
    private func performRequest<T: Codable>(url: String, responseType: T.Type = T.self) async throws -> T {
        guard let requestURL = URL(string: url) else {
            throw ClientError.invalidURL(url)
        }

        var request = URLRequest(url: requestURL)
        request.setValue(selectRandomUserAgent(), forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw ClientError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 200...299:
                break
            case 404:
                throw ClientError.notFound
            default:
                throw ClientError.networkError(URLError(.badServerResponse))
            }

            do {
                let decoder = JSONDecoder()
                return try decoder.decode(T.self, from: data)
            } catch {
                throw ClientError.decodingError(error)
            }

        } catch {
            if let clientError = error as? ClientError {
                throw clientError
            } else {
                throw ClientError.networkError(error)
            }
        }
    }

    /// Selects a random Safari user agent from the pool
    private func selectRandomUserAgent() -> String {
        return userAgentPool.randomElement() ?? Self.safariUserAgents[0]
    }

    /// Normalizes a documentation path (removes .json, ensures proper format)
    private func normalizeDocumentationPath(_ path: String) -> String {
        var normalized = path.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.isEmpty {
            return "documentation"
        }

        normalized = normalizedURLString(for: normalized)

        if let components = URLComponents(string: normalized) {
            normalized = components.path
        }

        if normalized.hasPrefix("/") {
            normalized.removeFirst()
        }

        if normalized.hasPrefix("tutorials/data/") {
            normalized = String(normalized.dropFirst("tutorials/data/".count))
        }

        normalized = normalized.replacingOccurrences(of: ".json", with: "")
        normalized = normalized.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        if !normalized.hasPrefix("documentation/") {
            normalized = "documentation/\(normalized)"
        }

        return normalized
    }

    /// Attempts to extract an HIG path if present
    private func extractHIGPath(from path: String) -> String? {
        let normalized = normalizedURLString(for: path)
        guard let components = URLComponents(string: normalized) else {
            return nil
        }

        let trimmedPath = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let lower = trimmedPath.lowercased()
        let higPrefix = "design/human-interface-guidelines"
        guard lower.hasPrefix(higPrefix) else {
            return nil
        }

        let suffix = trimmedPath.dropFirst(higPrefix.count)
        return suffix.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    private func normalizedURLString(for rawPath: String) -> String {
        var normalized = rawPath.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.isEmpty {
            return "\(documentationBaseURL)/documentation"
        }

        if normalized.hasPrefix("doc://") {
            let remainder = normalized.dropFirst("doc://".count)
            if remainder.hasPrefix("/") {
                normalized = "\(documentationBaseURL)\(remainder)"
            } else if let slashIndex = remainder.firstIndex(of: "/") {
                let prefix = remainder[..<slashIndex]
                let suffix = remainder[slashIndex...]  // includes leading slash
                if prefix.contains(".") {
                    normalized = "\(documentationBaseURL)\(suffix)"
                } else {
                    normalized = "\(documentationBaseURL)/\(remainder)"
                }
            } else if remainder.isEmpty {
                normalized = documentationBaseURL
            } else {
                normalized = "\(documentationBaseURL)/\(remainder)"
            }
        } else if normalized.hasPrefix("developer.apple.com/") {
            normalized = "https://" + normalized
        } else if normalized.hasPrefix("//") {
            normalized = "https:" + normalized
        } else if !normalized.contains("://") {
            if normalized.lowercased().hasPrefix("design/") {
                normalized = "\(documentationBaseURL)/\(normalized)"
            } else if normalized.lowercased().hasPrefix("documentation/") {
                normalized = "\(documentationBaseURL)/\(normalized)"
            } else {
                normalized = "\(documentationBaseURL)/documentation/\(normalized)"
            }
        }

        return normalized
    }

    /// Extracts identifier from Apple Developer URL
    private func extractIdentifier(from url: String) -> String? {
        let components = url.components(separatedBy: "/")
        return components.last?.replacingOccurrences(of: ".json", with: "")
    }

    /// Flattens framework index nodes into searchable entries
    private func flattenFrameworkNodes(_ node: FrameworkIndexNode) -> [FrameworkIndex] {
        var results: [FrameworkIndex] = []

        if let path = node.path,
           let title = node.title,
           node.type?.lowercased() != "groupmarker" {
            let normalizedURL = normalizeDocumentationURL(path)
            let entry = FrameworkIndex(
                name: title,
                url: normalizedURL,
                kind: node.type ?? "topic",
                role: node.role ?? node.type ?? "topic",
                abstract: node.abstract
            )
            results.append(entry)
        }

        if let children = node.children {
            for child in children {
                results.append(contentsOf: flattenFrameworkNodes(child))
            }
        }

        return results
    }

    /// Normalizes documentation URLs to include the developer.apple.com host
    private func normalizeDocumentationURL(_ path: String) -> String {
        if path.hasPrefix("http") {
            return path
        }

        let trimmedPath = path.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedPath.hasPrefix("/") {
            return "\(documentationBaseURL)\(trimmedPath)"
        } else if trimmedPath.hasPrefix("documentation/") {
            return "\(documentationBaseURL)/\(trimmedPath)"
        } else {
            return "\(documentationBaseURL)/documentation/\(trimmedPath)"
        }
    }

    // MARK: - Response Types

    /// Framework index response wrapper
    private struct FrameworkIndexTreeResponse: Codable {
        let interfaceLanguages: [String: [FrameworkIndexNode]]
    }

    /// Tree node for framework index entries
    private struct FrameworkIndexNode: Codable {
        let path: String?
        let title: String?
        let type: String?
        let role: String?
        let abstract: [TextFragment]?
        let external: Bool?
        let children: [FrameworkIndexNode]?
    }

    /// Response metadata (retained for other endpoints)
    private struct ResponseMetadata: Codable {
        let version: String?
        let generated: String?
    }

    // MARK: - Utility Methods

    /// Validates if a framework is supported
    public func isValidFramework(_ framework: String) -> Bool {
        let supportedFrameworks = [
            "swiftui", "swiftdata", "combine", "async-await", "concurrency",
            "uikit", "appkit", "coredata", "metal", "arkit", "visionos",
            "widgetkit", "eventkit", "coreml", "avfoundation", "mapkit",
            "bundleresources"
        ]
        return supportedFrameworks.contains(framework.lowercased())
    }

    /// Gets the base URL for debugging
    public func getBaseURL() -> String {
        return baseURL
    }
}

// MARK: - Search Extensions

extension AppleDocumentationClient {

    /// Comprehensive search across multiple query formats
    public func comprehensiveSearch(query: String) async throws -> DocumentationSearchResponse {
        var allResults: [DocumentationSearchResult] = []
        var searchMetadata: [String: Int] = [:]

        // Direct documentation search
        let docResults = try await searchDocumentation(query: query)
        allResults.append(contentsOf: docResults)
        searchMetadata["documentation"] = docResults.count

        // HIG search
        let higResults = try await searchHumanInterfaceGuidelines(query: query)
        let newHIGResults = higResults.filter { result in
            !allResults.contains { $0.url == result.url }
        }
        allResults.append(contentsOf: newHIGResults)
        searchMetadata["human_interface_guidelines"] = newHIGResults.count

        // Framework-specific searches
        let queryWords = query.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }

        for word in queryWords {
            if isValidFramework(word) {
                let frameworkResults = try await searchDocumentation(query: query, frameworks: [word])
                let newResults = frameworkResults.filter { result in
                    !allResults.contains { $0.url == result.url }
                }
                allResults.append(contentsOf: newResults)
                searchMetadata[word] = newResults.count
            }
        }

        // Remove duplicates and sort by relevance
        let uniqueResults = Array(Set(allResults)).sorted { result1, result2 in
            // Prioritize exact title matches
            if result1.title.localizedCaseInsensitiveContains(query) && !result2.title.localizedCaseInsensitiveContains(query) {
                return true
            } else if !result1.title.localizedCaseInsensitiveContains(query) && result2.title.localizedCaseInsensitiveContains(query) {
                return false
            } else {
                return result1.title.localizedCaseInsensitiveCompare(result2.title) == .orderedAscending
            }
        }

        return DocumentationSearchResponse(
            query: query,
            results: uniqueResults,
            metadata: searchMetadata,
            totalFound: uniqueResults.count
        )
    }
}

// MARK: - Content Type Classification and Metadata Extraction

public enum ContentType {
    case article
    case sampleCode
    case symbol
    case tutorial
    case generic
}

/// User intent for content discovery - agent-friendly terminology
public enum SearchIntent {
    case example      // "Show me working code"
    case explain       // "Help me understand this"
    case reference    // "Technical details please"
    case learn         // "Teach me step by step"
    case all           // "Show everything"

    /// Maps intent to preferred content types with weighting
    var preferredContentTypes: [(ContentType, Double)] {
        switch self {
        case .example:
            return [(.sampleCode, 1.0), (.tutorial, 0.7), (.article, 0.3)]
        case .explain:
            return [(.article, 1.0), (.symbol, 0.8), (.tutorial, 0.4)]
        case .reference:
            return [(.symbol, 1.0), (.article, 0.3)]
        case .learn:
            return [(.tutorial, 1.0), (.sampleCode, 0.6), (.article, 0.5)]
        case .all:
            return [(.article, 1.0), (.sampleCode, 1.0), (.symbol, 1.0), (.tutorial, 1.0)]
        }
    }

    /// Creates intent from string input (CLI-friendly)
    public static func from(string: String) -> SearchIntent? {
        switch string.lowercased() {
        case "example", "examples", "code", "sample", "samples", "demo", "demos":
            return .example
        case "explain", "explanation", "understand", "overview", "intro", "introduction":
            return .explain
        case "reference", "api", "technical", "docs", "documentation":
            return .reference
        case "learn", "tutorial", "tutorials", "guide", "guides", "how", "step":
            return .learn
        case "all", "everything", "complete", "full":
            return .all
        default:
            return nil
        }
    }
}

/// Extracted metadata structure for rich content analysis
public struct ExtractedMetadata {
    public let contentType: ContentType
    public let roleHeading: String?
    public let customMetadata: [String: Any]
    public let requirements: [String]
    public let timeEstimate: String?
    public let platforms: [String]
    public let relationships: [String: [String]]
    public let relatedTopics: [String]
    public let breadcrumbs: [String]

    public init(
        contentType: ContentType,
        roleHeading: String? = nil,
        customMetadata: [String: Any] = [:],
        requirements: [String] = [],
        timeEstimate: String? = nil,
        platforms: [String] = [],
        relationships: [String: [String]] = [:],
        relatedTopics: [String] = [],
        breadcrumbs: [String] = []
    ) {
        self.contentType = contentType
        self.roleHeading = roleHeading
        self.customMetadata = customMetadata
        self.requirements = requirements
        self.timeEstimate = timeEstimate
        self.platforms = platforms
        self.relationships = relationships
        self.relatedTopics = relatedTopics
        self.breadcrumbs = breadcrumbs
    }
}

public extension AppleDocumentationClient {

    /// Classifies content type based on kind and metadata.role
    func classifyContentType(_ documentation: AppleDocumentation) -> ContentType {
        // Use BOTH kind and metadata.role for classification (official DoCC approach)
        switch (documentation.kind, documentation.metadata?.role) {
        case (.some("symbol"), _):
            return .symbol
        case (.some("article"), .some("sampleCode")):
            return .sampleCode
        case (.some("article"), _):
            return .article
        case (.some("tutorial"), _):
            return .tutorial
        default:
            return .generic
        }
    }

    /// Extracts custom metadata from documentation
    func extractCustomMetadata(_ metadata: DocumentationMetadata?) -> [String: Any] {
        guard let customMetadata = metadata?.customMetadata else { return [:] }

        var result: [String: Any] = [:]

        if let requirements = customMetadata.requirements {
            result["requirements"] = requirements
        }
        if let estimatedTime = customMetadata.estimatedTime {
            result["estimatedTime"] = estimatedTime
        }
        if let skillLevel = customMetadata.skillLevel {
            result["skillLevel"] = skillLevel
        }
        if let prerequisites = customMetadata.prerequisites {
            result["prerequisites"] = prerequisites
        }
        if let tags = customMetadata.tags {
            result["tags"] = tags
        }

        return result
    }

    /// Extracts relationship information from relationship sections
    func extractRelationships(_ sections: [RelationshipsSection]?) -> [String: [String]] {
        guard let sections = sections, !sections.isEmpty else { return [:] }

        var relationships: [String: [String]] = [:]

        for section in sections {
            if let type = section.type, let identifiers = section.identifiers {
                relationships[type] = identifiers
            }
        }

        return relationships
    }

    /// Extracts related topics from topic sections
    func extractTopics(_ sections: [TopicSection]?) -> [String] {
        guard let sections = sections, !sections.isEmpty else { return [] }

        var topics: [String] = []

        for section in sections {
            topics.append(contentsOf: section.identifiers)
        }

        return topics
    }

    /// Extracts breadcrumb paths from hierarchy
    func extractHierarchy(_ hierarchy: Hierarchy?) -> [String] {
        guard let hierarchy = hierarchy,
              let paths = hierarchy.paths,
              !paths.isEmpty else { return [] }

        // Return the first path (most common breadcrumb path)
        return paths.first ?? []
    }

    /// Extracts platform information from metadata
    func extractPlatforms(_ metadata: DocumentationMetadata?) -> [String] {
        guard let platforms = metadata?.platforms else { return [] }

        return platforms.compactMap { platform in
            if let name = platform.name {
                // Add version info if available
                if let introducedAt = platform.introducedAt {
                    return "\(name) (\(introducedAt)+)"
                }
                return name
            }
            return nil
        }
    }

    /// Main metadata extraction function that combines all extraction methods
    func extractMetadata(_ documentation: AppleDocumentation) -> ExtractedMetadata {
        let contentType = classifyContentType(documentation)
        let customMetadata = extractCustomMetadata(documentation.metadata)
        let relationships = extractRelationships(documentation.relationshipsSections)
        let topics = extractTopics(documentation.topicSections)
        let breadcrumbs = extractHierarchy(documentation.hierarchy)
        let platforms = extractPlatforms(documentation.metadata)

        // Extract specific fields from custom metadata
        var requirements: [String] = []
        var timeEstimate: String?

        if let reqs = customMetadata["requirements"] as? [String] {
            requirements = reqs
        }

        if let time = customMetadata["estimatedTime"] as? String {
            timeEstimate = time
        }

        return ExtractedMetadata(
            contentType: contentType,
            roleHeading: documentation.metadata?.roleHeading,
            customMetadata: customMetadata,
            requirements: requirements,
            timeEstimate: timeEstimate,
            platforms: platforms,
            relationships: relationships,
            relatedTopics: topics,
            breadcrumbs: breadcrumbs
        )
    }
}

// MARK: - Search Filtering and Discovery

/// Filtering options for enhanced documentation search
public struct ContentTypeFilter {
    public var contentType: ContentType?
    public var requiresPlatforms: [String]?  // iOS 14+, macOS 12+, etc.
    public var maxTimeEstimate: Int?         // minutes
    public var minTimeEstimate: Int?         // minutes
    public var intent: SearchIntent?         // User intent (NEW)

    public init(
        contentType: ContentType? = nil,
        requiresPlatforms: [String]? = nil,
        maxTimeEstimate: Int? = nil,
        minTimeEstimate: Int? = nil,
        intent: SearchIntent? = nil
    ) {
        self.contentType = contentType
        self.requiresPlatforms = requiresPlatforms
        self.maxTimeEstimate = maxTimeEstimate
        self.minTimeEstimate = minTimeEstimate
        self.intent = intent
    }
}

/// Enhanced search result with metadata for filtering
public struct EnhancedSearchResult {
    public let originalResult: DocumentationSearchResult
    public let renderNode: AppleDocumentation?
    public let extractedMetadata: ExtractedMetadata?
    public let relevance: Double

    public init(
        originalResult: DocumentationSearchResult,
        renderNode: AppleDocumentation? = nil,
        extractedMetadata: ExtractedMetadata? = nil,
        relevance: Double = 0.0
    ) {
        self.originalResult = originalResult
        self.renderNode = renderNode
        self.extractedMetadata = extractedMetadata
        self.relevance = relevance
    }
}

public extension AppleDocumentationClient {

      /// Detects user intent from query patterns (automatic inference)
    private func detectIntent(from query: String) -> SearchIntent {
        let queryLower = query.lowercased()

        // Explicit intent patterns
        if queryLower.contains("example") || queryLower.contains("sample") ||
           queryLower.contains("demo") || queryLower.contains("code") ||
           queryLower.contains("how to") || queryLower.contains("implement") {
            return .example
        }

        if queryLower.contains("explain") || queryLower.contains("understand") ||
           queryLower.contains("overview") || queryLower.contains("intro") ||
           queryLower.contains("what is") || queryLower.contains("how does") {
            return .explain
        }

        if queryLower.contains("api") || queryLower.contains("method") ||
           queryLower.contains("function") || queryLower.contains("class") ||
           queryLower.contains("protocol") || queryLower.contains("reference") {
            return .reference
        }

        if queryLower.contains("learn") || queryLower.contains("tutorial") ||
           queryLower.contains("guide") || queryLower.contains("step by step") ||
           queryLower.contains("getting started") || queryLower.contains("beginner") {
            return .learn
        }

        // Default to "all" for general queries
        return .all
    }

    /// Enhanced comprehensive search with intent-based filtering and comprehensive fallback
    func comprehensiveSearch(
        query: String,
        limit: Int? = nil,
        filter: ContentTypeFilter? = nil
    ) async throws -> [DocumentationSearchResult] {
        // Create filter with automatic intent detection if none provided
        var searchFilter = filter ?? ContentTypeFilter()
        if searchFilter.intent == nil {
            searchFilter.intent = detectIntent(from: query)
        }

        // Perform existing search logic first (limited Apple index)
        var results = try await searchDocumentation(query: query)

        // If limited search has few results, try comprehensive fallback
        if results.count < 3 {
            let fallbackResults = try await comprehensiveFallbackSearch(query: query, existingResults: results)
            results.append(contentsOf: fallbackResults)
        }

        // Apply intent-based filtering and ranking
        results = try await applyFilter(results, filter: searchFilter, query: query)

        // Apply limit if specified
        if let limit = limit, results.count > limit {
            results = Array(results.prefix(limit))
        }

        return results
    }

    /// Comprehensive fallback search that covers ALL Apple frameworks
    private func comprehensiveFallbackSearch(
        query: String,
        existingResults: [DocumentationSearchResult]
    ) async throws -> [DocumentationSearchResult] {
        var fallbackResults: [DocumentationSearchResult] = []

        // 1. Try direct framework name matches
        let frameworkResults = try await directFrameworkSearch(query: query)
        fallbackResults.append(contentsOf: frameworkResults)

        // 2. Try camelCase variations and common typos
        let variations = generateFrameworkVariations(query: query)
        for variation in variations {
            if !frameworkResults.contains(where: { $0.title.contains(variation) }) {
                let variationResults = try await directFrameworkSearch(query: variation)
                fallbackResults.append(contentsOf: variationResults)
            }
        }

        // 3. Try broader documentation search if we still have few results
        if fallbackResults.count < 3 {
            let broadResults = try await broadDocumentationSearch(query: query)
            fallbackResults.append(contentsOf: broadResults)
        }

        // Deduplicate while preserving order and relevance
        return deduplicateSearchResults(fallbackResults, existingResults: existingResults)
    }

    /// Direct framework search using known framework names
    private func directFrameworkSearch(query: String) async throws -> [DocumentationSearchResult] {
        var results: [DocumentationSearchResult] = []

        let knownFrameworks = [
            "swiftui", "uikit", "appkit", "foundation", "coredata", "metal", "arkit", "visionos",
            "widgetkit", "eventkit", "coreml", "avfoundation", "mapkit", "combine", "swiftdata",
            "groupactivities", "shareplay", "realitykit", "visionkit", "passkit", "watchkit", "homekit",
            "healthkit", "coremotion", "corelocation", "corebluetooth", "network", "multipeerconnectivity",
            "eventkitui", "photosui", "phonenumbers", "contactsui", "calendarui", "messageui",
            "carplay", "externalaccessory", "fileproviderextensionui", "pdfkit", "screentimeapi",
            "sf_symbols", "avfaudioplayers", "musicplayer", "mediasession"
        ]

        // Try to fetch each framework's index and search for matches
        for framework in knownFrameworks {
            do {
                let frameworkResults = try await fetchFrameworkIndex(framework: framework)

                let matchingItems = frameworkResults.filter { item in
                    // Smart matching with the query
                    item.name.localizedCaseInsensitiveContains(query) ||
                    item.url.localizedCaseInsensitiveContains(query)
                }

                for item in matchingItems {
                    let result = DocumentationSearchResult(
                        title: item.name,
                        url: item.url,
                        type: item.kind,
                        description: item.abstract?.compactMap { $0.text }.joined(separator: " "),
                        identifier: extractIdentifier(from: item.url)
                    )

                    results.append(result)
                }
            } catch {
                // Continue with other frameworks if one fails
                continue
            }
        }

        return results
    }

    /// Broader documentation search across Apple's documentation site
    private func broadDocumentationSearch(query: String) async throws -> [DocumentationSearchResult] {
        var results: [DocumentationSearchResult] = []

        // Try to construct likely documentation paths based on query
        let potentialPaths = generateDocumentationPaths(query: query)

        for path in potentialPaths {
            do {
                let documentation = try await fetchDocumentation(path: path)

                // Check if this documentation actually matches our query
                if documentationMatchesQuery(documentation, query: query) {
                    let result = DocumentationSearchResult(
                        title: documentation.metadata?.title ?? path,
                        url: "https://developer.apple.com/documentation/\(path)",
                        type: documentation.kind ?? "documentation",
                        description: documentation.abstract?.compactMap { $0.text }.joined(separator: " "),
                        identifier: extractIdentifier(from: documentation.identifier?.url ?? "")
                    )
                    results.append(result)
                }
            } catch {
                // Continue with other paths if one fails
                continue
            }
        }

        return results
    }

    /// Check if documentation content matches the search query
    private func documentationMatchesQuery(_ documentation: AppleDocumentation, query: String) -> Bool {
        let queryLower = query.lowercased()

        // Check title
        if let title = documentation.metadata?.title {
            if title.lowercased().contains(queryLower) {
                return true
            }
        }

        // Check abstract
        if let abstract = documentation.abstract {
            let abstractText = abstract.compactMap { $0.text }.joined(separator: " ").lowercased()
            if abstractText.contains(queryLower) {
                return true
            }
        }

        // Check primary content sections
        if let sections = documentation.primaryContentSections {
            for section in sections {
                if let title = section.title {
                    if title.lowercased().contains(queryLower) {
                        return true
                    }
                }
                if let content = section.content {
                    let contentText = content.compactMap { $0.text }.joined(separator: " ").lowercased()
                    if contentText.contains(queryLower) {
                        return true
                    }
                }
            }
        }

        return false
    }

    /// Generate potential documentation paths from query
    private func generateDocumentationPaths(query: String) -> [String] {
        var paths: [String] = []

        let queryLower = query.lowercased()

        // Direct path attempts (most likely)
        paths.append(queryLower)  // "groupactivities" → "groupactivities"

        // Common patterns
        paths.append("\(queryLower.lowercased())")  // "GroupActivities" → "groupactivities"
        paths.append("\(queryLower.lowercased())")  // "SharePlay" → "shareplay"

        // Framework-specific patterns
        if queryLower.contains("share") {
            paths.append("shareplay")
            paths.append("groupactivities")
        }

        if queryLower.contains("vision") {
            paths.append("visionos")
        }

        if queryLower.contains("activity") {
            paths.append("groupactivities")
        }

        // Remove duplicates and return
        return Array(Set(paths))
    }

    /// Generate common variations and typos for framework names
    private func generateFrameworkVariations(query: String) -> [String] {
        var variations: [String] = []

        let queryLower = query.lowercased()

        // Common plural/singular variations
        if queryLower.hasSuffix("ies") {
            variations.append(String(queryLower.dropLast(3))) // "activities" → "activity"
        } else if !queryLower.hasSuffix("s") {
            variations.append(queryLower + "s") // "activity" → "activities"
        }

        // Common misspellings
        let commonMisspellings: [String: [String]] = [
            "groupactivities": ["groupactivity", "group_activity"],
            "shareplay": ["share-play"],
            "realitykit": ["reality_kit"],
            "visionos": ["vision_os"],
            "swiftui": ["swift_ui"],
            "uikit": ["ui_kit"],
            "appkit": ["app_kit"],
            "coredata": ["core_data"],
            "coreml": ["core_ml"]
        ]

        if let misspellings = commonMisspellings[queryLower] {
            variations.append(contentsOf: misspellings)
        }

        return Array(Set(variations))
    }

    /// Remove duplicates from search results while preserving order
    private func deduplicateSearchResults(_ newResults: [DocumentationSearchResult], existingResults: [DocumentationSearchResult]) -> [DocumentationSearchResult] {
        var seen = Set<String>()

        // Add existing results to seen set
        for result in existingResults {
            seen.insert(result.url)
        }

        // Add only new results not already seen
        var deduplicated: [DocumentationSearchResult] = []
        for result in newResults {
            if seen.insert(result.url).inserted {
                deduplicated.append(result)
            }
        }

        return deduplicated
    }

    /// Applies filters to search results
    private func applyFilter(
        _ results: [DocumentationSearchResult],
        filter: ContentTypeFilter,
        query: String
    ) async throws -> [DocumentationSearchResult] {
        var enhancedResults: [EnhancedSearchResult] = []

        for result in results {
            var relevance = calculateBaseRelevance(result, query: query)
            var renderNode: AppleDocumentation?
            var extractedMetadata: ExtractedMetadata?

            // Try to fetch full documentation for better filtering
            if result.url.contains("/documentation/") {
                do {
                    // Extract path from URL for fetching
                    let path = extractDocumentationPath(from: result.url)
                    renderNode = try await fetchDocumentation(path: path)
                    extractedMetadata = extractMetadata(renderNode!)

                    // Boost relevance based on content type
                    relevance += calculateContentTypeBoost(contentType: extractedMetadata?.contentType, query: query)

                } catch {
                    // Fallback to basic filtering if we can't fetch full documentation
                    extractedMetadata = nil
                    renderNode = nil
                }
            }

            // Apply intent-based relevance boosting
            if let intent = filter.intent, let contentType = extractedMetadata?.contentType {
                relevance += calculateIntentRelevance(contentType: contentType, intent: intent)
            }

            // Apply filters
            if passesFilter(result, metadata: extractedMetadata, filter: filter) {
                let enhancedResult = EnhancedSearchResult(
                    originalResult: result,
                    renderNode: renderNode,
                    extractedMetadata: extractedMetadata,
                    relevance: relevance
                )
                enhancedResults.append(enhancedResult)
            }
        }

        // Sort by relevance (highest first)
        enhancedResults.sort { $0.relevance > $1.relevance }

        return enhancedResults.map { $0.originalResult }
    }

    /// Calculates base relevance score for search results
    private func calculateBaseRelevance(_ result: DocumentationSearchResult, query: String) -> Double {
        let queryLower = query.lowercased()
        let titleLower = result.title.lowercased()
        let descriptionLower = (result.description ?? "").lowercased()

        var score: Double = 0

        // Exact title match gets highest score
        if titleLower == queryLower {
            score += 1000
        }
        // Title contains query
        else if titleLower.contains(queryLower) {
            score += 500
        }

        // Description contains query
        if descriptionLower.contains(queryLower) {
            score += 100
        }

        // URL contains query (likely good match)
        if result.url.lowercased().contains(queryLower) {
            score += 50
        }

        return score
    }

    /// Calculates relevance boost based on intent and content type match
    private func calculateIntentRelevance(contentType: ContentType, intent: SearchIntent) -> Double {
        for (preferredType, weight) in intent.preferredContentTypes {
            if contentType == preferredType {
                return weight * 100 // Significant boost for matching intent
            }
        }
        return 0 // No boost for non-matching content types
    }

    /// Calculates relevance boost based on content type and query
    private func calculateContentTypeBoost(contentType: ContentType?, query: String) -> Double {
        guard let contentType = contentType else { return 0 }

        let queryLower = query.lowercased()

        switch contentType {
        case .sampleCode:
            // Boost sample code for queries suggesting examples
            if queryLower.contains("example") || queryLower.contains("sample") || queryLower.contains("code") {
                return 200
            }
            return 0

        case .article:
            // Boost articles for queries suggesting guides/tutorials
            if queryLower.contains("guide") || queryLower.contains("how") || queryLower.contains("learn") {
                return 150
            }
            return 0

        case .tutorial:
            // Boost tutorials for learning-related queries
            if queryLower.contains("tutorial") || queryLower.contains("step") || queryLower.contains("build") {
                return 250
            }
            return 0

        case .symbol:
            // Boost symbols for API/implementation queries
            if queryLower.contains("api") || queryLower.contains("function") || queryLower.contains("method") {
                return 100
            }
            return 0

        case .generic:
            return 0
        }
    }

    /// Checks if a result passes the specified filters
    private func passesFilter(
        _ result: DocumentationSearchResult,
        metadata: ExtractedMetadata?,
        filter: ContentTypeFilter
    ) -> Bool {
        // Content type filtering
        if let contentTypeFilter = filter.contentType,
           let metadata = metadata {
            if metadata.contentType != contentTypeFilter {
                return false
            }
        }

        // Platform filtering
        if let requiredPlatforms = filter.requiresPlatforms,
           let metadata = metadata {
            let platforms = metadata.platforms.map { $0.lowercased() }

            for requirement in requiredPlatforms {
                let requirementLower = requirement.lowercased()
                if !platforms.contains(where: { platform in
                    platform.contains(requirementLower) || requirementLower.contains(platform)
                }) {
                    return false
                }
            }
        }

        // Time estimate filtering
        if let metadata = metadata {
            if let maxTime = filter.maxTimeEstimate,
               let timeStr = metadata.timeEstimate {
                let timeMinutes = parseTimeEstimate(timeStr)
                if timeMinutes > maxTime {
                    return false
                }
            }

            if let minTime = filter.minTimeEstimate,
               let timeStr = metadata.timeEstimate {
                let timeMinutes = parseTimeEstimate(timeStr)
                if timeMinutes < minTime {
                    return false
                }
            }
        }

        return true
    }

    /// Parses time estimate string to minutes
    private func parseTimeEstimate(_ timeStr: String) -> Int {
        let lowerStr = timeStr.lowercased()

        // Look for hours
        if let hourRange = lowerStr.range(of: #"(\d+)\s*hour"#, options: .regularExpression) {
            let hoursStr = String(lowerStr[hourRange].dropLast(5)).trimmingCharacters(in: .whitespaces)
            if let hours = Int(hoursStr) {
                var totalMinutes = hours * 60
                // Look for additional minutes
                if let minuteRange = lowerStr.range(of: #"(\d+)\s*minute"#, options: .regularExpression) {
                    let minutesStr = String(lowerStr[minuteRange].dropLast(7)).trimmingCharacters(in: .whitespaces)
                    if let minutes = Int(minutesStr) {
                        totalMinutes += minutes
                    }
                }
                return totalMinutes
            }
        }

        // Look for minutes only
        if let minuteRange = lowerStr.range(of: #"(\d+)\s*minute"#, options: .regularExpression) {
            let minutesStr = String(lowerStr[minuteRange].dropLast(7)).trimmingCharacters(in: .whitespaces)
            return Int(minutesStr) ?? 0
        }

        // Default fallback
        return 30 // Assume 30 minutes if parsing fails
    }

    /// Extracts documentation path from URL
    private func extractDocumentationPath(from url: String) -> String {
        // Convert full Apple developer URL to documentation path
        // Example: https://developer.apple.com/documentation/swiftui/button -> swiftui/button
        if let range = url.range(of: "/documentation/") {
            return String(url[range.upperBound...])
        }
        return url
    }
}

/// Response wrapper for comprehensive search results
public struct DocumentationSearchResponse: Codable {
    public let query: String
    public let results: [DocumentationSearchResult]
    public let metadata: [String: Int]
    public let totalFound: Int

    public init(query: String, results: [DocumentationSearchResult], metadata: [String: Int], totalFound: Int) {
        self.query = query
        self.results = results
        self.metadata = metadata
        self.totalFound = totalFound
    }
}
