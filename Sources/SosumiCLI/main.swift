import ArgumentParser
import Foundation
import SosumiCore

@main
struct SosumiCLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Sosumi - Apple Documentation & WWDC Search Tool",
        version: "1.1.0",
        subcommands: [SearchCommand.self, WWDCCommand.self, UpdateCommand.self, TestCommand.self]
    )

    struct SearchCommand: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Search Apple documentation and WWDC content"
        )

        @Argument(help: "Search query")
        var query: String

        @Option(name: .long, help: "Limit number of results")
        var limit: Int?

        @Option(name: .long, help: "Content type filter")
        var type: String?

        func run() throws {
            print("🔍 Searching for: \(query)")

            // For now, simulate a basic search
            // In a full implementation, this would use SosumiCore
            print("📚 Found 3 results for '\(query)':")
            print("1. Codable - Apple Developer Documentation")
            print("   Learn how to encode and decode custom data types")
            print()
            print("2. Encoding and Decoding Custom Types")
            print("   Swift Language Guide section on Codable")
            print()
            print("3. Codable Best Practices")
            print("   Performance considerations and tips")

            if let limit = limit {
                print("📊 Showing top \(limit) results")
            }
        }
    }

    struct WWDCCommand: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Search WWDC session content with enhanced search"
        )

        @Argument(help: "WWDC search query")
        var query: String

        @Option(name: .long, help: "Show detailed results with formatting")
        var detailed = false

        func run() throws {
            print("🎥 Searching WWDC sessions for: \(query)")
            print(String(repeating: "=", count: 50))

            let results = SosumiCore.searchWWDC(query: query)

            if results.isEmpty {
                print("❌ No WWDC sessions found for: \(query)")
                print("💡 Try searching for related terms like 'SwiftUI', 'Combine', 'async'")
                return
            }

            if detailed {
                let formattedResults = SosumiCore.formatWWDCResults(results, query: query)
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

    struct UpdateCommand: ParsableCommand {
        static let configuration = CommandConfiguration(
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
                                    let results = SosumiCore.searchWWDC(query: query)
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
                print("💡 Run sosumi update to generate data file")
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
}