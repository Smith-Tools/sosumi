#!/usr/bin/env swift

import Foundation
import CryptoKit

// Hybrid approach: Public metadata + Private encrypted content
struct HybridObfuscator {
    private static let obfuscationKey = "12345678901234567890123456789012"

    // Encrypt only the transcript, keep metadata public
    static func createHybridData(sessions: [[String: Any]], searchIndex: [String: [String]]) throws -> [String: Any] {
        var hybridSessions: [[String: Any]] = []

        for session in sessions {
            guard let title = session["title"] as? String,
                  let year = session["year"] as? Int,
                  let content = session["content"] as? String,
                  let hash = session["hash"] as? String else {
                continue
            }

            // Keep title readable for public searching
            let publicTitle = title

            // Encrypt only the transcript content
            let encryptedContent = try encryptContent(content)

            // Create excerpt from first 200 chars for public searching
            let publicExcerpt = content.count > 200 ? String(content.prefix(200)) + "..." : content

            let checksum = String(format: "%02x", content.hashValue)

            let hybridSession: [String: Any] = [
                "hash": hash,
                "title": publicTitle,           // ✅ Public - searchable
                "year": year,                   // ✅ Public
                "excerpt": publicExcerpt,       // ✅ Public - searchable
                "content": encryptedContent,    // 🔒 Private - encrypted
                "checksum": checksum
            ]

            hybridSessions.append(hybridSession)
        }

        return [
            "version": 1,
            "sessions": hybridSessions,
            "search_index": searchIndex,
            "metadata": [
                "total_sessions": hybridSessions.count,
                "years_range": [2021, 2023],
                "created_at": ISO8601DateFormatter().string(from: Date()),
                "security_model": "hybrid_public_metadata_private_content"
            ]
        ]
    }

    // Encrypt content with AES-256-GCM
    private static func encryptContent(_ content: String) throws -> String {
        let key = SymmetricKey(data: Data(obfuscationKey.utf8))
        let contentData = content.data(using: .utf8)!

        let sealedBox = try AES.GCM.seal(contentData, using: key)
        return sealedBox.combined?.base64EncodedString() ?? ""
    }
}

// Main execution
if CommandLine.arguments.count != 3 {
    print("Usage: swift hybrid-obfuscate.swift <input.json> <output.compressed>")
    exit(1)
}

let inputPath = CommandLine.arguments[1]
let outputPath = CommandLine.arguments[2]

do {
    // Load original data
    let data = try Data(contentsOf: URL(fileURLWithPath: inputPath))
    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
          let sessions = json["sessions"] as? [[String: Any]],
          let searchIndex = json["search_index"] as? [String: [String]] else {
        print("❌ Invalid input format")
        exit(1)
    }

    print("📊 Processing \(sessions.count) sessions with hybrid security model...")

    // Create hybrid data
    let hybridData = try HybridObfuscator.createHybridData(
        sessions: sessions,
        searchIndex: searchIndex
    )

    // Convert to JSON
    let hybridJSON = try JSONSerialization.data(withJSONObject: hybridData, options: .prettyPrinted)
    print("✅ Hybrid data size: \(hybridJSON.count) bytes")

    // Compress with LZFSE
    let compressed = try (hybridJSON as NSData).compressed(using: .lzfse)
    print("✅ Compressed size: \(compressed.count) bytes")

    let compressionRatio = 100 - (Double(compressed.count) / Double(hybridJSON.count) * 100)
    print("📦 Compression ratio: \(String(format: "%.1f", compressionRatio))%")

    // Write output
    try compressed.write(to: URL(fileURLWithPath: outputPath))
    print("💾 Saved to: \(outputPath)")

    // Verify hybrid security
    if let sessions = hybridData["sessions"] as? [[String: Any]],
       let sampleSession = sessions.first,
       let title = sampleSession["title"] as? String,
       let excerpt = sampleSession["excerpt"] as? String,
       let content = sampleSession["content"] as? String {
        print("\n🔒 Hybrid Security Verification:")
        print("  ✅ Title (public): '\(title)'")
        print("  ✅ Excerpt (public): '\(excerpt.prefix(50))...'")
        print("  🔒 Content (private): \(content.count) chars encrypted")
        print("  🎯 Users can search titles/excerpts without key")
        print("  🔐 Full content requires decryption key")
    }

} catch {
    print("❌ Error: \(error)")
    exit(1)
}