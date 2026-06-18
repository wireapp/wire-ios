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

import FoundationModels
import WireLogging
import Foundation

/// Re-ranks a list of embedding candidates using the on-device Foundation Models LLM.
///
/// NLEmbedding is fast but imprecise. Passing its top-N results here gives the LLM
/// a small, pre-filtered set to judge, combining recall from embeddings with the
/// precision of language understanding.
@available(iOS 26.0, *)
public struct MessageReranker {

    /// Maximum number of candidates to present to the LLM.
    private static let maxCandidates = 30

    public init() {}

    /// Returns a reordered and filtered subset of `candidates` ranked by relevance to `query`.
    /// Falls back to the original order if the model is unavailable or the response is unparseable.
    public func rerank(query: String, candidates: [SemanticSearchResult]) async -> [SemanticSearchResult] {
        let input = Array(candidates.prefix(Self.maxCandidates))
        guard input.count > 1 else { return input }

        let numbered = input.enumerated()
            .map { i, r in "[\(i)] \(r.conversationName): \(r.messageText.prefix(120))" }
            .joined(separator: "\n")

        let prompt = """
        Query: "\(query)"

        Below are messages retrieved by a vector search. List the indices of messages that are genuinely relevant to the query, most relevant first, separated by commas. Omit any that are unrelated. If none are relevant, respond with: none

        \(numbered)
        """

        do {
            let session = LanguageModelSession()
            let response = try await session.respond(to: prompt)
            let content = response.content.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

            guard content != "none" else {
                WireLogger.search.debug("Reranker: no relevant results for query")
                return []
            }

            let indices = content
                .components(separatedBy: CharacterSet(charactersIn: ", \n[]"))
                .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
                .filter { $0 >= 0 && $0 < input.count }

            // Deduplicate while preserving LLM-defined order
            var seen = Set<Int>()
            let ranked = indices.compactMap { i -> SemanticSearchResult? in
                guard seen.insert(i).inserted else { return nil }
                return input[i]
            }

            WireLogger.search.debug("Reranker: \(input.count) candidates → \(ranked.count) results")
            return ranked
        } catch {
            WireLogger.search.warn("Reranker failed (\(error)) — returning embedding order")
            return input
        }
    }
}
