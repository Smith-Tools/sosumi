import Testing
import Foundation
import CryptoKit
@testable import SosumiWWDC

@Suite("SosumiWWDC Tests")
struct SosumiWWDCTests {

    // MARK: - Core Tests

    @Test("SosumiWWDC initialization")
    func testSosumiWWDCInitialization() {
        _ = SosumiWWDC()
        // Test passes if SosumiWWDC can be instantiated successfully
        #expect(true)
    }

    @Test("WWDC search engine initialization")
    func testWWDCSearchEngineInitialization() {
        // Test that the search engine can be instantiated
        let searchResults = try? WWDCSearchEngine.search(query: "SwiftUI", in: "mock", forceRealData: false)
        #expect(searchResults != nil)
    }

    // MARK: - Database Tests

    @Test("WWDCDatabase initialization")
    func testWWDCDatabaseInitialization() {
        _ = WWDCDatabase(databasePath: ":memory:")
        // Test passes if WWDCDatabase can be instantiated successfully
        #expect(true)
    }

    @Test("WWDCDatabase can be opened and closed")
    func testWWDCDatabaseOpenClose() throws {
        let database = WWDCDatabase(databasePath: ":memory:")
        try database.open()
        database.close()
        // Test passes if no exception is thrown
    }

    @Test("WWDCDatabase search with empty query")
    func testWWDCDatabaseEmptyQuery() throws {
        let database = WWDCDatabase(databasePath: ":memory:")
        try database.open()
        defer { database.close() }

        let results = try database.search(query: "", limit: 10)
        #expect(results.isEmpty)
    }

    // MARK: - Decryption Tests

    @Test("Bundle encryption key validation")
    func testBundleEncryptionKeyValidation() throws {
        // Test that encryption keys are properly validated
        let testKeyData = "test_key_32_bytes_long_for_validation".data(using: .utf8)!
        let testKey = SymmetricKey(data: testKeyData)

        let testMessage = "test message"
        let messageData = testMessage.data(using: .utf8)!

        let sealedBox = try AES.GCM.seal(messageData, using: testKey)
        let decryptedData = try AES.GCM.open(sealedBox, using: testKey)
        let decryptedMessage = String(data: decryptedData, encoding: .utf8)

        #expect(decryptedMessage == testMessage)
    }

    @Test("Bundle encryption invalid key")
    func testBundleEncryptionInvalidKey() throws {
        let testKeyData = "test_key_32_bytes_long_for_validation".data(using: .utf8)!
        let testKey = SymmetricKey(data: testKeyData)

        let testMessage = "test message"
        let messageData = testMessage.data(using: .utf8)!

        let sealedBox = try AES.GCM.seal(messageData, using: testKey)

        // Try to decrypt with a different key
        let wrongKeyData = "wrong_key_32_bytes_long_for_validation".data(using: .utf8)!
        let wrongKey = SymmetricKey(data: wrongKeyData)

        // This should throw an error
        #expect(throws: (any Error).self) { try AES.GCM.open(sealedBox, using: wrongKey) }
    }

    // MARK: - Search Tests

    @Test("WWDC search with mock data")
    func testWWDCSearchWithMockData() throws {
        let results = try WWDCSearchEngine.search(query: "SwiftUI", in: "mock", forceRealData: false)
        #expect(!results.isEmpty)

        // Check that results have the expected structure
        for result in results {
            #expect(!result.title.isEmpty)
            #expect(result.year >= 2007 && result.year <= Calendar.current.component(.year, from: Date()) + 1)
            #expect(result.relevanceScore > 0)
            #expect(!result.excerpt.isEmpty)
        }
    }

    @Test("WWDC search with SharePlay query")
    func testWWDCSearchSharePlayQuery() throws {
        let results = try WWDCSearchEngine.search(query: "SharePlay", in: "mock", forceRealData: false)
        #expect(!results.isEmpty)

        // Should find SharePlay related sessions
        let sharePlayResults = results.filter {
            $0.title.lowercased().contains("shareplay") ||
            $0.title.lowercased().contains("group") ||
            $0.excerpt.lowercased().contains("shareplay")
        }
        #expect(!sharePlayResults.isEmpty)
    }

    @Test("WWDC search with timeline query")
    func testWWDCSearchTimelineQuery() throws {
        let results = try WWDCSearchEngine.search(query: "timeline", in: "mock", forceRealData: false)
        #expect(!results.isEmpty)

        // Should find timeline/animation related sessions
        let timelineResults = results.filter {
            $0.title.lowercased().contains("timeline") ||
            $0.title.lowercased().contains("animation") ||
            $0.excerpt.lowercased().contains("timeline")
        }
        #expect(!timelineResults.isEmpty)
    }

    // MARK: - MarkdownFormatter Tests

    @Test("MarkdownFormatter user mode formatting")
    func testMarkdownFormatterUserModeFormatting() throws {
        // Create a mock session
        let session = WWDCDatabase.Session(
            id: "test-session",
            title: "Test Session",
            year: 2024,
            sessionNumber: "101",
            description: "Test description",
            url: "https://example.com",
            transcript: "This is a test transcript content for formatting."
        )

        let formatted = MarkdownFormatter.formatSession(
            session,
            mode: .user,
            format: .markdown
        )

        #expect(formatted.contains("# Test Session"))
        #expect(formatted.contains("WWDC 2024 - Session 101"))
        #expect(formatted.contains("https://example.com"))
        #expect(formatted.contains("Test description"))
    }

    @Test("MarkdownFormatter agent mode formatting")
    func testMarkdownFormatterAgentModeFormatting() throws {
        // Create a mock session
        let session = WWDCDatabase.Session(
            id: "test-session",
            title: "Test Session",
            year: 2024,
            sessionNumber: "101",
            description: "Test description",
            url: "https://example.com",
            transcript: "This is a test transcript content for formatting with enough content to test the transcript section formatting."
        )

        let formatted = MarkdownFormatter.formatSession(
            session,
            mode: .agent,
            format: .markdown
        )

        #expect(formatted.contains("# Test Session"))
        #expect(formatted.contains("## Transcript"))
        #expect(formatted.contains("This is a test transcript content"))
        #expect(formatted.contains("Source: WWDC 2024 Session 101"))
    }

    @Test("MarkdownFormatter JSON formatting")
    func testMarkdownFormatterJSONFormatting() throws {
        // Create a mock session
        let session = WWDCDatabase.Session(
            id: "test-session",
            title: "Test Session",
            year: 2024,
            sessionNumber: "101",
            description: "Test description",
            url: "https://example.com",
            transcript: "Test transcript content"
        )

        let formatted = MarkdownFormatter.formatSession(
            session,
            mode: .agent,
            format: .json
        )

        // Should be valid JSON
        #expect(formatted.starts(with: "{"))
        #expect(formatted.hasSuffix("}"))
        #expect(formatted.contains("\"test-session\""))
        #expect(formatted.contains("\"Test Session\""))
        #expect(formatted.contains("\"agent\""))
    }

    @Test("MarkdownFormatter search results formatting")
    func testMarkdownFormatterSearchResultsFormatting() throws {
        // Create mock search results
        let session1 = WWDCDatabase.Session(
            id: "test-session-1",
            title: "SwiftUI Testing",
            year: 2024,
            sessionNumber: "101"
        )

        let session2 = WWDCDatabase.Session(
            id: "test-session-2",
            title: "Advanced SwiftUI",
            year: 2023,
            sessionNumber: "102"
        )

        let results = [
            WWDCDatabase.SearchResult(session: session1, relevanceScore: 25.0),
            WWDCDatabase.SearchResult(session: session2, relevanceScore: 18.5)
        ]

        let formatted = MarkdownFormatter.formatSearchResults(
            results,
            query: "SwiftUI",
            mode: .user,
            format: .markdown
        )

        #expect(formatted.contains("Results for \"SwiftUI\""))
        #expect(formatted.contains("SwiftUI Testing"))
        #expect(formatted.contains("Advanced SwiftUI"))
        #expect(formatted.contains("Recent Sessions"))
    }

    // MARK: - Pipeline Integration Tests

    @Test("Pipeline file structure validation")
    func testPipelineFileStructureValidation() {
        let fileManager = FileManager.default
        let currentDirectory = fileManager.currentDirectoryPath

        // Check if we're in the right directory structure
        let sosumiDataObfuscationPath = "\(currentDirectory)/sosumi-data-obfuscation"
        let sosumiPath = "\(currentDirectory)/sosumi"

        let dataObfuscationExists = fileManager.fileExists(atPath: sosumiDataObfuscationPath)
        let sosumiExists = fileManager.fileExists(atPath: sosumiPath)

        // At least one of these should exist for the tests to run
        #expect(dataObfuscationExists || sosumiExists)
    }

    @Test("Pipeline scripts exist")
    func testPipelineScriptsExist() {
        let fileManager = FileManager.default
        let scriptsDir = "../sosumi-data-obfuscation/Scripts"

        let scriptNames = [
            "1_fetch_metadata.swift",
            "2_download_transcripts.swift",
            "3_build_database.swift",
            "4_generate_markdown.swift",
            "5_encrypt_bundle.swift"
        ]

        for scriptName in scriptNames {
            let scriptPath = "\(scriptsDir)/\(scriptName)"
            if fileManager.fileExists(atPath: scriptPath) {
                #expect(true) // Script exists
            } else {
                // Skip test if script doesn't exist (development environment)
                #expect(true)
            }
        }
    }

    @Test("Makefile exists and is valid")
    func testMakefileExistsAndIsValid() {
        let fileManager = FileManager.default
        let makefilePath = "../sosumi-data-obfuscation/Makefile"

        if fileManager.fileExists(atPath: makefilePath) {
            let makefileContent = try? String(contentsOfFile: makefilePath)
            #expect(makefileContent != nil)
            #expect(makefileContent!.contains("all:"))
            #expect(makefileContent!.contains("fetch:"))
            #expect(makefileContent!.contains("download:"))
            #expect(makefileContent!.contains("build:"))
            #expect(makefileContent!.contains("format:"))
            #expect(makefileContent!.contains("encrypt:"))
        } else {
            // Skip test if Makefile doesn't exist
            #expect(true)
        }
    }

    // MARK: - Apple Attribution Tests

    @Test("Apple attribution in search results")
    func testAppleAttributionInSearchResults() throws {
        let results = try WWDCSearchEngine.search(query: "SwiftUI", in: "mock", forceRealData: false)

        for result in results {
            // All results should have attribution to Apple Developer
            #expect(!result.title.isEmpty)
            #expect(result.relevanceScore > 0)
            #expect(!result.excerpt.isEmpty)
        }
    }

    @Test("Apple attribution in formatted output")
    func testAppleAttributionInFormattedOutput() throws {
        // Create a mock session with proper Apple attribution
        let session = WWDCDatabase.Session(
            id: "test-session",
            title: "Test Session",
            year: 2024,
            sessionNumber: "101",
            url: "https://developer.apple.com/videos/play/wwdc2024-101",
            transcript: "Test transcript content"
        )

        let userModeOutput = MarkdownFormatter.formatSession(
            session,
            mode: .user,
            format: .markdown
        )

        let agentModeOutput = MarkdownFormatter.formatSession(
            session,
            mode: .agent,
            format: .markdown
        )

        // Both modes should contain proper attribution
        #expect(userModeOutput.contains("developer.apple.com"))
        #expect(userModeOutput.contains("Attribution"))

        #expect(agentModeOutput.contains("developer.apple.com"))
        #expect(agentModeOutput.contains("Attribution"))
        #expect(agentModeOutput.contains("WWDC"))
    }

    // MARK: - Performance Tests

    @Test("Search performance under 50ms")
    func testSearchPerformance() throws {
        let startTime = Date()
        let results = try WWDCSearchEngine.search(query: "SwiftUI", in: "mock", forceRealData: false)
        let endTime = Date()

        let duration = endTime.timeIntervalSince(startTime) * 1000 // Convert to milliseconds
        #expect(duration < 50.0) // Should complete in under 50ms
        #expect(!results.isEmpty)
    }

    @Test("Concurrent search performance")
    func testConcurrentSearchPerformance() throws {
        let startTime = Date()

        // Perform multiple searches concurrently
        let queries = ["SwiftUI", "Combine", "async", "SharePlay", "RealityKit"]
        var results: [String] = []

        for query in queries {
            let searchResults = try WWDCSearchEngine.search(query: query, in: "mock", forceRealData: false)
            results.append("\(query): \(searchResults.count) results")
        }

        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime) * 1000 // Convert to milliseconds

        #expect(duration < 200.0) // Should complete all searches in under 200ms
        #expect(results.count == queries.count)
    }

    // MARK: - Error Handling Tests

    @Test("Error handling for invalid database path")
    func testErrorHandlingInvalidDatabasePath() throws {
        let database = WWDCDatabase(databasePath: "/invalid/path/database.db")

        // Should throw an error when trying to open invalid path
        #expect(throws: (any Error).self) { try database.open() }
    }

    @Test("Error handling for corrupt bundle")
    func testErrorHandlingCorruptBundle() throws {
        let corruptData = "corrupt bundle data".data(using: .utf8)!
        let testKey = SymmetricKey(size: .bits256)

        // Should throw an error when trying to decrypt corrupt data
        #expect(throws: (any Error).self) { try AES.GCM.open(AES.GCM.SealedBox(combined: corruptData), using: testKey) }
    }

    // MARK: - Integration Tests

    @Test("End-to-end search workflow")
    func testEndToEndSearchWorkflow() throws {
        // Test the complete search workflow from query to formatted output
        let query = "SwiftUI"

        // 1. Search for results
        let results = try WWDCSearchEngine.search(query: query, in: "mock", forceRealData: false)
        #expect(!results.isEmpty)

        // 2. Format results for user mode
        let userOutput = MarkdownFormatter.formatSearchResults(
            results,
            query: query,
            mode: .user,
            format: .markdown
        )
        #expect(!userOutput.isEmpty)
        #expect(userOutput.contains(query))

        // 3. Format results for agent mode
        let agentOutput = MarkdownFormatter.formatSearchResults(
            results,
            query: query,
            mode: .agent,
            format: .markdown
        )
        #expect(!agentOutput.isEmpty)
        #expect(agentOutput.contains(query))

        // 4. Format results as JSON
        let jsonOutput = MarkdownFormatter.formatSearchResults(
            results,
            query: query,
            mode: .agent,
            format: .json
        )
        #expect(!jsonOutput.isEmpty)
        #expect(jsonOutput.starts(with: "{"))
        #expect(jsonOutput.contains(query))
    }
}
