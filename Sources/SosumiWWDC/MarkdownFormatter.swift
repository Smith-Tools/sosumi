import Foundation

/// Formats WWDC search results and sessions as Markdown for different output modes
public class MarkdownFormatter {

    // MARK: - Output Modes

    public enum OutputMode {
        case compact       // Quick overview: title + ID + duration + topics
        case user          // Short snippet + Apple link
        case agent         // Full transcript + metadata
        case compactAgent  // Truncated transcript + structured for AI efficiency
    }

    public enum OutputFormat {
        case markdown
        case json
    }

    // MARK: - Formatting Methods

    /// Formats search results according to the specified mode and format
    public static func formatSearchResults(
        _ results: [WWDCDatabase.SearchResult],
        query: String,
        mode: OutputMode = .user,
        format: OutputFormat = .markdown,
        maxTranscriptParagraphs: Int = 2
    ) -> String {
        switch format {
        case .markdown:
            return formatSearchResultsAsMarkdown(results, query: query, mode: mode, maxTranscriptParagraphs: maxTranscriptParagraphs)
        case .json:
            return formatSearchResultsAsJSON(results, query: query, mode: mode, maxTranscriptParagraphs: maxTranscriptParagraphs)
        }
    }

    /// Formats a single session according to the specified mode and format
    public static func formatSession(
        _ session: WWDCDatabase.Session,
        mode: OutputMode = .user,
        format: OutputFormat = .markdown,
        maxTranscriptParagraphs: Int = 2
    ) -> String {
        switch format {
        case .markdown:
            return formatSessionAsMarkdown(session, mode: mode, maxTranscriptParagraphs: maxTranscriptParagraphs)
        case .json:
            return formatSessionAsJSON(session, mode: mode, maxTranscriptParagraphs: maxTranscriptParagraphs)
        }
    }

    /// Formats multiple sessions according to the specified mode and format
    public static func formatSessions(
        _ sessions: [WWDCDatabase.Session],
        mode: OutputMode = .user,
        format: OutputFormat = .markdown
    ) -> String {
        switch format {
        case .markdown:
            return formatSessionsAsMarkdown(sessions, mode: mode)
        case .json:
            return formatSessionsAsJSON(sessions, mode: mode)
        }
    }

    // MARK: - Private Markdown Formatting Methods

    private static func formatSearchResultsAsMarkdown(
        _ results: [WWDCDatabase.SearchResult],
        query: String,
        mode: OutputMode,
        maxTranscriptParagraphs: Int = 2
    ) -> String {
        var output = ""

        if results.isEmpty {
            output += "No results found for \"\(query)\"\n\n"
            output += "Try different keywords or browse sessions by year.\n"
            return output
        }

        // Group results by recency
        let currentYear = Calendar.current.component(.year, from: Date())
        let recentResults = results.filter { $0.session.year >= currentYear - 1 }
        let olderResults = results.filter { $0.session.year < currentYear - 1 }

        if !recentResults.isEmpty {
            output += "## Recent Sessions (\(recentResults.first?.session.year ?? currentYear)-\(currentYear)) - \(recentResults.count) results\n\n"

            for (index, result) in recentResults.enumerated() {
                output += formatSearchResultMarkdown(result, index: index + 1, mode: mode)
            }
        }

        if !olderResults.isEmpty {
            if !recentResults.isEmpty {
                output += "\n"
            }

            output += "## Earlier Sessions - \(olderResults.count) results\n\n"

            for (index, result) in olderResults.enumerated() {
                output += formatSearchResultMarkdown(result, index: index + 1, mode: mode)
            }
        }

        output += "\n---\n\n"
        output += "**Search query:** \"\(query)\" | "
        output += "**Total results:** \(results.count) | "
        output += "**Source:** WWDC Sessions Archive\n"

        return output
    }

    private static func formatSearchResultMarkdown(
        _ result: WWDCDatabase.SearchResult,
        index: Int,
        mode: OutputMode
    ) -> String {
        let session = result.session
        var output = ""

        // Mode-specific formatting
        switch mode {
        case .compact:
            // Compact format: one efficient line with canonical session ID
            let canonicalId = "wwdc\(session.year)-\(session.sessionNumber)"
            let durationStr = session.duration.map { formatDuration($0) } ?? "duration unknown"
            output += "\(index). **\(session.title)** (\(durationStr))\n"
            output += "   \(canonicalId) | "

            // Add topics
            let topics = extractKeyTopics(from: session)
            output += topics.joined(separator: " • ")
            output += "\n"

        case .user:
            // User format: title + year + duration + snippet
            output += "\(index). **\(session.title)** (\(session.year))\n"
            if let duration = session.duration {
                output += "   Duration: \(formatDuration(duration))\n"
            }
            output += formatUserModeContent(result)

        case .agent:
            // Agent format: title + year + duration + full metadata
            output += "\(index). **\(session.title)** (\(session.year))\n"
            if let duration = session.duration {
                output += "   Duration: \(formatDuration(duration))\n"
            }
            output += formatAgentModeContent(result)

        case .compactAgent:
            // CompactAgent format: title + relevance + minimal transcript for AI efficiency
            output += "\(index). **\(session.title)** (\(session.year))\n"
            if let duration = session.duration {
                output += "   Duration: \(formatDuration(duration))\n"
            }
            output += formatCompactAgentModeContent(result, maxTranscriptParagraphs: 2)
        }

        output += "\n"
        return output
    }

    private static func formatUserModeContent(_ result: WWDCDatabase.SearchResult) -> String {
        let session = result.session
        var output = ""

        // Add a brief snippet from the transcript or description
        var snippet = ""

        if let description = session.description, !description.isEmpty {
            snippet = description.prefix(200).appending("...")
        } else if let transcript = session.transcript, !transcript.isEmpty {
            // Get first few sentences from transcript
            let sentences = transcript.components(separatedBy: ". ").prefix(2)
            snippet = sentences.joined(separator: ". ").appending(".")
        }

        if !snippet.isEmpty {
            output += "   \(snippet)\n"
        }

        // Always include the official Apple link
        if let url = session.webUrl {
            output += "   📍 **Full video:** [Watch on Apple Developer](\(url))\n"
        }

        return output
    }

    private static func formatAgentModeContent(_ result: WWDCDatabase.SearchResult, maxTranscriptParagraphs: Int = 2) -> String {
        let session = result.session
        var output = ""

        // Add relevance score
        output += "   Relevance Score: \(String(format: "%.2f", result.relevanceScore))\n"

        // Add matching text snippets
        if !result.matchingText.isEmpty {
            output += "   **Matching content:**\n"
            for match in result.matchingText {
                output += "   - \(match)\n"
            }
        }

        // Add detailed metadata
        if let wordCount = session.wordCount {
            output += "   Word Count: \(wordCount)\n"
        }

        // Include full transcript if available
        if let transcript = session.transcript, !transcript.isEmpty {
            output += "\n   **Transcript:**\n"
            let paragraphs = transcript.components(separatedBy: "\n\n").prefix(maxTranscriptParagraphs) // Respect the limit
            for paragraph in paragraphs {
                let trimmed = paragraph.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    output += "   \(trimmed)\n\n"
                }
            }
        }

        // Always include attribution
        output += "   **Source:** [Apple Developer](\(session.webUrl ?? "https://developer.apple.com/videos/"))\n"

        return output
    }

    private static func formatCompactAgentModeContent(_ result: WWDCDatabase.SearchResult, maxTranscriptParagraphs: Int = 2) -> String {
        let session = result.session
        var output = ""

        // Add relevance score as percentage
        output += "   📊 **Relevance:** \(String(format: "%.0f%%", result.relevanceScore * 100))\n"

        // Brief summary instead of full description
        if let description = session.description, !description.isEmpty {
            let summaryLength = min(description.count, 300)
            let summary = String(description.prefix(summaryLength))
            output += "   \(summary)\(description.count > 300 ? "..." : "")\n\n"
        }

        // Top topics only
        let topics = extractKeyTopics(from: session)
        if !topics.isEmpty {
            output += "   🎯 **Topics:** \(topics.prefix(3).joined(separator: ", "))\n\n"
        }

        // Minimal transcript (capped at maxTranscriptParagraphs)
        if let transcript = session.transcript, !transcript.isEmpty {
            let paragraphs = transcript.components(separatedBy: "\n\n").prefix(maxTranscriptParagraphs)
            for paragraph in paragraphs {
                let trimmed = paragraph.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    output += "   > \(trimmed)\n\n"
                }
            }
        }

        // Link to full video
        output += "   📺 [Watch on Apple Developer](\(session.webUrl ?? "https://developer.apple.com/videos/"))\n"

        return output
    }

    private static func extractKeyTopics(from session: WWDCDatabase.Session) -> [String] {
        var topics: [String] = []

        // Common framework patterns
        let title = session.title.lowercased()
        let description = session.description?.lowercased() ?? ""

        // Extract frameworks
        if title.contains("swiftui") || description.contains("swiftui") {
            topics.append("SwiftUI")
        }
        if title.contains("combine") || description.contains("combine") {
            topics.append("Combine")
        }
        if title.contains("realitykit") || description.contains("realitykit") {
            topics.append("RealityKit")
        }
        if title.contains("arkit") || description.contains("arkit") {
            topics.append("ARKit")
        }
        if title.contains("shareplay") || description.contains("shareplay") {
            topics.append("SharePlay")
        }
        if title.contains("core data") || description.contains("core data") {
            topics.append("Core Data")
        }
        if title.contains("swift concurrency") || description.contains("async/await") {
            topics.append("Concurrency")
        }
        if title.contains("visionos") || description.contains("vision os") {
            topics.append("visionOS")
        }

        // Extract key concepts
        if title.contains("what's new") || description.contains("new features") {
            topics.append("New Features")
        }
        if title.contains("essentials") || description.contains("fundamentals") {
            topics.append("Essentials")
        }
        if title.contains("performance") || description.contains("optimization") {
            topics.append("Performance")
        }
        if title.contains("design") || description.contains("ui") {
            topics.append("Design")
        }

        // Fallback if no topics found
        if topics.isEmpty {
            // Extract keywords from title
            let words = title.components(separatedBy: " ")
                .filter { $0.count > 3 }
                .prefix(2)
                .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            topics = Array(words)
        }

        return topics
    }

    private static func formatSessionAsMarkdown(_ session: WWDCDatabase.Session, mode: OutputMode, maxTranscriptParagraphs: Int = 2) -> String {
        var output = ""

        output += "# \(session.title)\n\n"
        output += "**WWDC \(session.year) - Session \(session.sessionNumber)**\n\n"

        // Metadata section
        if let description = session.description {
            output += "**Description:**\n\(description)\n\n"
        }

        if let duration = session.duration {
            output += "**Duration:** \(formatDuration(duration))\n\n"
        }

        if let wordCount = session.wordCount {
            output += "**Word Count:** \(wordCount)\n\n"
        }

        // Mode-specific content
        switch mode {
        case .compact:
            // Compact format: one line with key info
            let topics = extractKeyTopics(from: session)
            let topicsStr = topics.isEmpty ? "General" : topics.joined(separator: " • ")
            if let duration = session.duration {
                output += "**\(session.title)** (WWDC\(session.year)-\(session.sessionNumber)) • \(formatDuration(duration)) • \(topicsStr)\n\n"
            } else {
                output += "**\(session.title)** (WWDC\(session.year)-\(session.sessionNumber)) • \(topicsStr)\n\n"
            }

        case .user:
            output += "**📺 Watch Full Video:** [Apple Developer](\(session.webUrl ?? "#"))\n\n"
            if let description = session.description, !description.isEmpty {
                output += "**Summary:**\n\(description)\n\n"
            }

        case .agent:
            output += "**📺 Official Video:** [Watch on Apple Developer](\(session.webUrl ?? "#"))\n\n"

            if let transcript = session.transcript, !transcript.isEmpty {
                output += "## Transcript\n\n"
                output += "*\(session.wordCount ?? 0) words*\n\n"

                // Format transcript in paragraphs
                let paragraphs = transcript.components(separatedBy: "\n\n")
                for (index, paragraph) in paragraphs.enumerated() {
                    let trimmed = paragraph.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        // If it looks like speaker change, format as such
                        if trimmed.contains(":") && trimmed.count < 100 {
                            output += "### \(trimmed)\n\n"
                        } else {
                            output += "\(trimmed)\n\n"
                        }

                        // Add separator after significant content
                        if index % 3 == 2 && index < paragraphs.count - 1 {
                            output += "\n"
                        }
                    }
                }
            } else {
                output += "## Transcript\n\n"
                output += "*Transcript not available*\n\n"
                output += "Please watch the [full video](\(session.webUrl ?? "#")) for the complete session content.\n\n"
            }

        case .compactAgent:
            output += "**📺 Watch:** [Apple Developer](\(session.webUrl ?? "#"))\n\n"

            // Brief summary only
            if let description = session.description, !description.isEmpty {
                let summaryLength = min(description.count, 300)
                output += String(description.prefix(summaryLength))
                if description.count > 300 {
                    output += "..."
                }
                output += "\n\n"
            }

            // Top 3 topics only
            let topics = extractKeyTopics(from: session)
            if !topics.isEmpty {
                output += "**Topics:** \(topics.prefix(3).joined(separator: ", "))\n\n"
            }

            // Minimal transcript preview
            if let transcript = session.transcript, !transcript.isEmpty {
                output += "## Transcript Preview\n\n"
                let paragraphs = transcript.components(separatedBy: "\n\n").prefix(2)
                for paragraph in paragraphs {
                    let trimmed = paragraph.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        output += "> \(trimmed)\n\n"
                    }
                }
            }
        }

        // Footer
        output += "---\n\n"
        output += "**Source:** WWDC \(session.year) Session \(session.sessionNumber)\n\n"
        output += "**Attribution:** This content is from Apple's WWDC session. Please visit the [official Apple Developer website](https://developer.apple.com/videos/) for the original video content.\n"

        return output
    }

    private static func formatSessionsAsMarkdown(_ sessions: [WWDCDatabase.Session], mode: OutputMode) -> String {
        var output = ""

        // Group sessions by year
        let sessionsByYear = Dictionary(grouping: sessions) { $0.year }
        let years = sessionsByYear.keys.sorted { $0 > $1 }

        output += "# WWDC Sessions Archive\n\n"
        output += "*Generated on \(Date())*\n\n"

        for year in years {
            guard let yearSessions = sessionsByYear[year] else { continue }

            output += "## \(year) Sessions (\(yearSessions.count) sessions)\n\n"

            // Sort by session number
            let sortedSessions = yearSessions.sorted { session1, session2 in
                return session1.sessionNumber.compare(session2.sessionNumber, options: .numeric) == .orderedAscending
            }

            for (index, session) in sortedSessions.enumerated() {
                output += "\(index + 1). **[\(session.sessionNumber): \(session.title)](#session-\(session.id.lowercased()))**\n"

                if let duration = session.duration {
                    output += "   Duration: \(formatDuration(duration))\n"
                }

                if let wordCount = session.wordCount, wordCount > 0 {
                    output += "   Words: \(wordCount)\n"
                }

                output += "\n"
            }
        }

        return output
    }

    // MARK: - Private JSON Formatting Methods

    private static func formatSearchResultsAsJSON(
        _ results: [WWDCDatabase.SearchResult],
        query: String,
        mode: OutputMode,
        maxTranscriptParagraphs: Int = 2
    ) -> String {
        var jsonData: [String: Any] = [
            "query": query,
            "mode": mode == .user ? "user" : "agent",
            "resultCount": results.count,
            "generatedAt": ISO8601DateFormatter().string(from: Date()),
            "results": []
        ]

        let resultsArray = results.map { result in
            var sessionData: [String: Any] = [
                "id": result.session.id,
                "title": result.session.title,
                "year": result.session.year,
                "sessionNumber": result.session.sessionNumber,
                "relevanceScore": result.relevanceScore,
                "webUrl": result.session.webUrl as Any
            ]

            if let duration = result.session.duration {
                sessionData["duration"] = duration
            }

            // Mode-specific content
            switch mode {
            case .compact:
                if let description = result.session.description {
                    sessionData["description"] = String(description.prefix(100)).appending("...")
                }
                sessionData["topics"] = extractKeyTopics(from: result.session)
            case .user:
                if let description = result.session.description {
                    sessionData["description"] = String(description.prefix(200)).appending("...")
                }

            case .agent:
                sessionData["matchingText"] = result.matchingText
                sessionData["transcript"] = result.session.transcript
                sessionData["wordCount"] = result.session.wordCount as Any
                sessionData["description"] = result.session.description as Any

            case .compactAgent:
                // Compact version: truncated description and minimal data
                if let description = result.session.description {
                    sessionData["description"] = String(description.prefix(200)).appending("...")
                }
                sessionData["topics"] = extractKeyTopics(from: result.session).prefix(3)
            }

            return sessionData
        }

        jsonData["results"] = resultsArray

        return formatJSON(jsonData)
    }

    private static func formatSessionAsJSON(_ session: WWDCDatabase.Session, mode: OutputMode, maxTranscriptParagraphs: Int = 2) -> String {
        var sessionData: [String: Any] = [
            "id": session.id,
            "title": session.title,
            "year": session.year,
            "sessionNumber": session.sessionNumber,
            "generatedAt": ISO8601DateFormatter().string(from: Date())
        ]

        // Add optional fields
        if let webUrl = session.webUrl {
            sessionData["webUrl"] = webUrl
        }

        if let type = session.type {
            sessionData["type"] = type
        }

        if let duration = session.duration {
            sessionData["duration"] = duration
        }

        if let description = session.description {
            sessionData["description"] = description
        }

        if let wordCount = session.wordCount {
            sessionData["wordCount"] = wordCount
        }

        // Mode-specific content
        switch mode {
        case .compact:
            // Compact mode includes minimal info
            sessionData["topics"] = extractKeyTopics(from: session)
        case .user:
            // User mode includes minimal information
            break

        case .agent:
            // Agent mode includes full transcript
            sessionData["transcript"] = session.transcript as Any

        case .compactAgent:
            // CompactAgent mode includes limited data for efficiency
            if let description = session.description {
                sessionData["description"] = String(description.prefix(200)).appending("...")
            }
            sessionData["topics"] = extractKeyTopics(from: session).prefix(3)
        }

        return formatJSON(sessionData)
    }

    private static func formatSessionsAsJSON(_ sessions: [WWDCDatabase.Session], mode: OutputMode) -> String {
        var jsonData: [String: Any] = [
            "mode": mode == .user ? "user" : "agent",
            "sessionCount": sessions.count,
            "generatedAt": ISO8601DateFormatter().string(from: Date()),
            "sessions": []
        ]

        let sessionsArray = sessions.map { session in
            var sessionData: [String: Any] = [
                "id": session.id,
                "title": session.title,
                "year": session.year,
                "sessionNumber": session.sessionNumber
            ]

            if let webUrl = session.webUrl {
                sessionData["webUrl"] = webUrl
            }

            if let type = session.type {
                sessionData["type"] = type
            }

            if let duration = session.duration {
                sessionData["duration"] = duration
            }

            if let wordCount = session.wordCount {
                sessionData["wordCount"] = wordCount
            }

            // Mode-specific content
            switch mode {
            case .compact:
                // Minimal info for compact mode
                if let description = session.description {
                    sessionData["description"] = String(description.prefix(50)).appending("...")
                }
                sessionData["topics"] = extractKeyTopics(from: session)
            case .user:
                // Minimal info for user mode
                if let description = session.description {
                    sessionData["description"] = String(description.prefix(100)).appending("...")
                }

            case .agent:
                // Full info for agent mode
                sessionData["description"] = session.description as Any
                sessionData["transcript"] = session.transcript as Any

            case .compactAgent:
                // Limited info for compact-agent mode
                if let description = session.description {
                    sessionData["description"] = String(description.prefix(200)).appending("...")
                }
                sessionData["topics"] = extractKeyTopics(from: session).prefix(3)
            }

            return sessionData
        }

        jsonData["sessions"] = sessionsArray

        return formatJSON(jsonData)
    }

    // MARK: - Helper Methods

    private static func formatJSON(_ data: [String: Any]) -> String {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: [.prettyPrinted, .sortedKeys])
            return String(data: jsonData, encoding: .utf8) ?? "{}"
        } catch {
            return "{\"error\": \"Failed to serialize JSON: \(error.localizedDescription)\"}"
        }
    }

    private static func formatDuration(_ seconds: Int) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.collapsesLargestUnit = true

        return formatter.string(from: TimeInterval(seconds)) ?? "\(seconds)s"
    }
}