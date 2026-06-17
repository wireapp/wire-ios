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

public import SwiftUI

// MARK: - Model

public struct ConversationSummary: Identifiable {
    public let id = UUID()
    let conversationName: String
    let summary: String
    let missedCount: Int
}

// MARK: - Root view

public struct CatchUpView: View {

    private let summaries: [ConversationSummary]

    public init(summaries: [ConversationSummary] = ConversationSummary.mocks) {
        self.summaries = summaries
    }

    public var body: some View {
        NavigationView {
            Group {
                if summaries.isEmpty {
                    emptyState
                } else {
                    summaryList
                }
            }
            .navigationTitle(Text(verbatim: "Catch-Up"))
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        ContentUnavailableView(
            "You're All Caught Up",
            systemImage: "sparkles",
            description: Text("Summaries of conversations you missed will appear here.")
        )
    }

    // MARK: - List

    private var summaryList: some View {
        List(summaries) { summary in
            ConversationSummaryRow(summary: summary)
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Row

private struct ConversationSummaryRow: View {

    let summary: ConversationSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(verbatim: summary.conversationName)
                    .font(.headline)
                Spacer()
                Text(verbatim: "\(summary.missedCount) missed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(verbatim: summary.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Mock data

extension ConversationSummary {

    public static var mocks: [ConversationSummary] {
        [
            ConversationSummary(
                conversationName: "Engineering",
                summary: "Dave fixed a FoundationModels import issue on older OS versions (branch fix/foundation-models-import). Sprint planning moved to Thursday 2pm in room Zurich.",
                missedCount: 12
            ),
            ConversationSummary(
                conversationName: "Design Team",
                summary: "New design specs for the catch-up feature were reviewed. Bob left comments in Figma — the summary card was well received.",
                missedCount: 7
            ),
            ConversationSummary(
                conversationName: "Alice",
                summary: "Alice asked whether you're joining the hackathon demo on Friday.",
                missedCount: 3
            )
        ]
    }

}

// MARK: - Preview

#Preview("With summaries") {
    CatchUpView()
}

#Preview("Empty") {
    CatchUpView(summaries: [])
}
