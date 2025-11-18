#!/usr/bin/env swift

import Foundation

func compressData(inputPath: String, outputPath: String) {
    do {
        let data = try Data(contentsOf: URL(fileURLWithPath: inputPath))
        print("📊 Original size: \(data.count) bytes")

        let compressed = try (data as NSData).compressed(using: .lzfse)
        print("✅ Compressed size: \(compressed.count) bytes")

        let compressionRatio = 100 - (Double(compressed.count) / Double(data.count) * 100)
        print("📦 Compression ratio: \(String(format: "%.1f", compressionRatio))%")

        try compressed.write(to: URL(fileURLWithPath: outputPath))
        print("💾 Saved to: \(outputPath)")

    } catch {
        print("❌ Error: \(error)")
    }
}

if CommandLine.arguments.count == 3 {
    compressData(inputPath: CommandLine.arguments[1], outputPath: CommandLine.arguments[2])
} else {
    print("Usage: swift compress-data.swift <input.json> <output.compressed>")
}