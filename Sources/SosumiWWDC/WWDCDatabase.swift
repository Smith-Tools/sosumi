import Foundation
import SQLite3
import CryptoKit
import Compression

/// Manages WWDC database operations including decryption and querying
public class WWDCDatabase {

    // MARK: - Types

    public struct BundleMetadata: Codable {
        public let version: String
        public let createdAt: String
        public let totalSessions: Int
        public let totalYears: Int
        public let totalWordCount: Int
        public let uncompressedSize: Int64
        public let compressedSize: Int64
        public let encryptionAlgorithm: String
        public let checksum: String
    }

    public struct Session: Codable {
        public let id: String
        public let title: String
        public let year: Int
        public let sessionNumber: String
        public let type: String?
        public let duration: Int?
        public let description: String?
        public let webUrl: String?
        public let transcript: String?
        public let wordCount: Int?

        public init(
            id: String,
            title: String,
            year: Int,
            sessionNumber: String,
            type: String? = nil,
            duration: Int? = nil,
            description: String? = nil,
            webUrl: String? = nil,
            transcript: String? = nil,
            wordCount: Int? = nil
        ) {
            self.id = id
            self.title = title
            self.year = year
            self.sessionNumber = sessionNumber
            self.type = type
            self.duration = duration
            self.description = description
            self.webUrl = webUrl
            self.transcript = transcript
            self.wordCount = wordCount
        }
    }

    public struct SearchResult {
        public let session: Session
        public let relevanceScore: Double
        public let matchingText: [String]

        public init(session: Session, relevanceScore: Double, matchingText: [String] = []) {
            self.session = session
            self.relevanceScore = relevanceScore
            self.matchingText = matchingText
        }
    }

    // MARK: - Properties

    private let databasePath: String
    private var db: OpaquePointer?
    private var isInitialized = false

    // MARK: - Initialization

    public init(databasePath: String) {
        self.databasePath = databasePath
    }

    deinit {
        close()
    }

    // MARK: - Bundle Management

    /// Decrypts and extracts an encrypted bundle
    public static func decryptBundle(atPath bundlePath: String, key: SymmetricKey) throws -> (metadata: BundleMetadata, databasePath: String, markdownPath: String) {

        // Load and parse encrypted bundle
        let bundleData = try Data(contentsOf: URL(fileURLWithPath: bundlePath))
        let encryptedBundle = try JSONDecoder().decode(EncryptedBundle.self, from: bundleData)

        // Decrypt the data
        let encryptedData = Data(base64Encoded: encryptedBundle.encryptedData)!
        let ivData = Data(base64Encoded: encryptedBundle.iv)!
        let tagData = Data(base64Encoded: encryptedBundle.tag)!

        let nonce = try AES.GCM.Nonce(data: ivData)
        let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: encryptedData, tag: tagData)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)

        // Decompress the data
        let decompressedData = try (decryptedData as NSData).decompressed(using: .lzfse) as Data

        // Parse the bundle JSON
        guard let bundleJSON = try JSONSerialization.jsonObject(with: decompressedData) as? [String: Any] else {
            throw WWDCDatabaseError.invalidBundleFormat
        }

        // Create temporary directory for extracted files
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        // Extract database
        if let databaseInfo = bundleJSON["database"] as? [String: Any],
           let databaseBase64 = databaseInfo["data"] as? String,
           let databaseData = Data(base64Encoded: databaseBase64) {
            let databasePath = tempDir.appendingPathComponent("wwdc.db").path
            try databaseData.write(to: URL(fileURLWithPath: databasePath))
        }

        // Extract markdown files
        if let markdownInfo = bundleJSON["markdown"] as? [String: Any],
           let files = markdownInfo["files"] as? [String: String] {
            let markdownDir = tempDir.appendingPathComponent("markdown")
            try FileManager.default.createDirectory(at: markdownDir, withIntermediateDirectories: true)

            for (filename, base64Content) in files {
                if let fileData = Data(base64Encoded: base64Content) {
                    let filePath = markdownDir.appendingPathComponent(filename)
                    try fileData.write(to: filePath)
                }
            }
        }

        return (encryptedBundle.metadata, tempDir.appendingPathComponent("wwdc.db").path, tempDir.appendingPathComponent("markdown").path)
    }

    // MARK: - Database Operations

    /// Opens the database connection
    public func open() throws {
        guard !isInitialized else { return }

        if sqlite3_open(databasePath, &db) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db))
            throw WWDCDatabaseError.databaseConnectionFailed(errmsg)
        }

        // Enable foreign key constraints
        if sqlite3_exec(db, "PRAGMA foreign_keys = ON;", nil, nil, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db))
            throw WWDCDatabaseError.databaseError(errmsg)
        }

        isInitialized = true
    }

    /// Closes the database connection
    public func close() {
        if isInitialized {
            sqlite3_close(db)
            db = nil
            isInitialized = false
        }
    }

    /// Performs a full-text search for sessions matching the query
    public func search(query: String, limit: Int = 20, offset: Int = 0) throws -> [SearchResult] {
        try ensureInitialized()

        // Use string interpolation instead of parameter binding for FTS5 MATCH queries
        // This works around the SQLite FTS5 parameter binding issue in Swift
        let searchQuery = """
        SELECT
            s.id, s.title, s.year, s.session_number, s.type, s.duration,
            s.description, s.web_url,
            t.content, t.word_count,
            bm25(transcripts_fts)
        FROM transcripts_fts
        JOIN sessions s ON transcripts_fts.session_id = s.id
        LEFT JOIN transcripts t ON s.id = t.session_id
        WHERE transcripts_fts MATCH '\(query)'
        ORDER BY bm25(transcripts_fts)
        LIMIT \(limit) OFFSET \(offset)
        """

        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, searchQuery, -1, &stmt, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db))
            throw WWDCDatabaseError.queryFailed(errmsg)
        }

        var results: [SearchResult] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let session = extractSessionFrom(stmt: stmt)
            let relevanceScore = sqlite3_column_double(stmt, 10)
            results.append(SearchResult(session: session, relevanceScore: relevanceScore, matchingText: []))
        }

        sqlite3_finalize(stmt)

        return results
    }

    /// Gets a specific session by ID
    public func getSession(byId id: String) throws -> Session? {
        try ensureInitialized()

        // Use string interpolation instead of parameter binding to work around SQLite binding issues
        let sanitizedId = id.replacingOccurrences(of: "'", with: "''")
        let query = """
        SELECT
            s.id, s.title, s.year, s.session_number, s.type, s.duration,
            s.description, s.web_url,
            t.content, t.word_count
        FROM sessions s
        LEFT JOIN transcripts t ON s.id = t.session_id
        WHERE s.id = '\(sanitizedId)'
        """

        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db))
            throw WWDCDatabaseError.queryFailed(errmsg)
        }

        let result = sqlite3_step(stmt)
        if result == SQLITE_ROW {
            let session = extractSessionFrom(stmt: stmt)
            sqlite3_finalize(stmt)
            return session
        } else {
            sqlite3_finalize(stmt)
            return nil
        }
    }

    /// Gets sessions by year
    public func getSessionsByYear(_ year: Int, limit: Int = 50) throws -> [Session] {
        try ensureInitialized()

        // Use string interpolation instead of parameter binding to work around SQLite binding issues
        let query = """
        SELECT
            s.id, s.title, s.year, s.session_number, s.type, s.duration,
            s.description, s.web_url,
            t.content, t.word_count
        FROM sessions s
        LEFT JOIN transcripts t ON s.id = t.session_id
        WHERE s.year = \(year)
        ORDER BY s.session_number
        LIMIT \(limit)
        """

        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db))
            throw WWDCDatabaseError.queryFailed(errmsg)
        }

        var sessions: [Session] = []

        while sqlite3_step(stmt) == SQLITE_ROW {
            let session = extractSessionFrom(stmt: stmt)
            sessions.append(session)
        }

        sqlite3_finalize(stmt)

        return sessions
    }

    /// Gets database statistics
    public func getStatistics() throws -> [String: Any] {
        try ensureInitialized()

        var stats: [String: Any] = [:]

        let queries: [(String, String)] = [
            ("total_sessions", "SELECT COUNT(*) FROM sessions;"),
            ("sessions_with_transcripts", "SELECT COUNT(*) FROM transcripts WHERE content IS NOT NULL;"),
            ("total_word_count", "SELECT SUM(word_count) FROM transcripts;"),
            ("average_duration", "SELECT AVG(duration) FROM sessions WHERE duration IS NOT NULL;"),
            ("year_range", "SELECT MIN(year), MAX(year) FROM sessions;"),
            ("unique_session_types", "SELECT COUNT(DISTINCT type) FROM sessions WHERE type IS NOT NULL;")
        ]

        for (key, query) in queries {
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
                if sqlite3_step(stmt) == SQLITE_ROW {
                    if key == "year_range" {
                        let minYear = sqlite3_column_int(stmt, 0)
                        let maxYear = sqlite3_column_int(stmt, 1)
                        stats[key] = ["min": minYear, "max": maxYear]
                    } else if let value = sqlite3_column_text(stmt, 0) {
                        stats[key] = String(cString: value)
                    } else {
                        let intValue = sqlite3_column_int(stmt, 0)
                        stats[key] = Int(intValue)
                    }
                }
            }
            sqlite3_finalize(stmt)
        }

        return stats
    }

    // MARK: - Private Methods

    private func ensureInitialized() throws {
        if !isInitialized {
            try open()
        }
    }

    private func extractSessionFrom(stmt: OpaquePointer?) -> Session {
        let id = extractString(from: stmt, at: 0) ?? ""
        let title = extractString(from: stmt, at: 1) ?? ""
        let year = Int(sqlite3_column_int(stmt, 2))
        let sessionNumber = extractString(from: stmt, at: 3) ?? ""
        let type = extractString(from: stmt, at: 4)
        let duration = sqlite3_column_type(stmt, 5) != SQLITE_NULL ? Int(sqlite3_column_int(stmt, 5)) : nil
        let description = extractString(from: stmt, at: 6)
        let webUrl = extractString(from: stmt, at: 7)
        let transcript = extractString(from: stmt, at: 8)
        let wordCount = sqlite3_column_type(stmt, 9) != SQLITE_NULL ? Int(sqlite3_column_int(stmt, 9)) : nil

        return Session(
            id: id,
            title: title,
            year: year,
            sessionNumber: sessionNumber,
            type: type,
            duration: duration,
            description: description,
            webUrl: webUrl,
            transcript: transcript,
            wordCount: wordCount
        )
    }

    private func extractString(from stmt: OpaquePointer?, at index: Int32) -> String? {
        guard let stmt = stmt else { return nil }
        if sqlite3_column_type(stmt, index) != SQLITE_NULL {
            if let cString = sqlite3_column_text(stmt, index) {
                return String(cString: cString)
            }
        }
        return nil
    }

    private func parseJSONArray(_ jsonString: String) -> [String]? {
        guard let data = jsonString.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode([String].self, from: data)
    }

    // MARK: - Internal Types

    private struct EncryptedBundle: Codable {
        let metadata: BundleMetadata
        let encryptedData: String
        let iv: String
        let tag: String
    }
}

// MARK: - Errors

public enum WWDCDatabaseError: Error, LocalizedError {
    case databaseConnectionFailed(String)
    case databaseError(String)
    case queryFailed(String)
    case decryptionFailed(String)
    case invalidBundleFormat
    case keyNotFound

    public var errorDescription: String? {
        switch self {
        case .databaseConnectionFailed(let message):
            return "Failed to connect to database: \(message)"
        case .databaseError(let message):
            return "Database error: \(message)"
        case .queryFailed(let message):
            return "Query failed: \(message)"
        case .decryptionFailed(let message):
            return "Decryption failed: \(message)"
        case .invalidBundleFormat:
            return "Invalid bundle format"
        case .keyNotFound:
            return "Encryption key not found. Please set WWDC_BUNDLE_KEY environment variable."
        }
    }
}