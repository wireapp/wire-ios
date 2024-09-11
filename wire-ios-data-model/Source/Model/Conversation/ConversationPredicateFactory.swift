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

@objc
public final class ConversationPredicateFactory: NSObject {
    private let selfTeam: Team?

    @objc
    init(selfTeam: Team? = nil) {
        self.selfTeam = selfTeam
    }

    @objc(predicateForConversationsExcludingArchived)
    public func predicateForConversationsExcludingArchived() -> NSPredicate {
        let notArchivedPredicate = NSPredicate(format: "\(ZMConversationIsArchivedKey) == NO")

        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            predicateForConversationsIncludingArchived(),
            notArchivedPredicate,
        ])
    }

    @objc(predicateForArchivedConversations)
    public func predicateForArchivedConversations() -> NSPredicate {
        NSCompoundPredicate(andPredicateWithSubpredicates: [
            predicateForConversationsIncludingArchived(),
            NSPredicate(format: "\(ZMConversationIsArchivedKey) == YES"),
        ])
    }

    @objc(predicateForConversationsIncludingArchived)
    public func predicateForConversationsIncludingArchived() -> NSPredicate {
        let notClearedTimestamp =
            NSPredicate(
                format: "\(ZMConversationClearedTimeStampKey) == NULL OR \(ZMConversationLastServerTimeStampKey) > \(ZMConversationClearedTimeStampKey) OR (\(ZMConversationLastServerTimeStampKey) == \(ZMConversationClearedTimeStampKey) AND \(ZMConversationIsArchivedKey) == NO)"
            )

        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            notClearedTimestamp,
            predicateForValidConversations(),
        ])
    }

    @objc(predicateForPendingConversations)
    public func predicateForPendingConversations() -> NSPredicate {
        let basePredicate = ZMConversation.predicateForFilteringResults()
        let pendingConversationPredicate =
            NSPredicate(
                format: "\(ZMConversationConversationTypeKey) == \(ZMConversationType.connection.rawValue) AND \(ZMConversationOneOnOneUserKey).connection.status == \(ZMConnectionStatus.pending.rawValue)"
            )

        return NSCompoundPredicate(andPredicateWithSubpredicates: [basePredicate, pendingConversationPredicate])
    }

    @objc(predicateForClearedConversations)
    public func predicateForClearedConversations() -> NSPredicate {
        let cleared =
            NSPredicate(
                format: "\(ZMConversationClearedTimeStampKey) != NULL AND \(ZMConversationIsArchivedKey) == YES"
            )

        return NSCompoundPredicate(andPredicateWithSubpredicates: [cleared, predicateForValidConversations()])
    }

    @objc(predicateForOneToOneConversations)
    public func predicateForOneToOneConversations() -> NSPredicate {
        // We consider a conversation to be one-to-one if it's of type .oneToOne, is a team 1:1 or an outgoing
        // connection request.
        let oneToOneConversationPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
            predicateForOneToOneConversation(),
            predicateForUnconnectedConversations(),
        ])
        let notInFolderPredicate =
            NSCompoundPredicate(notPredicateWithSubpredicate: predicateForConversationsInFolders())

        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            predicateForConversationsExcludingArchived(),
            oneToOneConversationPredicate,
            notInFolderPredicate,
        ])
    }

    @objc(predicateForGroupConversations)
    public func predicateForGroupConversations() -> NSPredicate {
        let groupConversationPredicate =
            NSPredicate(format: "\(ZMConversationConversationTypeKey) == \(ZMConversationType.group.rawValue)")
        let notInFolderPredicate =
            NSCompoundPredicate(notPredicateWithSubpredicate: predicateForConversationsInFolders())

        return .all(of: [
            predicateForConversationsExcludingArchived(),
            groupConversationPredicate,
            notInFolderPredicate,
        ])
    }

    @objc(predicateForLabeledConversations:)
    public func predicateForLabeledConversations(_ label: Label) -> NSPredicate {
        let labelPredicate = NSPredicate(format: "%@ IN \(ZMConversationLabelsKey)", label)

        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            predicateForConversationsExcludingArchived(),
            labelPredicate,
        ])
    }

    private func predicateForValidConversations() -> NSPredicate {
        let basePredicate = ZMConversation.predicateForFilteringResults()
        return .all(of: [basePredicate, isProtocolReady(), isValidConversation()])
    }

    private func isProtocolReady() -> NSPredicate {
        // Proteus
        let isProteus =
            NSPredicate(format: "\(ZMConversation.messageProtocolKey) == \(MessageProtocol.proteus.int16Value)")

        // Mixed
        let isMixed = NSPredicate(format: "\(ZMConversation.messageProtocolKey) == \(MessageProtocol.mixed.int16Value)")

        // MLS
        let isMLS = NSPredicate(format: "\(ZMConversation.messageProtocolKey) == \(MessageProtocol.mls.int16Value)")
        let isMLSStatusReady = NSPredicate(format: "\(ZMConversation.mlsStatusKey) == \(MLSGroupStatus.ready.rawValue)")
        let isMLSAndReady = NSPredicate.all(of: [isMLS, isMLSStatusReady])

        return .any(of: [isProteus, isMixed, isMLSAndReady])
    }

    private func isValidConversation() -> NSPredicate {
        .any(of: [isValidConnection(), isValidOneOnOne(), isValidGroup()])
    }

    private func isValidConnection() -> NSPredicate {
        let isConnection =
            NSPredicate(format: "\(ZMConversationConversationTypeKey) == \(ZMConversationType.connection.rawValue)")

        let isActive = NSPredicate(format: "NOT \(ZMConversationOneOnOneUserKey).connection.status IN %@", [
            NSNumber(value: ZMConnectionStatus.pending.rawValue),
            NSNumber(value: ZMConnectionStatus.ignored.rawValue),
            NSNumber(value: ZMConnectionStatus.cancelled.rawValue),
        ])

        return .all(of: [isConnection, isActive])
    }

    private func isValidOneOnOne() -> NSPredicate {
        let isOneOnOne =
            NSPredicate(format: "\(ZMConversationConversationTypeKey) == \(ZMConversationType.oneOnOne.rawValue)")
        let hasOneOnOneUser = NSPredicate(format: "\(#keyPath(ZMConversation.oneOnOneUser)) != NULL")
        let isConnectionAccepted =
            NSPredicate(
                format: "\(#keyPath(ZMConversation.oneOnOneUser)).connection.status == \(ZMConnectionStatus.accepted.rawValue)"
            )

        let isOtherUserInSameTeam = if let selfTeam {
            NSPredicate(format: "\(#keyPath(ZMConversation.oneOnOneUser.membership.team)) == %@", selfTeam)
        } else {
            NSPredicate(value: false)
        }

        let isOtherUserBot = NSPredicate(format: "\(#keyPath(ZMConversation.oneOnOneUser.serviceIdentifier)) != NULL")

        return isOneOnOne.and(hasOneOnOneUser).and(isConnectionAccepted.or(isOtherUserInSameTeam).or(isOtherUserBot))
    }

    private func isValidGroup() -> NSPredicate {
        let isGroup =
            NSPredicate(format: "\(ZMConversationConversationTypeKey) == \(ZMConversationType.group.rawValue)")
        // Fake 1:1 conversations are actually groups, so we check
        // whether this group has a one on one user to filter it out.
        let hasNoOneOnOneUser = NSPredicate(format: "\(#keyPath(ZMConversation.oneOnOneUser)) == NULL")
        return isGroup.and(hasNoOneOnOneUser)
    }

    private func predicateForConversationsInFolders() -> NSPredicate {
        NSPredicate(format: "ANY %K.%K == \(Label.Kind.folder.rawValue)", ZMConversationLabelsKey, #keyPath(Label.type))
    }

    private func predicateForOneToOneConversation() -> NSPredicate {
        let isOneOnOne =
            NSPredicate(format: "\(ZMConversationConversationTypeKey) == \(ZMConversationType.oneOnOne.rawValue)")
        let hasOneOnOneUser = NSPredicate(format: "\(ZMConversationOneOnOneUserKey) != NULL")
        return NSCompoundPredicate(andPredicateWithSubpredicates: [isOneOnOne, hasOneOnOneUser])
    }

    private func predicateForUnconnectedConversations() -> NSPredicate {
        NSPredicate(format: "\(ZMConversationConversationTypeKey) == \(ZMConversationType.connection.rawValue)")
    }
}
