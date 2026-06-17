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

    // MARK: - Summarization

    private let session = LanguageModelSession()

    public init() {}

    /// Returns a summary of the given messages for a user who was away.
    public func summarize(messages: [String]) async throws -> String {
        let transcript = messages.joined(separator: "\n")
        let prompt = """
        The following is a team chat conversation. Summarize what happened for a team member \
        who was away. Be concise, group related topics together, and do not invent any content \
        that is not present in the messages.

        Conversation:
        \(transcript)
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
