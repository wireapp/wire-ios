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

    /// Recent messages that were already read — passed as `context:` to give the model background.
    public static let mockContextMessages: [String] = [
        "Alice: Hey team, just a heads up — the server deployment is scheduled for Friday at 10pm.",
        "Bob: Sounds good. Will there be a maintenance window?",
        "Alice: Yes, about 30 minutes. We'll post updates in #status.",
        "Carol: I'll make sure the on-call rotation is aware."
    ]

    /// New (unread) messages — passed as `messages:` to be summarized.
    public static let mockMessages: [String] = [
        "Bob: Also, the iOS build broke this morning. Looks like a dependency issue with the new SDK.",
        "Dave: I looked into it — it's the FoundationModels import on older OS versions. Fixed in branch fix/foundation-models-import.",
        "Bob: Nice, I'll review that PR after standup.",
        "Alice: Sprint planning is moved to Thursday 2pm btw, room Zurich is booked.",
        "Carol: Works for me.",
        "Dave: Also — anyone looked at the new design specs for the catch-up feature?",
        "Bob: Yep, left some comments in Figma. The summary card looks great.",
        "Alice: Let's aim to demo it at the hackathon on Friday!"
    ]

    /// Trivial messages — exercises the short-transcript fallback (no model call).
    public static let mockTrivialMessages: [String] = [
        "Alice: Hi!",
        "Bob: Hey, how's it going?"
    ]

    // MARK: - Constants

    // English text is roughly 4 characters per token.
    private static let charsPerToken = 4
    // Headroom reserved for the system prompt template and the model's response.
    private static let reservedTokens = 512
    // Transcripts shorter than this are not worth sending to the model — it tends to hallucinate on sparse input.
    private static let minimumTranscriptLength = 120

    // MARK: - Public API

    public init() {}

    /// Returns a summary of the new (unread) messages for a user who was away.
    ///
    /// Pass recent already-read messages in `context` so the model can understand
    /// references in the new messages. Long new-message lists are split and summarized
    /// hierarchically so the on-device context window is never exceeded.
    public func summarize(messages: [String], context: [String] = []) async throws -> String {
        let limit = SystemLanguageModel.default.contextSize - Self.reservedTokens
        return try await summarize(messages: messages, context: context, tokenLimit: limit)
    }

    // MARK: - Internals

    private func summarize(messages: [String], context: [String], tokenLimit: Int) async throws -> String {
        let newTranscript = messages.joined(separator: "\n")

        // Skip the model for trivial transcripts — avoid hallucination on near-empty input.
        // Show the raw messages directly instead so the user still sees what was said.
        guard newTranscript.count >= Self.minimumTranscriptLength else {
            return paraphrase(messages: messages)
        }

        // Context counts toward the token budget but is trimmed from the front, never split.
        let contextTranscript = context.joined(separator: "\n")
        let estimatedTokens = (contextTranscript.count + newTranscript.count) / Self.charsPerToken

        if estimatedTokens > tokenLimit, messages.count > 1 {
            // Split only the new messages in half; context is dropped on recursive calls
            // because each chunk covers a narrow time window and doesn't need it.
            let mid = messages.count / 2
            let firstSummary = try await summarize(messages: Array(messages[..<mid]), context: [], tokenLimit: tokenLimit)
            let secondSummary = try await summarize(messages: Array(messages[mid...]), context: [], tokenLimit: tokenLimit)
            return try await merge(summaries: [firstSummary, secondSummary])
        }

        return try await callModel(newTranscript: newTranscript, contextTranscript: contextTranscript.isEmpty ? nil : contextTranscript)
    }

    private func callModel(newTranscript: String, contextTranscript: String?) async throws -> String {
        let session = LanguageModelSession()

        let contextSection = contextTranscript.map { """

        <prior_conversation>
        \($0)
        </prior_conversation>
        """ } ?? ""

        let prompt = """
        Extract decisions, announcements, and action items from the new messages inside <new_messages> tags. Write at most 5 bullet points, one sentence each. Every bullet point must be directly supported by text inside <new_messages> — do not add, infer, or invent anything. If there are no decisions, announcements, or action items, respond with only: Nothing to summarize.\(contextSection)

        <new_messages>
        \(newTranscript)
        </new_messages>
        """
        do {
            let response = try await session.respond(to: prompt)
            // If the model found nothing worth reporting, show the raw messages instead.
            if response.content.localizedCaseInsensitiveContains("nothing to summarize") {
                return paraphrase(messages: newTranscript.components(separatedBy: "\n"))
            }
            return response.content
        } catch LanguageModelSession.GenerationError.exceededContextWindowSize {
            // Should not normally happen after the pre-check above, but if the estimate
            // was off (e.g. non-Latin script) drop context and retry with half the new transcript.
            return try await callModel(
                newTranscript: String(newTranscript.prefix(newTranscript.count / 2)),
                contextTranscript: nil
            )
        }
    }

    /// Returns a compact plain-text representation of the messages without model involvement.
    /// Used as a fallback when there is nothing meaningful to summarize (e.g. only greetings).
    private func paraphrase(messages: [String]) -> String {
        messages.prefix(5).joined(separator: "\n")
    }

    private func merge(summaries: [String]) async throws -> String {
        let combined = summaries.enumerated()
            .map { "Part \($0.offset + 1):\n\($0.element)" }
            .joined(separator: "\n\n")
        let session = LanguageModelSession()
        let prompt = """
        Combine the partial summaries inside <summaries> tags into one final list. Keep only decisions, announcements, and action items. Merge duplicates. At most 5 bullet points, one sentence each. Use only what is stated in the summaries — do not add anything. If there is nothing significant, respond with only: Nothing to summarize.

        <summaries>
        \(combined)
        </summaries>
        """
        let response = try await session.respond(to: prompt)
        return response.content
    }
}

@available(iOS 26.0, *)
#Playground {
    let summarizer = CatchUpSummarizer()

    // Full flow: new messages + prior context (mirrors what CatchUpViewModel passes).
    print("=== With context ===")
    let summary = try await summarizer.summarize(
        messages: CatchUpSummarizer.mockMessages,
        context: CatchUpSummarizer.mockContextMessages
    )
    print(summary)

    // No context: should still produce a reasonable summary.
    print("\n=== Without context ===")
    let summaryNoContext = try await summarizer.summarize(
        messages: CatchUpSummarizer.mockMessages
    )
    print(summaryNoContext)

    // Trivial messages: should fall back to paraphrase without calling the model.
    print("\n=== Trivial (paraphrase fallback) ===")
    let trivial = try await summarizer.summarize(
        messages: CatchUpSummarizer.mockTrivialMessages
    )
    print(trivial)
}
