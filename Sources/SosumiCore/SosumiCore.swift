import Foundation

public struct SosumiCore {
    public static let version = "1.1.0"  // Updated for enhanced search

    public init() {}

    public static func search(query: String) -> [SearchResult] {
        // Enhanced WWDC search implementation
        do {
            let dataPath = "Resources/DATA/wwdc_sessions_2024_enhanced.json.compressed"
            let wwdcResults = try WWDCSearchEngine.search(query: query, in: dataPath)

            return wwdcResults.map { wwdcResult in
                SearchResult(
                    title: wwdcResult.title,
                    description: "WWDC \(wwdcResult.year) Session • Score: \(String(format: "%.1f", wwdcResult.relevanceScore))",
                    url: "https://developer.apple.com/wwdc\(wwdcResult.year)/"
                )
            }
        } catch {
            // Fallback to placeholder results if WWDC data unavailable
            return [
                SearchResult(
                    title: "Apple Developer Documentation",
                    description: "Search Apple's official documentation for: \(query)",
                    url: "https://developer.apple.com/search/?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)"
                ),
                SearchResult(
                    title: "WWDC Session Search",
                    description: "Find WWDC sessions related to: \(query)",
                    url: "https://developer.apple.com/videos/?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)"
                )
            ]
        }
    }

    public static func searchWWDC(query: String) -> [WWDCSearchResult] {
        do {
            let dataPath = "Resources/DATA/wwdc_sessions_2024_enhanced.json.compressed"
            // Force real data - fail loudly if data unavailable
            return try WWDCSearchEngine.search(query: query, in: dataPath, forceRealData: true)
        } catch {
            print("❌ SOSUMI CRITICAL: Real WWDC data unavailable - \(error)")
            print("📁 Expected at: Resources/DATA/wwdc_sessions_2024_enhanced.json.compressed")
            print("🔧 Run 'sosumi update' to regenerate data, or contact maintainers")
            return []
        }
    }

    public static func formatWWDCResults(_ results: [WWDCSearchResult], query: String) -> String {
        return WWDCSearchEngine.formatResults(results, query: query)
    }
}

public struct SearchResult {
    public let title: String
    public let description: String
    public let url: String

    public init(title: String, description: String, url: String) {
        self.title = title
        self.description = description
        self.url = url
    }
}

// Re-export WWDC search types
public typealias WWDCSearchResult = WWDCSearchEngine.SearchResult
public typealias WWDCTimeSegment = WWDCSearchEngine.TimeSegment