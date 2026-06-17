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

import SwiftUI
import WireDataModel
import WireFoundation
import WireMessagingDomain
import WireMessagingUI
import WireSyncEngine

// MARK: - ViewModel

@MainActor
final class CatchUpViewModel: ObservableObject {

    @Published var summaries: [ConversationSummary] = []

    private let userSession: ZMUserSession

    init(userSession: ZMUserSession) {
        self.userSession = userSession
    }

    func load() {
        let conversations = userSession.conversationDirectory.conversations(by: .unread)

        summaries = conversations.map { conversation in
            ConversationSummary(
                conversationName: conversation.displayName ?? "Unknown",
                summary: nil,
                missedCount: conversation.unreadMessages.count,
                oldestMessageDate: conversation.unreadMessages.first?.serverTimestamp,
                isGroup: conversation.conversationType == .group
            )
        }

        for (index, conversation) in conversations.enumerated() {
            let messages: [String] = conversation.unreadMessages.compactMap { message in
                guard let text = message.textMessageData?.messageText, !text.isEmpty else { return nil }
                let senderName = message.sender?.name ?? "Unknown"
                return "\(senderName): \(text)"
            }
            let context = recentReadMessages(before: conversation)

            Task { [weak self] in
                guard let self else { return }
                await summarize(messages: messages, context: context, at: index)
            }
        }
    }

    /// Fetches the last 20 text messages that were already read in this conversation,
    /// so the model has context for references in the new (unread) messages.
    private func recentReadMessages(before conversation: ZMConversation) -> [String] {
        guard
            let moc = conversation.managedObjectContext,
            let readBoundary = conversation.lastReadServerTimeStamp
        else { return [] }

        let request = NSFetchRequest<ZMMessage>(entityName: ZMMessage.entityName())
        request.predicate = NSPredicate(
            format: "visibleInConversation == %@ AND serverTimestamp <= %@",
            conversation,
            readBoundary as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(key: "serverTimestamp", ascending: false)]
        request.fetchLimit = 20

        guard let messages = try? moc.fetch(request) else { return [] }
        return messages.reversed().compactMap { message in
            guard let text = message.textMessageData?.messageText, !text.isEmpty else { return nil }
            let senderName = message.sender?.name ?? "Unknown"
            return "\(senderName): \(text)"
        }
    }

    private func summarize(messages: [String], context: [String], at index: Int) async {
        guard index < summaries.count else { return }

        guard !messages.isEmpty else {
            update(at: index, summary: "No text messages in this conversation.")
            return
        }

        if #available(iOS 26.0, *) {
            do {
                let summary = try await CatchUpSummarizer().summarize(messages: messages, context: context)
                update(at: index, summary: summary)
            } catch {
                update(at: index, summary: "Could not generate summary.")
            }
        } else {
            update(at: index, summary: "Requires iOS 26 or later.")
        }
    }

    private func update(at index: Int, summary: String) {
        guard index < summaries.count else { return }
        let existing = summaries[index]
        summaries[index] = ConversationSummary(
            conversationName: existing.conversationName,
            summary: summary,
            missedCount: existing.missedCount,
            oldestMessageDate: existing.oldestMessageDate,
            isGroup: existing.isGroup
        )
    }
}

// MARK: - Container view

/// Wraps `CatchUpView` and owns the lifecycle of `CatchUpViewModel`.
struct CatchUpContainerView: View {

    @StateObject private var viewModel: CatchUpViewModel
    private let accentColor: WireAccentColor

    init(userSession: ZMUserSession, accentColor: WireAccentColor) {
        _viewModel = StateObject(wrappedValue: CatchUpViewModel(userSession: userSession))
        self.accentColor = accentColor
    }

    var body: some View {
        CatchUpView(summaries: $viewModel.summaries)
            .environment(\.wireAccentColor, accentColor)
            .task { viewModel.load() }
    }
}
