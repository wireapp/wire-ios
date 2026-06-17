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
import Playgrounds

/// Summarizes a list of chat messages using the on-device Apple Intelligence model.
/// All processing happens on-device — no content leaves the user's device.
@available(iOS 26.0, *)
public struct CatchUpSummarizer {

    // MARK: - Mock data

    public static let mockMessages: [String] = [
        "Alice: Hey team, just a heads up — the server deployment is scheduled for Friday at 10pm.",
        "Bob: Sounds good. Will there be a maintenance window?",
        "Alice: Yes, about 30 minutes. We'll post updates in #status.",
        "Carol: I'll make sure the on-call rotation is aware.",
        "Bob: Also, the iOS build broke this morning. Looks like a dependency issue with the new SDK.",
        "Dave: I looked into it — it's the FoundationModels import on older OS versions. Fixed in branch fix/foundation-models-import.",
        "Bob: Nice, I'll review that PR after standup.",
        "Alice: Sprint planning is moved to Thursday 2pm btw, room Zurich is booked.",
        "Carol: Works for me.",
        "Dave: Also — anyone looked at the new design specs for the catch-up feature?",
        "Bob: Yep, left some comments in Figma. The summary card looks great.",
        "Alice: Let's aim to demo it at the hackathon on Friday!"
    ]

    // MARK: - Constants

    // English text is roughly 4 characters per token.
    private static let charsPerToken = 4
    // Headroom reserved for the system prompt template and the model's response.
    private static let reservedTokens = 512

    // MARK: - Public API

    public init() {}

    /// Returns a summary of the given messages for a user who was away.
    ///
    /// Long conversations are split into chunks and summarized hierarchically so that
    /// the on-device context window is never exceeded.
    public func summarize(messages: [String]) async throws -> String {
        let limit = SystemLanguageModel.default.contextSize - Self.reservedTokens
        return try await summarize(messages: messages, tokenLimit: limit)
    }

    // MARK: - Internals

    private func summarize(messages: [String], tokenLimit: Int) async throws -> String {
        let transcript = messages.joined(separator: "\n")
        let estimatedTokens = transcript.count / Self.charsPerToken

        if estimatedTokens > tokenLimit, messages.count > 1 {
            // Split the message list in half and summarize each part separately,
            // then merge the two partial summaries into one.
            let mid = messages.count / 2
            let firstSummary = try await summarize(messages: Array(messages[..<mid]), tokenLimit: tokenLimit)
            let secondSummary = try await summarize(messages: Array(messages[mid...]), tokenLimit: tokenLimit)
            return try await merge(summaries: [firstSummary, secondSummary])
        }

        return try await callModel(transcript: transcript)
    }

    private func callModel(transcript: String) async throws -> String {
        let session = LanguageModelSession()
        let prompt = """
        A team member was away and wants to catch up on what they missed.

        Read the conversation below and write a catch-up summary as 3–5 short bullet points, grouped by topic. Each bullet point should be one sentence. Cover only decisions, announcements, and action items from real people. Brief acknowledgments ("OK", "sounds good", "+1") are not worth including. Messages from bots, CI pipelines, GitHub, Jira, or other automated tools are also not worth including.

        Conversation:
        \(transcript)
        """
        do {
            let response = try await session.respond(to: prompt)
            return response.content
        } catch LanguageModelSession.GenerationError.exceededContextWindowSize {
            // Should not normally happen after the pre-check above, but if the estimate
            // was off (e.g. non-Latin script) fall back to a single-message summary.
            return try await callModel(transcript: String(transcript.prefix(transcript.count / 2)))
        }
    }

    private func merge(summaries: [String]) async throws -> String {
        let combined = summaries.enumerated()
            .map { "Part \($0.offset + 1):\n\($0.element)" }
            .joined(separator: "\n\n")
        let session = LanguageModelSession()
        let prompt = """
        A team member was away and wants to catch up on what they missed.

        The conversation was long, so it has been pre-summarised in parts below. Combine these partial summaries into one final catch-up summary as 3–5 short bullet points, grouped by topic. Each bullet point should be one sentence. Merge duplicate points across parts into one. Cover only decisions, announcements, and action items.

        \(combined)
        """
        let response = try await session.respond(to: prompt)
        return response.content
    }
}

@available(iOS 26.0, *)
#Playground {
    let summarizer = CatchUpSummarizer()
    let summary = try await summarizer.summarize(messages: CatchUpSummarizer.mockMessages)
    print(summary)
}
