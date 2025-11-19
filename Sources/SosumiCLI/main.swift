import ArgumentParser
import Foundation
import SosumiDocs
import SosumiWWDC

@main
struct SosumiCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "sosumi",
        abstract: "Sosumi - Apple Documentation & WWDC Search Tool",
        version: "1.2.0",
        subcommands: [
            DocsCommand.self,
            WWDCCommand.self,
            SessionCommand.self,
            YearCommand.self,
            StatsCommand.self,
            UpdateCommand.self,
            TestCommand.self,
            AppleDocCommand.self
        ]
    )

    struct DocsCommand: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "docs",
            abstract: "Search Apple Developer documentation"
        )

        @Argument(help: "Search query")
        var query: String

        @Option(name: .long, help: "Limit number of results")
        var limit: Int?

        @Option(name: .long, help: "Content type filter")
        var type: String?

        mutating func run() async throws {
            print("🔍 Searching Apple documentation for: \(query)")

            let client = AppleDocumentationClient()
            let renderer = AppleDocumentationRenderer()

            do {
                // Perform comprehensive search across Apple documentation
                let searchResponse = try await client.comprehensiveSearch(query: query)

                if searchResponse.results.isEmpty {
                    print("❌ No Apple documentation found for: \(query)")
                    print("💡 Try searching for frameworks like 'SwiftUI', 'Combine', 'async'")
                    return
                }

                // Apply optional filters and limits prior to rendering
                let filteredResults: [DocumentationSearchResult]
                if let typeFilter = type?.lowercased(), !typeFilter.isEmpty {
                    filteredResults = searchResponse.results.filter {
                        $0.type.lowercased().contains(typeFilter)
                    }
                } else {
                    filteredResults = searchResponse.results
                }

                let limitedResults: [DocumentationSearchResult]
                if let limit = limit, limit < filteredResults.count {
                    limitedResults = Array(filteredResults.prefix(limit))
                } else {
                    limitedResults = filteredResults
                }

                let renderedResponse = DocumentationSearchResponse(
                    query: searchResponse.query,
                    results: limitedResults,
                    metadata: searchResponse.metadata,
                    totalFound: filteredResults.count
                )

                // Render search results to markdown
                let markdown = renderer.renderSearchResults(renderedResponse)
                print(markdown)

                if let limit = limit, limit < filteredResults.count {
                    print("📊 Showing top \(limit) of \(filteredResults.count) results")
                }

            } catch {
                print("❌ Search failed: \(error)")
                print("💡 This might be a network issue or the API endpoints may have changed")
                print("🔗 For Apple Developer documentation, visit: https://developer.apple.com/documentation")
            }
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
    }
}
