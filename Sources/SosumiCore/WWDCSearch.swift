import Foundation
import CryptoKit

// MARK: - WWDC Enhanced Search

public enum SearchError: Error {
    case dataNotAvailable
    case invalidDataFormat
    case compressionNotSupported
    case realDataFailed
    case decryptionFailed
}

// MARK: - Decryption Helper
private struct ContentDecryptor {
    // 🔒 SECURITY: Key should come from secure source in production
    // NEVER hardcode keys in public repositories!
    private static func getDecryptionKey() -> SymmetricKey? {
        // 🔒 PRODUCTION KEY MANAGEMENT
        // In production, this should be securely embedded during build process
        // Never expose keys in source code for public repositories

        // Build-time key injection (recommended for public tools)
        #if DEBUG
        // Development: Use placeholder for testing
        // Replace with actual demo key during development
        let devKeyString = ProcessInfo.processInfo.environment["SOSUMI_DEV_KEY"]
            ?? "REPLACE_WITH_ACTUAL_DEVELOPMENT_KEY_32_BYTES"
        if devKeyString.count != 32 {
            print("⚠️  WARNING: Development key is not 32 bytes. Using placeholder.")
            return nil
        }
        return SymmetricKey(data: Data(devKeyString.utf8))
        #else
        // Production: Key MUST be injected via build-time flags or GitHub Secrets
        // This is enforced - no fallback to placeholder
        #if SOSUMI_ENCRYPTION_KEY
            let prodKey = "\(SOSUMI_ENCRYPTION_KEY)"
            guard prodKey.count == 32 else {
                fatalError("❌ SOSUMI_ENCRYPTION_KEY must be exactly 32 bytes. Build failed.")
            }
            return SymmetricKey(data: Data(prodKey.utf8))
        #else
            fatalError("❌ PRODUCTION BUILD ERROR: SOSUMI_ENCRYPTION_KEY not provided. " +
                      "See KEY_MANAGEMENT.md for build instructions.")
        #endif
        #endif
    }

    static func decryptContent(_ encryptedContent: String) throws -> String? {
        guard let key = getDecryptionKey() else {
            throw SearchError.decryptionFailed
        }

        guard let combinedData = Data(base64Encoded: encryptedContent),
              let sealedBox = try? AES.GCM.SealedBox(combined: combinedData),
              let decryptedData = try? AES.GCM.open(sealedBox, using: key),
              let decryptedString = String(data: decryptedData, encoding: .utf8) else {
            return nil
        }

        return decryptedString
    }
}

public struct WWDCSearchEngine {

    // MARK: - Configuration
    private static let maxResults = 20

    // MARK: - Data Structures

    public struct SearchResult {
        public let sessionHash: String
        public let title: String
        public let year: Int
        public let relevanceScore: Double
        public let excerpt: String
        public let timeSegments: [TimeSegment]?

        public init(sessionHash: String, title: String, year: Int, relevanceScore: Double, excerpt: String, timeSegments: [TimeSegment]? = nil) {
            self.sessionHash = sessionHash
            self.title = title
            self.year = year
            self.relevanceScore = relevanceScore
            self.excerpt = excerpt
            self.timeSegments = timeSegments
        }
    }

    public struct TimeSegment {
        public let approximateTime: String
        public let text: String

        public init(approximateTime: String, text: String) {
            self.approximateTime = approximateTime
            self.text = text
        }
    }

    // MARK: - Search Methods

    public static func search(query: String, in dataPath: String, forceRealData: Bool = true) throws -> [SearchResult] {
        // Try to load real data first, fail loudly if requested
        do {
            let realResults = try searchRealData(query: query, in: dataPath)
            if !realResults.isEmpty {
                return realResults
            } else if forceRealData {
                // Real data loaded but no results - this means data might be wrong
                throw SearchError.realDataFailed
            }
        } catch {
            if forceRealData {
                // Fail loudly - don't silently fallback to mock data
                print("❌ REAL DATA FAILED: \(error)")
                print("🔍 Data path: \(dataPath)")
                print("💡 Check if data file exists and is properly obfuscated")
                throw SearchError.realDataFailed
            } else {
                print("⚠️  Could not load real WWDC data, falling back to mock: \(error)")
            }
        }

        // Only fallback to mock data if explicitly allowed
        return createEnhancedMockResults(query: query)
    }

    private static func searchRealData(query: String, in dataPath: String) throws -> [SearchResult] {
        // Try to decompress and search real data
        guard let data = try? loadCompressedData(path: dataPath) else {
            throw SearchError.dataNotAvailable
        }

        // Parse JSON and search for matches
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let sessions = json["sessions"] as? [[String: Any]],
              let searchIndex = json["search_index"] as? [String: [String]] else {
            throw SearchError.invalidDataFormat
        }

        let lowerQuery = query.lowercased()
        let searchTerms = [lowerQuery] + getSynonyms(for: lowerQuery)
        var matchingSessions: Set<String> = Set()

        // First, check search index for fast matching
        for term in searchTerms {
            if let sessionHashes = searchIndex[term.lowercased()] {
                matchingSessions.formUnion(sessionHashes)
            }
        }

        // Then search in titles, excerpts, and optionally full content (with decryption)
        for session in sessions {
            if let title = session["title"] as? String,
               let excerpt = session["excerpt"] as? String,
               let encryptedContent = session["content"] as? String,
               let hash = session["hash"] as? String {

                let matchesTitle = searchTerms.contains { term in
                    title.lowercased().contains(term)
                }

                let matchesExcerpt = searchTerms.contains { term in
                    excerpt.lowercased().contains(term)
                }

                // Try to decrypt full content for enhanced searching (if key available)
                var matchesContent = false
                if let decryptedContent = try? ContentDecryptor.decryptContent(encryptedContent) {
                    matchesContent = searchTerms.contains { term in
                        decryptedContent.lowercased().contains(term)
                    }
                }

                if matchesTitle || matchesExcerpt || matchesContent {
                    matchingSessions.insert(hash)
                }
            }
        }

        // Convert matching sessions to results
        return matchingSessions.compactMap { sessionHash in
            guard let session = sessions.first(where: { $0["hash"] as? String == sessionHash }),
                  let title = session["title"] as? String,
                  let year = session["year"] as? Int,
                  let encryptedContent = session["content"] as? String else {
                return nil
            }

            // Always try to decrypt content for full results
            // Tool should work completely - keys are for source protection only
            guard let content = try? ContentDecryptor.decryptContent(encryptedContent) else {
                // If decryption fails, return nil (this should never happen in properly deployed tool)
                return nil
            }

            let excerpt = extractExcerpt(from: content, query: query)
            let segments = extractTimeSegments(from: content, query: query, duration: 50)

            let score = calculateRelevanceScore(title: title, transcript: content, query: query)

            return SearchResult(
                sessionHash: sessionHash,
                title: title,
                year: year,
                relevanceScore: score,
                excerpt: excerpt,
                timeSegments: segments
            )
        }
    }

    private static func loadCompressedData(path: String) throws -> Data {
        let url = URL(fileURLWithPath: path)
        let compressedData = try Data(contentsOf: url)

        // Use the proper LZFSE decompression from sosumi-data-obfuscation
        guard let data = try (compressedData as NSData).decompressed(using: .lzfse) as Data? else {
            throw SearchError.compressionNotSupported
        }

        return data
    }

    private static func getSynonyms(for query: String) -> [String] {
        let synonyms: [String: [String]] = [
            "shareplay": ["group activities", "groupactivities", "shared experience", "shared activity", "collaborative"],
            "groupactivities": ["shareplay", "group activities", "shared experience"],
            "timeline": ["animation", "playback", "animationresource", "realitykit"],
            "realitykit": ["timeline", "animation", "reality composer", "rcp"],
            "swiftui": ["swift ui", "uikit equivalent"]
        ]

        let lowerQuery = query.lowercased()
        return synonyms.first { $0.key == lowerQuery }?.value ?? []
    }

    public static func formatResults(_ results: [SearchResult], query: String) -> String {
        var output = "# Results for \"\(query)\"\n\n"

        // Group by year
        let recentSessions = results.filter { $0.year >= 2023 }
        let olderSessions = results.filter { $0.year < 2023 }

        if !recentSessions.isEmpty {
            output += "## Recent Sessions (2023-2024) - \(recentSessions.count) results\n\n"
            for (index, result) in recentSessions.enumerated() {
                output += formatResult(result, index: index + 1)
            }
        }

        if !olderSessions.isEmpty {
            output += "\n## Earlier Sessions (2018-2022) - \(olderSessions.count) results\n\n"
            for (index, result) in olderSessions.enumerated() {
                output += formatResult(result, index: index + 1)
            }
        }

        return output
    }

    private static func formatResult(_ result: SearchResult, index: Int) -> String {
        var text = "\(index). **\(result.title)** (\(result.year))\n"
        text += "   Score: \(String(format: "%.1f", result.relevanceScore))\n"

        if let segments = result.timeSegments, !segments.isEmpty {
            text += "   Segments: "
            text += segments.map { $0.approximateTime }.joined(separator: ", ")
            text += "\n"
        }

        text += "   \(result.excerpt)\n\n"
        return text
    }

    // MARK: - Enhanced Mock Results (with comprehensive SharePlay coverage)

    private static func createEnhancedMockResults(query: String) -> [SearchResult] {
        let lowerQuery = query.lowercased()
        let searchTerms = [lowerQuery] + getSynonyms(for: lowerQuery)
        let hasSharePlay = searchTerms.contains { $0.contains("shareplay") || $0.contains("group") || $0.contains("collaborative") }
        let hasTimeline = searchTerms.contains { $0.contains("timeline") || $0.contains("animation") || $0.contains("playback") }

        // SharePlay and Group Activities sessions
        if hasSharePlay {
            return [
                SearchResult(
                    sessionHash: "wwdc2021_10195",
                    title: "Build SharePlay experiences",
                    year: 2021,
                    relevanceScore: 25.0,
                    excerpt: "Learn how to integrate SharePlay and GroupActivities into your apps to create shared experiences that bring people together, whether they're in the same room or miles apart...",
                    timeSegments: [
                        TimeSegment(approximateTime: "2:15", text: "Introduction to SharePlay and GroupActivities framework"),
                        TimeSegment(approximateTime: "8:45", text: "Setting up a GroupActivity session"),
                        TimeSegment(approximateTime: "15:30", text: "Coordinating playback across participants"),
                        TimeSegment(approximateTime: "22:10", text: "Handling join/leave scenarios gracefully"),
                        TimeSegment(approximateTime: "28:50", text: "Best practices for shared experiences")
                    ]
                ),
                SearchResult(
                    sessionHash: "wwdc2021_10032",
                    title: "Meet GroupActivities",
                    year: 2021,
                    relevanceScore: 23.5,
                    excerpt: "Dive deep into the GroupActivities framework and learn how to coordinate activities between people, including media playback, collaborative documents, and shared interactive experiences...",
                    timeSegments: [
                        TimeSegment(approximateTime: "3:20", text: "GroupActivities framework overview"),
                        TimeSegment(approximateTime: "12:45", text: "Activity lifecycle and state management"),
                        TimeSegment(approximateTime: "19:15", text: "Real-time coordination mechanisms"),
                        TimeSegment(approximateTime: "26:30", text: "Integrating with FaceTime and Messages")
                    ]
                ),
                SearchResult(
                    sessionHash: "wwdc2022_10039",
                    title: "GroupActivities updates and best practices",
                    year: 2022,
                    relevanceScore: 21.8,
                    excerpt: "Discover the latest enhancements to GroupActivities including new APIs, improved performance, and guidance on creating compelling shared experiences that work seamlessly across iOS, iPadOS, and macOS...",
                    timeSegments: [
                        TimeSegment(approximateTime: "4:10", text: "What's new in GroupActivities for 2022"),
                        TimeSegment(approximateTime: "11:30", text: "Enhanced coordination APIs"),
                        TimeSegment(approximateTime: "18:45", text: "Cross-platform compatibility improvements"),
                        TimeSegment(approximateTime: "25:20", text: "Privacy and security considerations")
                    ]
                ),
                SearchResult(
                    sessionHash: "wwdc2023_10018",
                    title: "Advanced SharePlay: Building custom shared experiences",
                    year: 2023,
                    relevanceScore: 19.2,
                    excerpt: "Go beyond basic SharePlay integration and learn how to build sophisticated collaborative experiences with custom coordination, real-time data sync, and complex activity state management...",
                    timeSegments: [
                        TimeSegment(approximateTime: "6:15", text: "Designing complex collaborative flows"),
                        TimeSegment(approximateTime: "14:40", text: "Custom activity coordination patterns"),
                        TimeSegment(approximateTime: "23:10", text: "Performance optimization for group activities"),
                        TimeSegment(approximateTime: "31:25", text: "Testing multi-user scenarios")
                    ]
                ),
                SearchResult(
                    sessionHash: "wwdc2023_10154",
                    title: "What's new in SharePlay and FaceTime integration",
                    year: 2023,
                    relevanceScore: 17.6,
                    excerpt: "Explore the latest SharePlay enhancements including deeper FaceTime integration, new activity types, and improved tools for debugging and monitoring shared experiences...",
                    timeSegments: [
                        TimeSegment(approximateTime: "5:00", text: "FaceTime API enhancements"),
                        TimeSegment(approximateTime: "13:15", text: "New activity types and templates"),
                        TimeSegment(approximateTime: "20:40", text: "Debugging tools for shared experiences")
                    ]
                )
            ]
        }

        // Timeline and RealityKit animation sessions
        if hasTimeline {
            return [
                SearchResult(
                    sessionHash: "wwdc2023_10007",
                    title: "Dive into Reality Composer Pro",
                    year: 2023,
                    relevanceScore: 24.1,
                    excerpt: "Master Reality Composer Pro's timeline animation system for creating complex spatial experiences. Learn to use AnimationPlaybackController and AnimationResource for precise timing control...",
                    timeSegments: [
                        TimeSegment(approximateTime: "8:30", text: "Timeline animation fundamentals"),
                        TimeSegment(approximateTime: "16:45", text: "AnimationPlaybackController API deep dive"),
                        TimeSegment(approximateTime: "25:10", text: "Working with AnimationResource assets"),
                        TimeSegment(approximateTime: "33:20", text: "Synchronizing multiple animation tracks")
                    ]
                ),
                SearchResult(
                    sessionHash: "wwdc2024_10112",
                    title: "Advanced RealityKit timeline animations",
                    year: 2024,
                    relevanceScore: 22.7,
                    excerpt: "Take your RealityKit animations to the next level with advanced timeline techniques, custom animation curves, and performance optimization strategies for visionOS experiences...",
                    timeSegments: [
                        TimeSegment(approximateTime: "7:15", text: "Advanced timeline editing techniques"),
                        TimeSegment(approximateTime: "15:30", text: "Custom animation curves and easing"),
                        TimeSegment(approximateTime: "24:00", text: "Performance optimization for spatial animations"),
                        TimeSegment(approximateTime: "32:45", text: "Interactive timeline control patterns")
                    ]
                ),
                SearchResult(
                    sessionHash: "wwdc2023_10184",
                    title: "RealityKit: Animation best practices",
                    year: 2023,
                    relevanceScore: 20.3,
                    excerpt: "Learn best practices for implementing animations in RealityKit, including timeline workflows, performance considerations, and techniques for creating smooth spatial animations...",
                    timeSegments: [
                        TimeSegment(approximateTime: "6:00", text: "Animation performance fundamentals"),
                        TimeSegment(approximateTime: "13:20", text: "Timeline vs programmatic animation"),
                        TimeSegment(approximateTime: "21:40", text: "Memory management for animation assets")
                    ]
                )
            ]
        }

        // SwiftUI and animation sessions
        if searchTerms.contains(where: { $0.contains("swiftui") || $0.contains("animation") }) {
            return [
                SearchResult(
                    sessionHash: "wwdc2024_101",
                    title: "What's new in SwiftUI",
                    year: 2024,
                    relevanceScore: 15.8,
                    excerpt: "We've enhanced the animation system with new APIs that make it easier to create smooth, performant animations that adapt to different devices...",
                    timeSegments: [
                        TimeSegment(approximateTime: "12:45", text: "New animation APIs provide better performance"),
                        TimeSegment(approximateTime: "18:20", text: "Adaptive animations for different screen sizes")
                    ]
                ),
                SearchResult(
                    sessionHash: "wwdc2023_456",
                    title: "Advanced SwiftUI animations",
                    year: 2023,
                    relevanceScore: 12.3,
                    excerpt: "Learn advanced techniques for creating complex animations in SwiftUI, including custom timing curves and physics-based animations...",
                    timeSegments: [
                        TimeSegment(approximateTime: "8:15", text: "Custom timing curves and spring animations")
                    ]
                )
            ]
        }

        if searchTerms.contains(where: { $0.contains("async") || $0.contains("concurrency") }) {
            return [
                SearchResult(
                    sessionHash: "wwdc2024_789",
                    title: "Advanced Swift concurrency",
                    year: 2024,
                    relevanceScore: 18.5,
                    excerpt: "Deep dive into Swift's concurrency model, covering async/await, actors, and advanced patterns for building responsive applications...",
                    timeSegments: [
                        TimeSegment(approximateTime: "5:30", text: "Understanding Swift's structured concurrency"),
                        TimeSegment(approximateTime: "22:15", text: "Actor reentrancy and data isolation")
                    ]
                )
            ]
        }

        // Default mock results
        return [
            SearchResult(
                sessionHash: "wwdc2024_123",
                title: "Best practices for iOS development",
                year: 2024,
                relevanceScore: 8.2,
                excerpt: "This session covers essential best practices for building high-quality iOS applications with modern Swift and SwiftUI..."
            )
        ]
    }

    // MARK: - Helper Methods

    private static func calculateRelevanceScore(title: String, transcript: String, query: String) -> Double {
        let lowerTitle = title.lowercased()
        let lowerTranscript = transcript.lowercased()
        let lowerQuery = query.lowercased()

        var score: Double = 0.0

        // Title matches are most valuable
        if lowerTitle.contains(lowerQuery) {
            score += 20.0
        }

        // Count query occurrences in transcript
        let transcriptOccurrences = lowerTranscript.components(separatedBy: lowerQuery).count - 1
        score += Double(transcriptOccurrences) * 2.5

        // Bonus for recent years
        if title.contains("2024") { score += 10.0 }
        else if title.contains("2023") { score += 5.0 }
        else if title.contains("2022") { score += 2.0 }

        // Bonus for key sessions
        if lowerTitle.contains("introduction") || lowerTitle.contains("fundamentals") {
            score += 8.0
        }
        if lowerTitle.contains("advanced") || lowerTitle.contains("deep dive") {
            score += 12.0
        }

        return max(score, 1.0)
    }

    private static func extractExcerpt(from transcript: String, query: String) -> String {
        let sentences = transcript.components(separatedBy: ". ")
        let lowerQuery = query.lowercased()

        // Find first sentence containing the query
        for sentence in sentences {
            if sentence.lowercased().contains(lowerQuery) {
                let cleaned = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
                return cleaned.count > 150 ? String(cleaned.prefix(150)) + "..." : cleaned
            }
        }

        // Fallback to first part of transcript
        return transcript.count > 150 ? String(transcript.prefix(150)) + "..." : transcript
    }

    private static func extractTimeSegments(from transcript: String, query: String, duration: Int) -> [TimeSegment]? {
        // Simple pattern to find time codes like "2:15" or "15:30"
        let timePattern = #"\b(\d{1,2}:\d{2})\b"#
        let regex = try? NSRegularExpression(pattern: timePattern)
        let range = NSRange(location: 0, length: transcript.utf16.count)

        var segments: [TimeSegment] = []
        let matches = regex?.matches(in: transcript, options: [], range: range) ?? []

        for match in matches {
            if let timeRange = Range(match.range, in: transcript) {
                let time = String(transcript[timeRange])

                // Get surrounding text as context
                let startLocation = max(0, match.range.location - 50)
                let endLocation = min(transcript.utf16.count, match.range.location + match.range.length + 100)

                if let contextRange = Range(NSRange(location: startLocation, length: endLocation - startLocation), in: transcript) {
                    let context = String(transcript[contextRange])
                        .replacingOccurrences(of: "\n", with: " ")
                        .trimmingCharacters(in: .whitespacesAndNewlines)

                    // Only include if context mentions query-related terms
                    if context.lowercased().contains(query.lowercased()) {
                        segments.append(TimeSegment(
                            approximateTime: time,
                            text: context.count > 80 ? String(context.prefix(80)) + "..." : context
                        ))

                        // Limit to 4 most relevant segments
                        if segments.count >= 4 {
                            break
                        }
                    }
                }
            }
        }

        return segments.isEmpty ? nil : segments
    }
}

// MARK: - Data Extensions

extension Data {
    var isGzipped: Bool {
        return self.starts(with: [0x1f, 0x8b])
    }
}