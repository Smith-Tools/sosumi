import Foundation
import SmithRAG

/// Adapter to use SmithRAG for Sosumi WWDC search operations
public actor SosumiRAGAdapter {
    private let ragEngine: RAGEngine
    
    public init(ragDatabasePath: String = defaultRAGDatabasePath()) throws {
        self.ragEngine = try RAGEngine(databasePath: ragDatabasePath)
    }
    
    /// Semantic search for WWDC sessions using RAG pipeline
    public func search(
        query: String,
        limit: Int = 5,
        useReranker: Bool = true
    ) async throws -> [WWDCRAGResult] {
        let results = try await ragEngine.search(
            query: query,
            limit: limit,
            candidateCount: 100,
            useReranker: useReranker
        )
        
        return results.map { result in
            // Parse session info from chunk ID (format: "wwdc-2024-10102-chunk-0")
            let sessionInfo = parseSessionInfo(from: result.id)
            return WWDCRAGResult(
                chunkId: result.id,
                sessionId: sessionInfo.sessionId,
                year: sessionInfo.year,
                snippet: result.snippet,
                score: result.score
            )
        }
    }
    
    /// Fetch content by chunk ID
    public func fetch(chunkId: String, contextSize: Int = 2) async throws -> String {
        let result = try await ragEngine.fetch(
            id: chunkId,
            mode: contextSize > 0 ? .context : .chunk,
            contextSize: contextSize
        )
        return result.content
    }
    
    /// Ingest a WWDC session into RAG
    public func ingestSession(
        sessionId: String,
        year: Int,
        title: String,
        transcript: String
    ) async throws {
        let documentId = "wwdc-\(year)-\(sessionId)"
        try await ragEngine.ingest(
            documentId: documentId,
            title: "WWDC\(year): \(title)",
            url: "https://developer.apple.com/videos/play/wwdc\(year)/\(sessionId)",
            content: transcript,
            chunkSize: 400,
            overlap: 50
        )
    }
    
    /// Check RAG system status
    public func status() async -> (embedding: Bool, reranker: Bool) {
        await ragEngine.checkOllama()
    }
    
    private func parseSessionInfo(from chunkId: String) -> (sessionId: String?, year: Int?) {
        // Expected format: "wwdc-2024-10102-chunk-0"
        let parts = chunkId.split(separator: "-")
        guard parts.count >= 3,
              parts[0] == "wwdc",
              let year = Int(parts[1]) else {
            return (nil, nil)
        }
        return (String(parts[2]), year)
    }
    
    /// Default RAG database path for Sosumi
    public static func defaultRAGDatabasePath() -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".smith/rag/sosumi.db").path
    }
}

public struct WWDCRAGResult: Sendable {
    public let chunkId: String
    public let sessionId: String?
    public let year: Int?
    public let snippet: String
    public let score: Float
}
