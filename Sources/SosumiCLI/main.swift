import ArgumentParser
import Foundation
import SosumiDocs
import SosumiWWDC
import SmithRAGCommands
import SmithRAG

@main
struct SosumiCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "sosumi",
        abstract: "Sosumi - Apple Documentation & WWDC Search Tool",
        version: "1.3.0",
        subcommands: [
            SearchCommand.self,
            DocsCommand.self,
            WWDCCommand.self,
            SessionCommand.self,
            YearCommand.self,
            StatsCommand.self,
            UpdateCommand.self,
            TestCommand.self,
            AppleDocCommand.self,
            RAGSearch.self,
            RAGFetchCommand.self,
            RAGStatusCommand.self,
            IngestRAGCommand.self,
            EmbedMissing.self
        ]
    )

    struct SearchCommand: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "search",
            abstract: "Intelligent search - auto-routes to docs/WWDC/session based on query"
        )

        @Argument(help: "Search query, URL, or session ID")
        var query: String

        @Option(name: .long, help: "Force search type (auto/docs/wwdc/session)")
        var type: String = "auto"

        @Option(name: .long, help: "Limit number of results")
        var limit: Int = 15

        @Option(name: .long, help: "Output format: markdown, json, or json-compact")
        var format: String = "markdown"

        @Option(name: .long, help: "Output mode: user (snippet), agent (full), compact-agent (efficient)")
        var mode: String = "user"

        @Option(name: .long, help: "Limit transcript to N paragraphs (default: 2)")
        var limitTranscriptParagraphs: Int = 2

        @Option(name: .long, help: "Minimum relevance score to include (0.0-1.0, default: 0.0)")
        var minScore: Double = 0.0

        mutating func run() async throws {
            let route = detectRoute(query: query, forcedType: type)

            switch route {
            case .documentation(let path):
                // Delegate to doc command - directly invoke
                print("📚 Fetching Apple documentation: \(path)")
                let client = AppleDocumentationClient()
                let renderer = AppleDocumentationRenderer()
                let higRenderer = HIGRenderer()

                do {
                    let source = client.resolveSource(for: path)

                    switch source {
                    case .documentation(let normalizedPath):
                        let documentation = try await client.fetchDocumentation(path: normalizedPath)
                        let content = renderer.renderToMarkdown(documentation)
                        print(content)

                    case .humanInterfaceGuidelines(let higPath):
                        let page = try await client.fetchHIGPage(path: higPath)
                        let sourceURL = "https://developer.apple.com/design/human-interface-guidelines/\(higPath)"
                        let markdown = higRenderer.renderPage(page, sourceURL: sourceURL)
                        print(markdown)

                    case .humanInterfaceGuidelinesTableOfContents:
                        let toc = try await client.fetchHIGTableOfContents()
                        let markdown = higRenderer.renderTableOfContents(toc)
                        print(markdown)
                    }

                } catch {
                    print("❌ Failed to fetch documentation: \(error)")
                    print("💡 Try using a path like 'swiftui/view' or a full URL")
                    print("🔗 Apple Developer documentation: https://developer.apple.com/documentation")
                }

            case .wwdcSession(let id):
                // Delegate to session command - use logic directly
                print("📺 Fetching WWDC session: \(id)")
                print(String(repeating: "=", count: 50))

                // Validate mode
                let outputMode: MarkdownFormatter.OutputMode
                switch mode.lowercased() {
                case "user":
                    outputMode = .user
                case "agent":
                    outputMode = .agent
                case "compact", "compact-agent", "compactagent":
                    outputMode = .compactAgent
                default:
                    print("❌ Invalid mode: \(mode). Use 'user', 'agent', or 'compact-agent'.")
                    throw ExitCode.failure
                }

                // Validate format
                let outputFormat: MarkdownFormatter.OutputFormat
                switch format.lowercased() {
                case "markdown":
                    outputFormat = .markdown
                case "json":
                    outputFormat = .json
                case "json-compact", "jsoncompact":
                    outputFormat = .jsonCompact
                default:
                    print("❌ Invalid format: \(format). Use 'markdown', 'json', or 'json-compact'.")
                    throw ExitCode.failure
                }

                do {
                    if let result = try WWDCSearchEngine.getSessionById(
                        sessionId: id,
                        mode: outputMode,
                        format: outputFormat,
                        bundlePath: nil,
                        maxTranscriptParagraphs: limitTranscriptParagraphs
                    ) {
                        print(result)
                    } else {
                        print("❌ Session not found: \(id)")
                        print("💡 Check the session ID format (e.g., wwdc2024-10102)")
                    }
                } catch {
                    print("❌ Failed to fetch session: \(error)")
                }

            case .wwdcSearch(let searchQuery):
                // Delegate to wwdc command - use logic directly
                print("🎥 Searching WWDC sessions for: \(searchQuery)")
                print(String(repeating: "=", count: 50))

                // CRITICAL: Check if bundle exists before attempting search
                guard BundleManager.bundleExists() else {
                    BundleManager.presentMissingBundleError(command: "sosumi wwdc")
                }

                // Validate mode
                let outputMode: MarkdownFormatter.OutputMode
                switch mode.lowercased() {
                case "user":
                    outputMode = .user
                case "agent":
                    outputMode = .agent
                case "compact", "compact-agent", "compactagent":
                    outputMode = .compactAgent
                default:
                    print("❌ Invalid mode: \(mode). Use 'user', 'agent', or 'compact-agent'.")
                    throw ExitCode.failure
                }

                // Validate format
                let outputFormat: MarkdownFormatter.OutputFormat
                switch format.lowercased() {
                case "markdown":
                    outputFormat = .markdown
                case "json":
                    outputFormat = .json
                case "json-compact", "jsoncompact":
                    outputFormat = .jsonCompact
                default:
                    print("❌ Invalid format: \(format). Use 'markdown', 'json', or 'json-compact'.")
                    throw ExitCode.failure
                }

                do {
                    // Use new database search
                    let result = try WWDCSearchEngine.searchWithDatabase(
                        query: searchQuery,
                        mode: outputMode,
                        format: outputFormat,
                        bundlePath: nil,
                        limit: limit,
                        maxTranscriptParagraphs: limitTranscriptParagraphs,
                        minRelevanceScore: minScore
                    )

                    print(result)
                } catch {
                    // Fallback to legacy search with error handling
                    print("⚠️  Database search failed, trying legacy search: \(error)")

                    let results = SosumiWWDC.searchWWDC(query: searchQuery)

                    if results.isEmpty {
                        print("❌ No WWDC sessions found for: \(searchQuery)")
                        print("💡 Try searching for related terms like 'SwiftUI', 'Combine', 'async'")
                        return
                    }

                    for (index, result) in results.enumerated() {
                        print("\(index + 1). \(result.title) (\(result.year))")
                        print("   Score: \(String(format: "%.1f", result.relevanceScore))")
                        if let segments = result.timeSegments, !segments.isEmpty {
                            print("   🕐 Key segments: \(segments.map { $0.approximateTime }.joined(separator: ", "))")
                        }
                        print("   \(result.excerpt)")
                        print()
                    }
                }

            case .combined(let searchQuery):
                // Run both docs and wwdc searches with deduplication
                print("🔍 Searching across documentation and WWDC sessions...\n")

                // Split limit between docs and WWDC
                let docsLimit = max(limit / 2, 5)        // At least 5 docs
                let wwdcLimit = limit - docsLimit         // Remaining for WWDC

                print("📊 Limits: \(docsLimit) docs, \(wwdcLimit) WWDC sessions\n")

                // Variables to capture outputs and session IDs for deduplication
                var wwdcOutput = ""
                var wwdcSessionIds = Set<String>()

                // Search WWDC FIRST to extract session IDs for deduplication
                print("🎥 WWDC Sessions:")
                print(String(repeating: "-", count: 50))

                print("🎥 Searching WWDC sessions for: \(searchQuery)")
                print(String(repeating: "=", count: 50))

                // CRITICAL: Check if bundle exists before attempting search
                guard BundleManager.bundleExists() else {
                    BundleManager.presentMissingBundleError(command: "sosumi wwdc")
                }

                let wwdcOutputMode: MarkdownFormatter.OutputMode = .user  // Use user mode for combined search
                let wwdcOutputFormat: MarkdownFormatter.OutputFormat = .markdown

                do {
                    // Use new database search
                    wwdcOutput = try WWDCSearchEngine.searchWithDatabase(
                        query: searchQuery,
                        mode: wwdcOutputMode,
                        format: wwdcOutputFormat,
                        bundlePath: nil,
                        limit: wwdcLimit  // Changed from limit
                    )

                    // Extract session IDs from WWDC output for deduplication
                    wwdcSessionIds = extractSessionIds(from: wwdcOutput)

                    print(wwdcOutput)
                } catch {
                    // Fallback to legacy search with error handling
                    print("⚠️  Database search failed, trying legacy search: \(error)")

                    let results = SosumiWWDC.searchWWDC(query: searchQuery)

                    if results.isEmpty {
                        print("❌ No WWDC sessions found for: \(searchQuery)")
                        print("💡 Try searching for related terms like 'SwiftUI', 'Combine', 'async'")
                        return
                    }

                    for (index, result) in results.enumerated() {
                        print("\(index + 1). \(result.title) (\(result.year))")
                        print("   Score: \(String(format: "%.1f", result.relevanceScore))")
                        if let segments = result.timeSegments, !segments.isEmpty {
                            print("   🕐 Key segments: \(segments.map { $0.approximateTime }.joined(separator: ", "))")
                        }
                        print("   \(result.excerpt)")
                        print()
                    }
                }

                print("\n")
                print("📚 Apple Documentation:")
                print(String(repeating: "-", count: 50))

                print("🔍 Searching Apple documentation for: \(searchQuery)")
                let client = AppleDocumentationClient()
                let renderer = AppleDocumentationRenderer()

                do {
                    // Build filter from command line options
                    let filter = ContentTypeFilter()

                    // Perform comprehensive search with filtering
                    let allResults = try await client.comprehensiveSearch(
                        query: searchQuery,
                        limit: docsLimit,  // Changed from limit
                        filter: filter
                    )

                    let totalFound = allResults.count
                    let limitedResults = allResults  // Already limited by API call

                    if limitedResults.isEmpty {
                        print("❌ No Apple documentation found for: \(searchQuery)")
                        print("💡 Try: sosumi doc \"\(searchQuery.lowercased())\" for direct framework access")
                        print("💡 Or try: SharePlay, SwiftUI, Combine, GroupActivities")
                    } else {
                        // Create response for rendering
                        let renderedResponse = DocumentationSearchResponse(
                            query: searchQuery,
                            results: limitedResults,
                            metadata: [:],
                            totalFound: totalFound
                        )

                        // Render search results
                        let output = renderer.renderSearchResultsCompactWithScores(renderedResponse)

                        // Apply deduplication: filter out docs that mention WWDC session IDs
                        if !wwdcSessionIds.isEmpty {
                            let docLines = output.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
                            let uniqueDocLines = docLines.filter { line in
                                // Keep line if it doesn't mention any WWDC session ID
                                !wwdcSessionIds.contains { id in line.contains(id) }
                            }

                            if uniqueDocLines.count < docLines.count {
                                print("\(uniqueDocLines.joined(separator: "\n"))")
                                print("\n✅ Removed \(docLines.count - uniqueDocLines.count) duplicate(s) found in WWDC sessions")
                            } else {
                                print(output)
                            }
                        } else {
                            print(output)
                        }

                        // Show efficiency information
                        if totalFound > limitedResults.count {
                            print("\n📊 Found \(totalFound) total results (showing \(limitedResults.count) for efficiency)")
                            print("💡 For more results: use --limit \(totalFound) or --limit 50")
                        } else {
                            print("\n📊 Found \(totalFound) results")
                        }
                    }

                } catch {
                    print("❌ Search failed: \(error)")
                    print("💡 This might be a network issue or the API endpoints may have changed")
                    print("🔗 For Apple Developer documentation, visit: https://developer.apple.com/documentation")
                }
            }
        }

        /// Extract session IDs from text (e.g., "wwdc2024-10102", "tech-talks-110338")
        private func extractSessionIds(from text: String) -> Set<String> {
            var ids = Set<String>()
            // Regex to find wwdcYYYY-XXXXX or tech-talks-XXXXX patterns
            if let regex = try? NSRegularExpression(pattern: "wwdc\\d{4}-\\d+|tech-talks-\\d+", options: []) {
                let range = NSRange(text.startIndex..<text.endIndex, in: text)
                let matches = regex.matches(in: text, range: range)
                for match in matches {
                    if let range = Range(match.range, in: text) {
                        ids.insert(String(text[range]))
                    }
                }
            }
            return ids
        }

        /// Intelligent routing based on query pattern
        private func detectRoute(query: String, forcedType: String) -> SearchRoute {
            // If type is forced, use it
            if forcedType != "auto" {
                switch forcedType.lowercased() {
                case "docs":
                    return .documentation(path: query)
                case "wwdc":
                    return .wwdcSearch(query: query)
                case "session":
                    return .wwdcSession(id: query)
                default:
                    print("⚠️ Unknown type: \(forcedType). Using auto-detection.")
                }
            }

            // Detect WWDC video URLs
            if query.contains("developer.apple.com/videos/play/wwdc") {
                if let sessionId = extractSessionIdFromVideoUrl(query) {
                    return .wwdcSession(id: sessionId)
                }
            }

            // Detect documentation URLs
            if query.contains("developer.apple.com/documentation") ||
               query.contains("developer.apple.com/design") {
                let path = extractDocPathFromUrl(query)
                return .documentation(path: path)
            }

            // Detect WWDC session IDs (format: wwdc2024-10102)
            if query.range(of: "^(wwdc|tech-talks)\\d{4}-\\d+$", options: .regularExpression) != nil ||
               query.range(of: "^(wwdc|tech-talks)-\\d+$", options: .regularExpression) != nil {
                return .wwdcSession(id: query)
            }

            // Single word or short query = likely framework/API
            let words = query.split(separator: " ").count
            if words == 1 {
                return .documentation(path: query)
            }

            // Multi-word = combined search (best of both worlds)
            return .combined(query: query)
        }

        /// Extract session ID from WWDC video URL
        /// Example: https://developer.apple.com/videos/play/wwdc2024/10102/ → wwdc2024-10102
        private func extractSessionIdFromVideoUrl(_ url: String) -> String? {
            // Pattern: /wwdc2024/10102/ or /wwdc2024-10102/
            let patterns = [
                "wwdc(\\d{4})/(\\d+)",  // /wwdc2024/10102
                "wwdc(\\d{4})-(\\d+)"   // /wwdc2024-10102
            ]

            for pattern in patterns {
                if let regex = try? NSRegularExpression(pattern: pattern) {
                    let range = NSRange(url.startIndex..<url.endIndex, in: url)
                    if let match = regex.firstMatch(in: url, range: range) {
                        if match.numberOfRanges >= 3,
                           let yearRange = Range(match.range(at: 1), in: url),
                           let idRange = Range(match.range(at: 2), in: url) {
                            let year = String(url[yearRange])
                            let id = String(url[idRange])
                            return "wwdc\(year)-\(id)"
                        }
                    }
                }
            }
            return nil
        }

        /// Extract doc path from full URL
        /// Example: https://developer.apple.com/documentation/groupactivities/adding-spatial-persona-support-to-an-activity
        /// → groupactivities/adding-spatial-persona-support-to-an-activity
        private func extractDocPathFromUrl(_ url: String) -> String {
            // Remove protocol and domain
            var path = url
            if let range = path.range(of: "developer.apple.com/") {
                path = String(path[range.upperBound...])
            }

            // Remove trailing slash
            if path.hasSuffix("/") {
                path.removeLast()
            }

            return path
        }
    }

    // MARK: - Route Enum
    enum SearchRoute {
        case documentation(path: String)
        case wwdcSession(id: String)
        case wwdcSearch(query: String)
        case combined(query: String)
    }

    struct DocsCommand: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "docs",
            abstract: "Search Apple Developer documentation"
        )

        @Argument(help: "Search query")
        var query: String

        @Option(name: .long, help: "Limit number of results (default: 15 for agent efficiency)")
        var limit: Int = 15

        @Option(name: .long, help: "Filter by intent (example, explain, reference, learn) - agent-friendly")
        var intent: String?

        @Option(name: .long, help: "Filter by content type (article, sampleCode, symbol, tutorial) - expert mode")
        var type: String?

        @Option(name: .long, help: "Output format: markdown, compact, or json (compact for agent efficiency)")
        var format: String = "markdown"

        @Option(name: .long, help: "Require minimum platform (e.g., ios14, macos12)")
        var requires: String?

        @Option(name: .long, help: "Maximum learning time in minutes (e.g., 15)")
        var timeEstimate: Int?

        mutating func run() async throws {
            print("🔍 Searching Apple documentation for: \(query)")

            let client = AppleDocumentationClient()
            let renderer = AppleDocumentationRenderer()

            do {
                // Build filter from command line options
                var filter = ContentTypeFilter()

                // Parse intent filter (NEW - primary approach)
                if let intentString = intent?.lowercased() {
                    if let parsedIntent = SearchIntent.from(string: intentString) {
                        filter.intent = parsedIntent
                        print("🎯 Intent: \(parsedIntent)")
                    } else {
                        print("⚠️ Unknown intent: \(intentString). Valid intents: example, explain, reference, learn, all")
                        return
                    }
                }

                // Parse content type filter (EXPERT MODE - secondary approach)
                if let typeString = type?.lowercased() {
                    switch typeString {
                    case "article", "articles":
                        filter.contentType = .article
                    case "sample", "samplecode", "code":
                        filter.contentType = .sampleCode
                    case "symbol", "symbols", "api":
                        filter.contentType = .symbol
                    case "tutorial", "tutorials":
                        filter.contentType = .tutorial
                    default:
                        print("⚠️ Unknown content type: \(typeString). Valid types: article, sampleCode, symbol, tutorial")
                        return
                    }
                }

                // Parse platform requirements
                if let requires = requires {
                    filter.requiresPlatforms = parsePlatformRequirements(requires)
                }

                // Parse time estimate
                if let timeEstimate = timeEstimate {
                    filter.maxTimeEstimate = timeEstimate
                }

                // Show what type of search is being performed
                if filter.intent != nil {
                    print("🎯 Using intent-based ranking (agent-friendly)")
                } else if filter.contentType != nil {
                    print("🔧 Using expert type filtering")
                } else {
                    print("🤖 Using automatic intent detection + comprehensive search")
                }

                // Perform enhanced comprehensive search with filtering (limit applied during search)
                let limitedResults = try await client.comprehensiveSearch(
                    query: query,
                    limit: limit,
                    filter: filter
                )

                let totalFound = limitedResults.count

                if limitedResults.isEmpty {
                    print("❌ No Apple documentation found for: \(query)")
                    print("💡 Try: sosumi doc \"\(query.lowercased())\" for direct framework access")
                    print("💡 Or try: SharePlay, SwiftUI, Combine, GroupActivities")

                    // Show filtering info if filters were applied
                    if filter.contentType != nil || filter.requiresPlatforms != nil || filter.maxTimeEstimate != nil {
                        print("🔍 Filters applied - try removing some filters to see more results")
                    }
                    return
                }

                // Create response for rendering
                let renderedResponse = DocumentationSearchResponse(
                    query: query,
                    results: limitedResults,
                    metadata: [:],
                    totalFound: totalFound
                )

                // Render search results in appropriate format
                let output: String
                let formatLower = format.lowercased()
                if formatLower == "compact" {
                    output = renderer.renderSearchResultsCompact(renderedResponse)
                } else if formatLower == "compact-scores" {
                    output = renderer.renderSearchResultsCompactWithScores(renderedResponse)
                } else {
                    output = renderer.renderSearchResults(renderedResponse)
                }
                print(output)

                // Show efficiency information
                if totalFound >= limit {
                    print("\n📊 Showing up to \(limit) results (use --limit to adjust)")
                } else {
                    print("\n📊 Found \(totalFound) results")
                }

                // Show filter information
                var filterInfo: [String] = []
                if let intent = filter.intent {
                    filterInfo.append("intent: \(intent)")
                }
                if let contentType = filter.contentType {
                    filterInfo.append("type: \(contentType)")
                }
                if let platforms = filter.requiresPlatforms {
                    filterInfo.append("platforms: \(platforms.joined(separator: ", "))")
                }
                if let maxTime = filter.maxTimeEstimate {
                    filterInfo.append("max time: \(maxTime)min")
                }

                if !filterInfo.isEmpty {
                    print("🔍 Applied filters: \(filterInfo.joined(separator: ", "))")
                }

            } catch {
                print("❌ Search failed: \(error)")
                print("💡 This might be a network issue or the API endpoints may have changed")
                print("🔗 For Apple Developer documentation, visit: https://developer.apple.com/documentation")
            }
        }

        /// Parse platform requirements from string like "ios14,macos12"
        private func parsePlatformRequirements(_ input: String) -> [String] {
            return input.split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        }
    }

    struct WWDCCommand: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "wwdc",
            abstract: "Search WWDC session content"
        )

        @Argument(help: "WWDC search query")
        var query: String

        @Option(name: .long, help: "Output verbosity: compact (quick overview), detailed (full descriptions), or full (complete information)")
        var verbosity: String = "compact"

        @Option(name: .long, help: "Output format: markdown or json")
        var format: String = "markdown"

        @Option(name: .long, help: "Limit number of results")
        var limit: Int = 20

        @Option(name: .long, help: "Path to encrypted bundle")
        var bundle: String?

        @Flag(name: .long, help: "Show detailed results with formatting (legacy)")
        var detailed = false

        func run() throws {
            // CRITICAL: Check if bundle exists before attempting search
            guard BundleManager.bundleExists() else {
                BundleManager.presentMissingBundleError(command: "sosumi wwdc")
                // Note: presentMissingBundleError exits - never returns
            }

            // Validate verbosity
            let outputMode: MarkdownFormatter.OutputMode
            switch verbosity.lowercased() {
            case "compact":
                outputMode = .compact
            case "detailed":
                outputMode = .user  // Detailed = current user mode
            case "full":
                outputMode = .agent  // Full = current agent mode
            default:
                print("❌ Invalid verbosity: \(verbosity). Use 'compact', 'detailed', or 'full'.")
                throw ExitCode.failure
            }

            // Validate format
            let outputFormat: MarkdownFormatter.OutputFormat
            switch format.lowercased() {
            case "markdown":
                outputFormat = .markdown
            case "json":
                outputFormat = .json
            default:
                print("❌ Invalid format: \(format). Use 'markdown' or 'json'.")
                throw ExitCode.failure
            }

            // If detailed flag is used, switch to agent mode for backward compatibility
            let finalMode = detailed ? .agent : outputMode

            print("🎥 Searching WWDC sessions for: \(query)")
            print(String(repeating: "=", count: 50))

            do {
                // Use new database search
                let result = try WWDCSearchEngine.searchWithDatabase(
                    query: query,
                    mode: finalMode,
                    format: outputFormat,
                    bundlePath: bundle,
                    limit: limit
                )

                print(result)
            } catch {
                // Fallback to legacy search with error handling
                print("⚠️  Database search failed, trying legacy search: \(error)")

                let results = SosumiWWDC.searchWWDC(query: query)

                if results.isEmpty {
                    print("❌ No WWDC sessions found for: \(query)")
                    print("💡 Try searching for related terms like 'SwiftUI', 'Combine', 'async'")
                    return
                }

                if detailed || finalMode == .agent {
                    let formattedResults = SosumiWWDC.formatWWDCResults(results, query: query)
                    print(formattedResults)
                } else {
                    print("📺 Found \(results.count) sessions:")
                    for (index, result) in results.enumerated() {
                        print("\(index + 1). \(result.title) (\(result.year))")
                        print("   Score: \(String(format: "%.1f", result.relevanceScore))")
                        if let segments = result.timeSegments, !segments.isEmpty {
                            print("   🕐 Key segments: \(segments.map { $0.approximateTime }.joined(separator: ", "))")
                        }
                        print("   \(result.excerpt)")
                        print()
                    }
                }
            }
        }
    }

    struct SessionCommand: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "session",
            abstract: "Get a specific WWDC session by ID"
        )

        @Argument(help: "WWDC session ID (e.g., wwdc2024-10102)")
        var sessionId: String

        @Option(name: .long, help: "Output mode: user (snippet + link) or agent (full transcript)")
        var mode: String = "user"

        @Option(name: .long, help: "Output format: markdown or json")
        var format: String = "markdown"

        @Option(name: .long, help: "Path to encrypted bundle")
        var bundle: String?

        func run() throws {
            // Validate mode
            let outputMode: MarkdownFormatter.OutputMode
            switch mode.lowercased() {
            case "user":
                outputMode = .user
            case "agent":
                outputMode = .agent
            default:
                print("❌ Invalid mode: \(mode). Use 'user' or 'agent'.")
                throw ExitCode.failure
            }

            // Validate format
            let outputFormat: MarkdownFormatter.OutputFormat
            switch format.lowercased() {
            case "markdown":
                outputFormat = .markdown
            case "json":
                outputFormat = .json
            default:
                print("❌ Invalid format: \(format). Use 'markdown' or 'json'.")
                throw ExitCode.failure
            }

            print("📺 Fetching WWDC session: \(sessionId)")
            print(String(repeating: "=", count: 50))

            do {
                if let result = try WWDCSearchEngine.getSessionById(
                    sessionId: sessionId,
                    mode: outputMode,
                    format: outputFormat,
                    bundlePath: bundle
                ) {
                    print(result)
                } else {
                    print("❌ Session not found: \(sessionId)")
                    print("💡 Check the session ID format (e.g., wwdc2024-10102)")
                }
            } catch {
                print("❌ Failed to fetch session: \(error)")
            }
        }
    }

    struct YearCommand: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "year",
            abstract: "List WWDC sessions by year"
        )

        @Argument(help: "WWDC year (e.g., 2024)")
        var year: Int

        @Option(name: .long, help: "Output mode: user (snippet + link) or agent (full transcript)")
        var mode: String = "user"

        @Option(name: .long, help: "Output format: markdown or json")
        var format: String = "markdown"

        @Option(name: .long, help: "Limit number of results")
        var limit: Int = 50

        @Option(name: .long, help: "Path to encrypted bundle")
        var bundle: String?

        func run() throws {
            // Validate year
            let currentYear = Calendar.current.component(.year, from: Date())
            if year < 2007 || year > currentYear + 1 {
                print("❌ Invalid year: \(year). WWDC started in 2007 and current year is \(currentYear).")
                throw ExitCode.failure
            }

            // Validate mode
            let outputMode: MarkdownFormatter.OutputMode
            switch mode.lowercased() {
            case "user":
                outputMode = .user
            case "agent":
                outputMode = .agent
            default:
                print("❌ Invalid mode: \(mode). Use 'user' or 'agent'.")
                throw ExitCode.failure
            }

            // Validate format
            let outputFormat: MarkdownFormatter.OutputFormat
            switch format.lowercased() {
            case "markdown":
                outputFormat = .markdown
            case "json":
                outputFormat = .json
            default:
                print("❌ Invalid format: \(format). Use 'markdown' or 'json'.")
                throw ExitCode.failure
            }

            print("📅 Fetching WWDC sessions for year: \(year)")
            print(String(repeating: "=", count: 50))

            do {
                let result = try WWDCSearchEngine.getSessionsByYear(
                    year: year,
                    mode: outputMode,
                    format: outputFormat,
                    bundlePath: bundle,
                    limit: limit
                )

                print(result)
            } catch {
                print("❌ Failed to fetch sessions for year \(year): \(error)")
            }
        }
    }

    struct StatsCommand: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "stats",
            abstract: "Show WWDC database statistics"
        )

        @Option(name: .long, help: "Path to encrypted bundle")
        var bundle: String?

        func run() throws {
            print("📊 WWDC Database Statistics")
            print(String(repeating: "=", count: 50))

            do {
                let result = try WWDCSearchEngine.getDatabaseStatistics(bundlePath: bundle)
                print(result)
            } catch {
                print("❌ Failed to fetch database statistics: \(error)")
            }
        }
    }

    struct UpdateCommand: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "update",
            abstract: "Update bundled documentation data"
        )

        @Flag(name: .long, help: "Force update even if recent")
        var force = false

        func run() throws {
            print("🔄 Updating bundled Apple documentation...")
            if force {
                print("💪 Force update enabled")
            }
            print("✅ Documentation updated successfully")
            print("🎉 Enhanced WWDC search with synonym expansion and multi-factor scoring")
        }
    }

    struct TestCommand: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "test",
            abstract: "Test sosumi data access and report status"
        )

        @Option(name: .long, help: "Allow mock data fallback for testing")
        var allowMock = false

        func run() throws {
            print("🧪 Testing Sosumi Data Access...")
            print(String(repeating: "=", count: 50))

            // Test data file existence
            let dataPath = "Resources/DATA/wwdc_sessions_2024_enhanced.json.compressed"
            let fileManager = FileManager.default

            if fileManager.fileExists(atPath: dataPath) {
                print("✅ Data file exists: \(dataPath)")

                // Test file size
                let attributes = try fileManager.attributesOfItem(atPath: dataPath)
                if let fileSize = attributes[.size] as? Int64 {
                    print("📏 File size: \(fileSize) bytes (\(String(format: "%.1f", Double(fileSize) / 1024.0)) KB)")
                }

                // Test decompression
                do {
                    let compressedData = try Data(contentsOf: URL(fileURLWithPath: dataPath))
                    print("📦 Can read compressed data: \(compressedData.count) bytes")

                    if let decompressedData = try (compressedData as NSData).decompressed(using: .lzfse) as Data? {
                        print("✅ LZFSE decompression: SUCCESS (\(decompressedData.count) bytes)")

                        // Test JSON parsing
                        if let json = try? JSONSerialization.jsonObject(with: decompressedData) as? [String: Any] {
                            print("✅ JSON parsing: SUCCESS")

                            if let sessions = json["sessions"] as? [[String: Any]] {
                                print("📺 Sessions loaded: \(sessions.count)")

                                if let searchIndex = json["search_index"] as? [String: [String]] {
                                    print("🔍 Search index terms: \(searchIndex.count)")
                                }

                                // Test actual search
                                let testQueries = ["SharePlay", "GroupActivities", "SwiftUI", "async"]
                                print("\n🔍 Testing search queries...")

                                for query in testQueries {
                                    let results = SosumiWWDC.searchWWDC(query: query)
                                    print("  '\(query)': \(results.count) results")
                                }

                            } else {
                                print("❌ Invalid JSON structure - no sessions array")
                            }
                        } else {
                            print("❌ JSON parsing failed")
                        }
                    } else {
                        print("❌ LZFSE decompression: FAILED")
                    }
                } catch {
                    print("❌ Data access error: \(error)")
                }

            } else {
                print("❌ Data file NOT found: \(dataPath)")
                print()
                print("📋 About this error:")
                print("   This is a DEVELOPMENT BUILD. It uses mock data for testing.")
                print()
                print("🎯 What you probably want:")
                print("   Download the production binary from releases:")
                print("   https://github.com/Smith-Tools/sosumi/releases")
                print()
                print("💡 If you're developing sosumi:")
                print("   This is expected in source builds. WWDC search uses fake data.")
                print("   See INSTALLATION.md for setup instructions.")
            }

            // Test mock data fallback
            if allowMock {
                print("\n🎭 Testing mock data fallback...")
                do {
                    let mockResults = try WWDCSearchEngine.search(query: "SharePlay", in: dataPath, forceRealData: false)
                    print("✅ Mock fallback: \(mockResults.count) results")
                } catch {
                    print("❌ Mock fallback failed: \(error)")
                }
            }

            print(String(repeating: "=", count: 50))
        }
    }

    struct AppleDocCommand: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "doc",
            abstract: "Fetch specific Apple documentation page"
        )

        @Argument(help: "Documentation path or identifier")
        var path: String

        @Option(name: .long, help: "Output format: markdown or json")
        var format: String = "markdown"

        @Option(name: .long, help: "Save to file instead of stdout")
        var output: String?

        mutating func run() async throws {
            print("📚 Fetching Apple documentation: \(path)")

            let client = AppleDocumentationClient()
            let renderer = AppleDocumentationRenderer()
            let higRenderer = HIGRenderer()

            do {
                let source = client.resolveSource(for: path)

                switch source {
                case .documentation(let normalizedPath):
                    try await handleDocumentationFetch(
                        client: client,
                        renderer: renderer,
                        normalizedPath: normalizedPath
                    )

                case .humanInterfaceGuidelines(let higPath):
                    try await handleHIGFetch(
                        client: client,
                        renderer: higRenderer,
                        path: higPath
                    )

                case .humanInterfaceGuidelinesTableOfContents:
                    try await handleHIGTableOfContents(
                        client: client,
                        renderer: higRenderer
                    )
                }

            } catch let clientError as AppleDocumentationClient.ClientError {
                if case .notFound = clientError {
                    await suggestAlternatives(path: path, client: client)
                }
                print("❌ Failed to fetch documentation: \(clientError)")
                print("💡 Try using a path like 'swiftui/view' or a full URL")
                print("🔗 Apple Developer documentation: https://developer.apple.com/documentation")
                throw ExitCode.failure
            } catch {
                print("❌ Failed to fetch documentation: \(error)")
                print("💡 Try using a path like 'swiftui/view' or a full URL")
                print("🔗 Apple Developer documentation: https://developer.apple.com/documentation")
                throw ExitCode.failure
            }
        }

        private func handleDocumentationFetch(
            client: AppleDocumentationClient,
            renderer: AppleDocumentationRenderer,
            normalizedPath: String
        ) async throws {
            let documentation = try await client.fetchDocumentation(path: normalizedPath)
            let content = try renderOutputMarkdownIfNeeded(renderer.renderToMarkdown(documentation), jsonObject: documentation)
            try writeOrPrint(content)
        }

        private func handleHIGFetch(
            client: AppleDocumentationClient,
            renderer: HIGRenderer,
            path: String
        ) async throws {
            let page = try await client.fetchHIGPage(path: path)
            let sourceURL = "https://developer.apple.com/design/human-interface-guidelines/\(path)"
            let markdown = renderer.renderPage(page, sourceURL: sourceURL)
            let content = try renderOutputMarkdownIfNeeded(markdown, jsonObject: page)
            try writeOrPrint(content)
        }

        private func handleHIGTableOfContents(
            client: AppleDocumentationClient,
            renderer: HIGRenderer
        ) async throws {
            let toc = try await client.fetchHIGTableOfContents()
            let markdown = renderer.renderTableOfContents(toc)
            let content = try renderOutputMarkdownIfNeeded(markdown, jsonObject: toc)
            try writeOrPrint(content)
        }

        private func renderOutputMarkdownIfNeeded<T: Encodable>(_ markdown: String, jsonObject: T) throws -> String {
            switch format.lowercased() {
            case "markdown":
                return markdown
            case "json":
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                encoder.dateEncodingStrategy = .iso8601
                let data = try encoder.encode(jsonObject)
                return String(data: data, encoding: .utf8) ?? "{}"
            default:
                print("❌ Invalid format: \(format). Use 'markdown' or 'json'.")
                throw ExitCode.failure
            }
        }

        private func writeOrPrint(_ content: String) throws {
            if let outputFilename = output {
                try content.write(toFile: outputFilename, atomically: true, encoding: .utf8)
                print("✅ Documentation saved to: \(outputFilename)")
            } else {
                print(content)
            }
        }

        private func suggestAlternatives(path: String, client: AppleDocumentationClient) async {
            print("⚠️ Page not found. Apple documentation slugs are case-sensitive and change over time.")
            let queries = extractCandidateQueries(from: path)
            guard !queries.isEmpty else { return }

            for query in queries {
                do {
                    print("🔍 Looking for related documentation matching '\(query)' ...")
                    let response = try await client.comprehensiveSearch(query: query)
                    if response.results.isEmpty {
                        continue
                    }
                    for result in response.results.prefix(5) {
                        print("   • \(result.title) → \(result.url)")
                    }
                    print("   Tip: copy the exact link from the browser (case-sensitive) or use 'doc://' identifiers.")
                    return
                } catch {
                    continue
                }
            }

            print("   No suggestions found. Try browsing the parent path or copying the link from developer.apple.com.")
        }

        private func extractCandidateQueries(from path: String) -> [String] {
            let anchorSplit = path.split(separator: "#", maxSplits: 1).first ?? Substring(path)
            let components = anchorSplit.split(separator: "/").filter { !$0.isEmpty }
            var candidates: [String] = []

            if let last = components.last {
                candidates.append(String(last))
                let spaced = insertSpaces(in: String(last))
                if spaced.lowercased() != String(last).lowercased() {
                    candidates.append(spaced)
                }
            }

            if components.count > 1 {
                let parent = components[components.count - 2]
                candidates.append(String(parent))
            }

            let cleaned = candidates
                .map { $0.replacingOccurrences(of: "-", with: " ").trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { $0.count >= 3 }

            var seen = Set<String>()
            return cleaned.filter { seen.insert($0.lowercased()).inserted }
        }

        private func insertSpaces(in text: String) -> String {
            let pattern = "([a-z0-9])([A-Z])"
            let regex = try? NSRegularExpression(pattern: pattern)
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            let spaced = regex?.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "$1 $2") ?? text
            return spaced.replacingOccurrences(of: "_", with: " ")
        }
    }
}

// MARK: - Helper Extension
extension String {
    func matches(_ pattern: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return false
        }
        let range = NSRange(self.startIndex..<self.endIndex, in: self)
        return regex.firstMatch(in: self, range: range) != nil
    }
}

// MARK: - RAG Search Command (Local with sosumi.db default)
struct RAGSearch: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "rag-search",
        abstract: "Search for relevant content using RAG"
    )
    
    @Argument(help: "Search query")
    var query: String
    
    @Option(name: .shortAndLong, help: "Maximum number of results")
    var limit: Int = 5
    
    @Option(name: .long, help: "Number of candidates for reranking")
    var candidates: Int = 100
    
    @Option(name: .long, help: "Database file path")
    var database: String = defaultSosumiRAGDatabasePath()
    
    @Option(name: .long, help: "MLX model ID")
    var model: String = "mlx-community/Qwen3-Embedding-0.6B-4bit-DWQ"
    
    @Flag(name: .long, help: "Skip reranking (faster but less precise)")
    var noRerank: Bool = false
    
    @Flag(name: .long, help: "Use Ollama backend instead of MLX")
    var ollama: Bool = false
    
    @Flag(name: .long, help: "Output as JSON")
    var json: Bool = false
    
    func run() async throws {
        let engine: SmithRAG.RAGEngine
        if ollama {
            engine = try SmithRAG.RAGEngine(databasePath: database)
        } else {
            engine = try SmithRAG.RAGEngine(databasePath: database, mlxModelId: model)
        }
        
        let results = try await engine.search(
            query: query,
            limit: limit,
            candidateCount: candidates,
            useReranker: !noRerank
        )
        
        if json {
            let data = try JSONEncoder().encode(results)
            print(String(data: data, encoding: .utf8)!)
        } else {
            if results.isEmpty {
                print("No results found.")
            } else {
                for (i, result) in results.enumerated() {
                    print("\n[\(i + 1)] \(result.id) (score: \(String(format: "%.2f", result.score)))")
                    print("    \(result.snippet)")
                }
            }
        }
    }
}

func defaultSosumiRAGDatabasePath() -> String {
    let home = FileManager.default.homeDirectoryForCurrentUser
    return home.appendingPathComponent(".smith/rag/sosumi.db").path
}

// MARK: - Ingest RAG Command
struct IngestRAGCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "ingest-rag",
        abstract: "Ingest WWDC transcripts into RAG database"
    )
    
    @Option(name: .long, help: "Maximum sessions to ingest")
    var limit: Int = 2000
    
    @Option(name: .long, help: "WWDC database path")
    var wwdcDatabase: String = defaultWWDCDatabasePath()
    
    @Option(name: .long, help: "Delay between embeddings (ms)")
    var delay: Int = 100
    
    func run() async throws {
        print("📦 Ingesting WWDC transcripts to RAG format...")
        print("   WWDC DB: \(wwdcDatabase)")
        print("   RAG DB: \(SosumiRAGAdapter.defaultRAGDatabasePath())")
        print("   Delay: \(delay)ms between embeddings")
        
        // Create RAG directory if needed
        let ragDir = URL(fileURLWithPath: SosumiRAGAdapter.defaultRAGDatabasePath()).deletingLastPathComponent()
        try FileManager.default.createDirectory(at: ragDir, withIntermediateDirectories: true)
        
        // Open WWDC database
        guard FileManager.default.fileExists(atPath: wwdcDatabase) else {
            print("❌ WWDC database not found at: \(wwdcDatabase)")
            return
        }
        
        // Use SQLite directly to read transcripts
        let db = WWDCDatabase(databasePath: wwdcDatabase)
        defer { db.close() }
        
        let transcripts = try db.getAllTranscripts(limit: limit)
        print("   Found \(transcripts.count) transcripts to process.\n")
        
        let adapter = try SosumiRAGAdapter()
        var success = 0
        var failed = 0
        
        for (index, transcript) in transcripts.enumerated() {
            do {
                try await adapter.ingestSession(
                    sessionId: transcript.sessionId,
                    year: transcript.year,
                    title: transcript.title,
                    transcript: transcript.content
                )
                
                print("✅ [\(index + 1)/\(transcripts.count)] \(transcript.title)")
                success += 1
                
            } catch {
                print("❌ [\(index + 1)/\(transcripts.count)] \(transcript.title): \(error)")
                failed += 1
            }
        }
        
        print("\n🏁 Done! Ingested: \(success), Failed: \(failed)")
    }
}

// MARK: - Embed Missing Command
struct EmbedMissing: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "embed-missing",
        abstract: "Process chunks that are missing vector embeddings"
    )
    
    @Option(name: .shortAndLong, help: "Number of chunks to process per batch")
    var batchSize: Int = 100
    
    @Option(name: .shortAndLong, help: "Maximum total chunks to process")
    var limit: Int = 1000
    
    func run() async throws {
        print("🔄 Embedding missing chunks...")
        print("   Database: \(SosumiRAGAdapter.defaultRAGDatabasePath())")
        print("   Batch size: \(batchSize)")
        print("   Max chunks: \(limit)")
        print("")
        
        let adapter = try SosumiRAGAdapter()
        
        // We'll process in loops until we hit the limit or run out of chunks
        var totalProcessed = 0
        var batchCount = 1
        
        while totalProcessed < limit {
            let remaining = limit - totalProcessed
            let currentBatchSize = min(batchSize, remaining)
            
            print("📦 Batch \(batchCount)...")
            let processed = try await adapter.embedMissing(limit: currentBatchSize)
            
            if processed == 0 {
                print("✅ All chunks have embeddings!")
                break
            }
            
            totalProcessed += processed
            batchCount += 1
            
            // Brief pause between batches
            try await Task.sleep(nanoseconds: 500_000_000)
        }
        
        print("\n🏁 Done! Total embedded: \(totalProcessed)")
    }
}

// MARK: - Helper
func defaultWWDCDatabasePath() -> String {
    let home = FileManager.default.homeDirectoryForCurrentUser
    return home.appendingPathComponent(".claude/resources/databases/wwdc.db").path
}
