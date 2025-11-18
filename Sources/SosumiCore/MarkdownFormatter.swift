import Foundation

/// Formats WWDC search results and sessions as Markdown for different output modes
public class MarkdownFormatter {

    // MARK: - Output Modes

    public enum OutputMode {
        case user    // Short snippet + Apple link
        case agent   // Full transcript + metadata
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
        format: OutputFormat = .markdown
    ) -> String {
        switch format {
        case .markdown:
            return formatSearchResultsAsMarkdown(results, query: query, mode: mode)
        case .json:
            return formatSearchResultsAsJSON(results, query: query, mode: mode)
        }
    }

    /// Formats a single session according to the specified mode and format
    public static func formatSession(
        _ session: WWDCDatabase.Session,
        mode: OutputMode = .user,
        format: OutputFormat = .markdown
    ) -> String {
        switch format {
        case .markdown:
            return formatSessionAsMarkdown(session, mode: mode)
        case .json:
            return formatSessionAsJSON(session, mode: mode)
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
        mode: OutputMode
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

        output += "\(index). **\(session.title)** (\(session.year))\n"

        // Add metadata
        if let platforms = session.platforms, !platforms.isEmpty {
            output += "   Platforms: \(platforms.joined(separator: ", "))\n"
        }

        if let focus = session.focus {
            output += "   Focus: \(focus)\n"
        }

        if let duration = session.duration {
            output += "   Duration: \(formatDuration(duration))\n"
        }

        // Mode-specific content
        switch mode {
        case .user:
            output += formatUserModeContent(result)
        case .agent:
            output += formatAgentModeContent(result)
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
        if let url = session.url {
            output += "   📍 **Full video:** [Watch on Apple Developer](\(url))\n"
        }

        return output
    }

    private static func formatAgentModeContent(_ result: WWDCDatabase.SearchResult) -> String {
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
        if let topics = session.topics, !topics.isEmpty {
            output += "   Topics: \(topics.joined(separator: ", "))\n"
        }

        if let speakers = session.speakers, !speakers.isEmpty {
            output += "   Speakers: \(speakers.joined(separator: ", "))\n"
        }

        if let wordCount = session.wordCount {
            output += "   Word Count: \(wordCount)\n"
        }

        // Include full transcript if available
        if let transcript = session.transcript, !transcript.isEmpty {
            output += "\n   **Transcript:**\n"
            let paragraphs = transcript.components(separatedBy: "\n\n").prefix(5) // First 5 paragraphs
            for paragraph in paragraphs {
                let trimmed = paragraph.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    output += "   \(trimmed)\n\n"
                }
            }
        }

        // Always include attribution
        output += "   **Source:** [Apple Developer](\(session.url ?? "https://developer.apple.com/videos/"))\n"

        return output
    }

    private static func formatSessionAsMarkdown(_ session: WWDCDatabase.Session, mode: OutputMode) -> String {
        var output = ""

        output += "# \(session.title)\n\n"
        output += "**WWDC \(session.year) - Session \(session.sessionNumber)**\n\n"

        // Metadata section
        if let focus = session.focus {
            output += "**Focus:** \(focus)\n\n"
        }

        if let description = session.description {
            output += "**Description:**\n\(description)\n\n"
        }

        if let platforms = session.platforms, !platforms.isEmpty {
            output += "**Platforms:** \(platforms.joined(separator: ", "))\n\n"
        }

        if let topics = session.topics, !topics.isEmpty {
            output += "**Topics:** \(topics.joined(separator: ", "))\n\n"
        }

        if let speakers = session.speakers, !speakers.isEmpty {
            output += "**Speakers:** \(speakers.joined(separator: ", "))\n\n"
        }

        if let duration = session.duration {
            output += "**Duration:** \(formatDuration(duration))\n\n"
        }

        if let wordCount = session.wordCount {
            output += "**Word Count:** \(wordCount)\n\n"
        }

        // Mode-specific content
        switch mode {
        case .user:
            output += "**📺 Watch Full Video:** [Apple Developer](\(session.url ?? "#"))\n\n"
            if let description = session.description, !description.isEmpty {
                output += "**Summary:**\n\(description)\n\n"
            }

        case .agent:
            output += "**📺 Official Video:** [Watch on Apple Developer](\(session.url ?? "#"))\n\n"

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
                output += "Please watch the [full video](\(session.url ?? "#")) for the complete session content.\n\n"
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

                if let platforms = session.platforms, !platforms.isEmpty {
                    output += "   Platforms: \(platforms.joined(separator: ", "))\n"
                }

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
        mode: OutputMode
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
                "url": result.session.url as Any
            ]

            if let platforms = result.session.platforms {
                sessionData["platforms"] = platforms
            }

            if let focus = result.session.focus {
                sessionData["focus"] = focus
            }

            if let duration = result.session.duration {
                sessionData["duration"] = duration
            }

            if let speakers = result.session.speakers {
                sessionData["speakers"] = speakers
            }

            if let topics = result.session.topics {
                sessionData["topics"] = topics
            }

            // Mode-specific content
            switch mode {
            case .user:
                if let description = result.session.description {
                    sessionData["description"] = String(description.prefix(200)).appending("...")
                }

            case .agent:
                sessionData["matchingText"] = result.matchingText
                sessionData["transcript"] = result.session.transcript
                sessionData["wordCount"] = result.session.wordCount as Any
                sessionData["description"] = result.session.description as Any
            }

            return sessionData
        }

        jsonData["results"] = resultsArray

        return formatJSON(jsonData)
    }

    private static func formatSessionAsJSON(_ session: WWDCDatabase.Session, mode: OutputMode) -> String {
        var sessionData: [String: Any] = [
            "id": session.id,
            "title": session.title,
            "year": session.year,
            "sessionNumber": session.sessionNumber,
            "url": session.url as Any,
            "generatedAt": ISO8601DateFormatter().string(from: Date())
        ]

        // Add optional fields
        if let focus = session.focus {
            sessionData["focus"] = focus
        }

        if let platforms = session.platforms {
            sessionData["platforms"] = platforms
        }

        if let duration = session.duration {
            sessionData["duration"] = duration
        }

        if let description = session.description {
            sessionData["description"] = description
        }

        if let speakers = session.speakers {
            sessionData["speakers"] = speakers
        }

        if let topics = session.topics {
            sessionData["topics"] = topics
        }

        if let wordCount = session.wordCount {
            sessionData["wordCount"] = wordCount
        }

        // Mode-specific content
        switch mode {
        case .user:
            // User mode includes minimal information
            break

        case .agent:
            // Agent mode includes full transcript
            sessionData["transcript"] = session.transcript as Any
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
                "sessionNumber": session.sessionNumber,
                "url": session.url as Any
            ]

            if let platforms = session.platforms {
                sessionData["platforms"] = platforms
            }

            if let focus = session.focus {
                sessionData["focus"] = focus
            }

            if let duration = session.duration {
                sessionData["duration"] = duration
            }

            if let wordCount = session.wordCount {
                sessionData["wordCount"] = wordCount
            }

            // Mode-specific content
            switch mode {
            case .user:
                // Minimal info for user mode
                if let description = session.description {
                    sessionData["description"] = String(description.prefix(100)).appending("...")
                }

            case .agent:
                // Full info for agent mode
                sessionData["description"] = session.description as Any
                sessionData["speakers"] = session.speakers as Any
                sessionData["topics"] = session.topics as Any
                sessionData["transcript"] = session.transcript as Any
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

    private static func formatDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60

        if hours > 0 {
            return "\(hours)h \(mins)m"
        } else {
            return "\(mins)m"
        }
    }
}