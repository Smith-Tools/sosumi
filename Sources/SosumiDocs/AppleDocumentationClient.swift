import Foundation

/// URLSession-based client for accessing Apple Developer JSON documentation APIs
/// Based on sosumi.ai implementation for accessing undocumented Apple endpoints
public class AppleDocumentationClient {

    // MARK: - Properties

    private let session: URLSession
    private let baseURL = "https://developer.apple.com/tutorials/data"
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
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: configuration)
        self.userAgentPool = Self.safariUserAgents
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
        let normalizedPath = normalizeDocumentationPath(path)
        let url = "\(baseURL)/\(normalizedPath).json"
        return try await performRequest(url: url)
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
            "uikit", "appkit", "coredata", "metal", "arkit", "visionos"
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
            "widgetkit", "eventkit", "coreml", "avfoundation", "mapkit"
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
