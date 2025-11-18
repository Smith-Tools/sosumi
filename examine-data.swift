#!/usr/bin/env swift

import Foundation

// Simple script to examine the obfuscated data structure
func examineObfuscatedData(path: String) {
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

        if let sessions = json["sessions"] as? [[String: Any]] {
            print("📺 Sessions: \(sessions.count)")

            // Show session titles
            for (index, session) in sessions.enumerated() {
                if let title = session["title"] as? String {
                    print("  \(index + 1). \(title)")
                }
            }
        }

        if let searchIndex = json["search_index"] as? [String: [String]] {
            print("🔍 Search index terms: \(searchIndex.count)")

            // Look for SharePlay-related terms
            let shareplayTerms = searchIndex.keys.filter { key in
                key.lowercased().contains("share") ||
                key.lowercased().contains("group") ||
                key.lowercased().contains("activity")
            }

            print("🎯 SharePlay-related terms: \(shareplayTerms.count)")
            for term in shareplayTerms.prefix(10) {
                if let sessions = searchIndex[term] {
                    print("  '\(term)': \(sessions.count) sessions")
                }
            }
        }

        // Show all search terms for debugging
        if let searchIndex = json["search_index"] as? [String: [String]] {
            print("\n📋 All search terms:")
            for term in searchIndex.keys.sorted() {
                print("  \(term)")
            }
        }

    } catch {
        print("❌ Error: \(error)")
    }
}

// Run with command line argument
if CommandLine.arguments.count > 1 {
    let path = CommandLine.arguments[1]
    examineObfuscatedData(path: path)
} else {
    print("Usage: swift examine-data.swift <path-to-json.compressed>")
}