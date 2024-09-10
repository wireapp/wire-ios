//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

import Foundation
import WireDataModel
import WireSyncEngine

fileprivate extension String {
    var isValidQuery: Bool {
        return !isEmpty && self != "@"
    }
}

typealias GroupParticipantsDetailConversation = GroupDetailsConversationType & StableRandomParticipantsProvider

final class GroupParticipantsDetailViewModel: NSObject, SearchHeaderViewControllerDelegate, ZMConversationObserver {
    private var internalParticipants: [UserType]
    private var filterQuery: String?

    let selectedParticipants: [UserType]
    let conversation: GroupParticipantsDetailConversation
    var participantsDidChange: (() -> Void)?

    let userSession: UserSession
    let isUserE2EICertifiedUseCase: IsUserE2EICertifiedUseCaseProtocol

    private(set) var userStatuses = [UUID: UserStatus]()

    fileprivate var token: NSObjectProtocol?

    var indexPathOfFirstSelectedParticipant: IndexPath? {
        guard let user = selectedParticipants.first as? ZMUser else { return nil }
        guard let row = (internalParticipants.firstIndex {
            ($0 as? ZMUser)?.remoteIdentifier == user.remoteIdentifier
        }) else { return nil }
        let section = user.isGroupAdmin(in: conversation) ? 0 : 1
        return IndexPath(row: row, section: section)
    }

    var participants = [UserType]() {
        didSet {
            computeParticipantGroups()
            participantsDidChange?()
        }
    }

    var admins = [UserType]()
    var members = [UserType]()

    init(
        selectedParticipants: [UserType],
        conversation: GroupParticipantsDetailConversation,
        userSession: UserSession
    ) {
        internalParticipants = conversation.sortedOtherParticipants
        self.conversation = conversation
        self.selectedParticipants = selectedParticipants.sortedAscendingPrependingNil(by: \.name)
        self.userSession = userSession
        isUserE2EICertifiedUseCase = userSession.isUserE2EICertifiedUseCase
        super.init()

        if let conversation = conversation as? ZMConversation {
            token = ConversationChangeInfo.add(observer: self, for: conversation)
        }

        computeVisibleParticipants()
        updateUserE2EICertificationStatuses()
    }

    private func computeVisibleParticipants() {
        guard let query = filterQuery,
            query.isValidQuery else {
                return participants = internalParticipants
        }
        participants = (internalParticipants as NSArray).filtered(using: filterPredicate(for: query)) as! [UserType]
    }

    private func computeParticipantGroups() {
        admins = participants.filter({ $0.isGroupAdmin(in: conversation) })
        members = participants.filter({ !$0.isGroupAdmin(in: conversation) })
    }

    private func filterPredicate(for query: String) -> NSPredicate {
        let trimmedQuery = query.trim()
        var predicates = [
            NSPredicate(format: "name contains[cd] %@", trimmedQuery),
            NSPredicate(format: "handle contains[cd] %@", trimmedQuery)
        ]

        if query.hasPrefix("@") {
            predicates.append(.init(format: "handle contains[cd] %@", String(trimmedQuery.dropFirst())))
        }

        return NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
    }

    func conversationDidChange(_ changeInfo: ConversationChangeInfo) {
        guard changeInfo.participantsChanged else { return }
        internalParticipants = conversation.sortedOtherParticipants
        computeVisibleParticipants()
    }

    // MARK: - SearchHeaderViewControllerDelegate

    func searchHeaderViewController(
        _ searchHeaderViewController: SearchHeaderViewController,
        updatedSearchQuery query: String
    ) {
        filterQuery = query
        computeVisibleParticipants()
    }

    func searchHeaderViewControllerDidConfirmAction(_ searchHeaderViewController: SearchHeaderViewController) {
        // no-op
    }

    // MARK: - UserStatuses

    private func updateUserE2EICertificationStatuses() {
        Task { @MainActor in
            let participants = conversation.sortedOtherParticipants
            for user in participants {
                guard let user = user as? ZMUser else { continue }
                guard let conversation = conversation as? ZMConversation else { continue }
                do {
                    let isE2EICertified = try await isUserE2EICertifiedUseCase.invoke(conversation: conversation, user: user)
                    if userStatuses.keys.contains(user.remoteIdentifier) {
                        userStatuses[user.remoteIdentifier]?.isE2EICertified = isE2EICertified
                    } else {
                        userStatuses[user.remoteIdentifier] = .init(user: user, isE2EICertified: isE2EICertified)
                    }
                } catch {
                    WireLogger.e2ei.error("Failed to get verification status for user: \(error)")
                }
            }
            participantsDidChange?()
        }
    }
}
