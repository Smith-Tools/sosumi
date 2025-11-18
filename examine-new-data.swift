#!/usr/bin/env swift

import Foundation

// Simple script to test search with our new data structure
func testSearch(path: String, query: String) {
    do {
        let compressedData = try Data(contentsOf: URL(fileURLWithPath: path))
        print("📦 Compressed size: \(compressedData.count) bytes")

        guard let data = try (compressedData as NSData).decompressed(using: .lzfse) as Data? else {
            print("❌ LZFSE decompression failed")
            return
        }

        print("✅ Decompressed size: \(data.count) bytes")

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("❌ JSON parsing failed")
            return
        }

        print("✅ JSON structure parsed successfully")

        guard let sessions = json["sessions"] as? [[String: Any]],
              let searchIndex = json["search_index"] as? [String: [String]] else {
            print("❌ Missing sessions or search_index")
            return
        }

        print("📺 Sessions: \(sessions.count)")
        print("🔍 Search terms: \(searchIndex.count)")

        let lowerQuery = query.lowercased()
        print("\n🔍 Searching for: '\(query)'")

        // Simple search in index
        var foundSessions: [String: [String: Any]] = [:]

        for (term, sessionHashes) in searchIndex {
            if term.lowercased().contains(lowerQuery) || lowerQuery.contains(term) {
                print("✅ Found term: '\(term)' -> \(sessionHashes.count) sessions")
                for hash in sessionHashes {
                    if let session = sessions.first(where: { $0["hash"] as? String == hash }) {
                        foundSessions[hash] = session
                    }
                }
            }
        }

        // Also search in titles and content
        for session in sessions {
            if let title = session["title"] as? String,
               let content = session["content"] as? String {

                if title.lowercased().contains(lowerQuery) || content.lowercased().contains(lowerQuery) {
                    if let hash = session["hash"] as? String {
                        foundSessions[hash] = session
                        print("✅ Found in title/content: '\(title)'")
                    }
                }
            }
        }

        print("\n📺 Results: \(foundSessions.count) sessions found")

        for (index, session) in foundSessions.values.enumerated() {
            if let title = session["title"] as? String,
               let year = session["year"] as? Int,
               let content = session["content"] as? String {

                print("\n\(index + 1). **\(title)** (\(year))")

                // Extract excerpt (first 200 chars)
                let excerpt = content.count > 200 ? String(content.prefix(200)) + "..." : content
                print("   \(excerpt)")
            }
        }

        if foundSessions.isEmpty {
            print("❌ No sessions found for query: '\(query)'")
            print("\n💡 Available search terms:")
            for term in Array(searchIndex.keys.sorted()).prefix(20) {
                print("   - \(term)")
            }
            print("   ... and \(searchIndex.count - 20) more terms")
        }

    } catch {
        print("❌ Error: \(error)")
    }
}

// Run with command line arguments
if CommandLine.arguments.count == 3 {
    let path = CommandLine.arguments[1]
    let query = CommandLine.arguments[2]
    testSearch(path: path, query: query)
} else {
    print("Usage: swift examine-new-data.swift <path-to-json.compressed> <query>")
}