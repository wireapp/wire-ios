// Wire
// Copyright (C) 2026 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import Accelerate
public import Foundation

// MARK: - Result type

public struct SemanticSearchResult: Identifiable, Sendable {
    public let id = UUID()
    public let conversationName: String
    public let messageText: String
    public let timestamp: Date
    public let score: Float
}

// MARK: - Index actor

/// Process-wide singleton that stores sentence embeddings and performs
/// cosine-similarity search using Accelerate (vDSP).
///
/// Embeddings are persisted to Application Support as a binary property list
/// so they survive app restarts without re-computing.
public actor SemanticSearchIndex {

    public static let shared = SemanticSearchIndex()

    private struct Entry: Codable, Sendable {
        let uri: String
        let conversationName: String
        let messageText: String
        let timestamp: Date
        let embeddingData: Data  // raw Float32 bytes — no base64 overhead
    }

    private var entries: [Entry] = []
    private var indexedURIs: Set<String> = []
    private let fileURL: URL

    private init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        fileURL = support.appendingPathComponent("wire-semantic-index.bin")
    }

    // MARK: - Persistence

    public func load() {
        guard
            let data = try? Data(contentsOf: fileURL),
            let loaded = try? PropertyListDecoder().decode([Entry].self, from: data)
        else { return }
        entries = loaded
        indexedURIs = Set(loaded.map { $0.uri })
    }

    public func save() throws {
        let data = try PropertyListEncoder().encode(entries)
        try data.write(to: fileURL, options: .atomic)
    }

    // MARK: - Indexing

    public var indexedCount: Int { entries.count }

    public func isIndexed(uri: String) -> Bool {
        indexedURIs.contains(uri)
    }

    public func add(uri: String, conversationName: String, text: String, timestamp: Date, embedding: [Float]) {
        guard !indexedURIs.contains(uri) else { return }
        let data = embedding.withUnsafeBytes { Data($0) }
        entries.append(Entry(
            uri: uri,
            conversationName: conversationName,
            messageText: text,
            timestamp: timestamp,
            embeddingData: data
        ))
        indexedURIs.insert(uri)
    }

    // MARK: - Search

    public func search(queryEmbedding: [Float], limit: Int = 20) -> [SemanticSearchResult] {
        let dim = queryEmbedding.count
        guard dim > 0 else { return [] }

        return entries
            .compactMap { entry -> (SemanticSearchResult, Float)? in
                let floatCount = entry.embeddingData.count / MemoryLayout<Float>.size
                guard floatCount == dim else { return nil }
                let entryEmbedding = entry.embeddingData.withUnsafeBytes { Array($0.bindMemory(to: Float.self)) }
                let score = cosineSimilarity(queryEmbedding, entryEmbedding)
                let result = SemanticSearchResult(
                    conversationName: entry.conversationName,
                    messageText: entry.messageText,
                    timestamp: entry.timestamp,
                    score: score
                )
                return (result, score)
            }
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .map { $0.0 }
    }

    // MARK: - Math

    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        let n = vDSP_Length(a.count)
        var dot: Float = 0
        vDSP_dotpr(a, 1, b, 1, &dot, n)
        var sumSqA: Float = 0
        vDSP_svesq(a, 1, &sumSqA, n)
        var sumSqB: Float = 0
        vDSP_svesq(b, 1, &sumSqB, n)
        let denom = sqrtf(sumSqA) * sqrtf(sumSqB)
        return denom > 0 ? dot / denom : 0
    }
}
