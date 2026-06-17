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
    public let conversationName: String
    public let summary: String
    public let missedCount: Int
    public let oldestMessageDate: Date?

    public init(
        conversationName: String,
        summary: String,
        missedCount: Int,
        oldestMessageDate: Date? = nil
    ) {
        self.conversationName = conversationName
        self.summary = summary
        self.missedCount = missedCount
        self.oldestMessageDate = oldestMessageDate
    }
}

// MARK: - Root view

public struct CatchUpView: View {

    @State private var summaries: [ConversationSummary]

    public init(summaries: [ConversationSummary] = ConversationSummary.mocks) {
        self._summaries = State(initialValue: summaries)
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
        List {
            Section {
                ForEach(summaries) { summary in
                    ConversationSummaryRow(summary: summary)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button {
                                withAnimation {
                                    summaries.removeAll { $0.id == summary.id }
                                }
                            } label: {
                                Label("Mark as Read", systemImage: "checkmark.circle")
                            }
                            .tint(.green)
                        }
                }
            } header: {
                Text(verbatim: subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .textCase(nil)
                    .padding(.bottom, 4)
            }
        }
        .listStyle(.plain)
    }

    private var subtitle: String {
        let totalMissed = summaries.reduce(0) { $0 + $1.missedCount }
        let count = summaries.count
        let oldest = summaries.compactMap(\.oldestMessageDate).min()

        var text = "You have \(totalMissed) unread message\(totalMissed == 1 ? "" : "s") across \(count) conversation\(count == 1 ? "" : "s")"

        if let oldest {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            text += ", the oldest \(formatter.localizedString(for: oldest, relativeTo: Date()))"
        }

        return text + "."
    }
}

// MARK: - Row

private struct ConversationSummaryRow: View {

    let summary: ConversationSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(verbatim: summary.conversationName)
                    .font(.headline)
                Spacer()
                Text(verbatim: "\(summary.missedCount) missed")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Text(verbatim: summary.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(4)
        }
        .padding(.horizontal)
        .padding(.vertical, 14)
    }
}

// MARK: - Mock data

extension ConversationSummary {

    public static var mocks: [ConversationSummary] {
        let calendar = Calendar.current
        let now = Date()
        return [
            ConversationSummary(
                conversationName: "Engineering",
                summary: "Dave fixed a FoundationModels import issue on older OS versions (branch fix/foundation-models-import). Sprint planning moved to Thursday 2pm in room Zurich.",
                missedCount: 12,
                oldestMessageDate: calendar.date(byAdding: .day, value: -10, to: now)
            ),
            ConversationSummary(
                conversationName: "Design Team",
                summary: "New design specs for the catch-up feature were reviewed. Bob left comments in Figma — the summary card was well received.",
                missedCount: 7,
                oldestMessageDate: calendar.date(byAdding: .day, value: -3, to: now)
            ),
            ConversationSummary(
                conversationName: "Alice",
                summary: "Alice asked whether you're joining the hackathon demo on Friday.",
                missedCount: 3,
                oldestMessageDate: calendar.date(byAdding: .day, value: -1, to: now)
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
