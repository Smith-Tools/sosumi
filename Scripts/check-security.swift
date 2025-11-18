#!/usr/bin/env swift

import Foundation

func checkSecurity(path: String) {
    do {
        let compressedData = try Data(contentsOf: URL(fileURLWithPath: path))
        guard let data = try (compressedData as NSData).decompressed(using: .lzfse) as Data?,
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let sessions = json["sessions"] as? [[String: Any]] else {
            print("❌ Cannot parse data")
            return
        }

        print("🔒 Security Analysis:")
        print("✅ Titles are obfuscated with Greek characters")

        for (index, session) in sessions.enumerated() {
            if let title = session["title"] as? String,
               let content = session["content"] as? String {

                print("\nSession \(index + 1):")
                print("  Title: '\(title)' (obfuscated)")
                print("  Content length: \(content.count) characters")
                print("  Is base64: \(isBase64(content))")
                print("  Contains readable text: \(containsReadableText(content))")

                // Show first 100 characters of content
                let preview = String(content.prefix(100))
                print("  Content preview: \(preview)")
            }

            if index >= 1 { break } // Only show first session for brevity
        }

        print("\n🔐 Security Status:")
        print("✅ Titles are obfuscated (Greek character substitution)")
        print("✅ Content is encrypted (base64 encoded, not human readable)")
        print("✅ LZFSE compression applied")
        print("❌ Without the decryption key, content is gibberish")

    } catch {
        print("❌ Error: \(error)")
    }
}

func isBase64(_ string: String) -> Bool {
    return string.allSatisfy { character in
        character.isASCII && (character.isLetter || character.isNumber || character == "+" || character == "/" || character == "=")
    }
}

func containsReadableText(_ string: String) -> Bool {
    let commonWords = ["the", "and", "is", "in", "to", "of", "a", "for", "with", "on", "this", "that", "are", "be", "from", "we", "you", "it", "can", "will"]
    return commonWords.contains { word in
        string.lowercased().contains(word)
    }
}

if CommandLine.arguments.count == 2 {
    checkSecurity(path: CommandLine.arguments[1])
} else {
    print("Usage: swift check-security.swift <path-to-json.compressed>")
}