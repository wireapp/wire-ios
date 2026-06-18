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

import WireDesign
import WireFoundation

// MARK: - Model

public struct ConversationSummary: Identifiable {
    public let id = UUID()
    public let conversationName: String
    /// `nil` while the AI summary is still being generated.
    public let summary: String?
    public let missedCount: Int
    public let oldestMessageDate: Date?
    public let isGroup: Bool

    public init(
        conversationName: String,
        summary: String? = nil,
        missedCount: Int,
        oldestMessageDate: Date? = nil,
        isGroup: Bool = true
    ) {
        self.conversationName = conversationName
        self.summary = summary
        self.missedCount = missedCount
        self.oldestMessageDate = oldestMessageDate
        self.isGroup = isGroup
    }
}

// MARK: - Root view

public struct CatchUpView: View {

    @Environment(\.wireAccentColor) private var accentColor
    @Binding private var summaries: [ConversationSummary]
    private let onMarkAsRead: (UUID) -> Void

    public init(
        summaries: Binding<[ConversationSummary]> = .constant(ConversationSummary.mocks),
        onMarkAsRead: @escaping (UUID) -> Void = { _ in }
    ) {
        self._summaries = summaries
        self.onMarkAsRead = onMarkAsRead
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
                    ConversationSummaryRow(summary: summary, accentColor: accentColor)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button {
                                onMarkAsRead(summary.id)
                                withAnimation {
                                    summaries.removeAll { $0.id == summary.id }
                                }
                            } label: {
                                Label("Mark as Read", systemImage: "checkmark.circle")
                            }
                            .tint(Color(accentColor))
                        }
                }
            } header: {
                Text(verbatim: subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .textCase(nil)
                    .padding(.bottom)
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
    let accentColor: WireAccentColor

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ConversationSummaryAvatarView(isGroup: summary.isGroup)

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline) {
                    Text(verbatim: summary.conversationName)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Spacer()
                    Text(verbatim: "\(summary.missedCount)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.black, in: Capsule())
                }
                if let text = summary.summary {
                    Text(verbatim: text)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(20)
                } else {
                    HStack(spacing: 6) {
                        ProgressView()
                            .controlSize(.small)
                        Text(verbatim: "Summarizing…")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .alignmentGuide(.listRowSeparatorLeading) { d in d[.leading] + 48 }
    }
}

// MARK: - Avatar

private struct ConversationSummaryAvatarView: View {

    let isGroup: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(.quaternarySystemFill))
            Image(systemName: isGroup ? "person.2.fill" : "person.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(.systemGray))
        }
        .frame(width: 32, height: 32)
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
                oldestMessageDate: calendar.date(byAdding: .day, value: -10, to: now),
                isGroup: true
            ),
            ConversationSummary(
                conversationName: "Design Team",
                summary: "New design specs for the catch-up feature were reviewed. Bob left comments in Figma — the summary card was well received.",
                missedCount: 7,
                oldestMessageDate: calendar.date(byAdding: .day, value: -3, to: now),
                isGroup: true
            ),
            ConversationSummary(
                conversationName: "Alice",
                summary: "Alice asked whether you're joining the hackathon demo on Friday.",
                missedCount: 3,
                oldestMessageDate: calendar.date(byAdding: .day, value: -1, to: now),
                isGroup: false
            ),
            ConversationSummary(
                conversationName: "Berlin Office",
                summary: nil,
                missedCount: 5,
                oldestMessageDate: calendar.date(byAdding: .hour, value: -6, to: now),
                isGroup: true
            )
        ]
    }
}

// MARK: - Preview

#Preview("With summaries") {
    CatchUpView()
        .environment(\.wireAccentColor, .purple)
}

#Preview("Empty") {
    CatchUpView(summaries: .constant([]))
}
