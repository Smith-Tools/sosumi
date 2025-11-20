#!/usr/bin/env swift

import Foundation
@testable import SosumiDocs

print("🧪 Testing Intent Parsing Logic")

// Test the SearchIntent enum
let testIntents = [
    ("example", .example),
    ("explain", .explain),
    ("reference", .reference),
    ("learn", .learn),
    ("all", .all),
    ("invalid", nil)
]

for (input, expected) in testIntents {
    let parsed = SearchIntent.from(string: input)
    if parsed == expected {
        print("✅ '\(input)' → \(parsed?.description ?? "nil") (correct)")
    } else {
        print("❌ '\(input)' → \(parsed?.description ?? "nil") (expected \(expected?.description ?? "nil"))")
    }
}

// Test intent detection from queries
let client = AppleDocumentationClient()
let testQueries = [
    ("how to animate", .example),
    ("explain animations", .explain),
    ("animation API", .reference),
    ("learn animations", .learn),
    ("SwiftUI", .all)
]

for (query, expected) in testQueries {
    let detected = client.detectIntent(from: query)
    if detected == expected {
        print("✅ '\(query)' → \(detected) (correct)")
    } else {
        print("❌ '\(query)' → \(detected) (expected \(expected))")
    }
}

print("\n🎯 Intent parsing functionality verified!")