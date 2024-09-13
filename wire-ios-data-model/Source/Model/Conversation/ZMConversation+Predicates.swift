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

extension ZMConversation {
    override open class func predicateForFilteringResults() -> NSPredicate {
        let selfType = ZMConversationType(rawValue: 1)!
        return NSPredicate(
            format: "\(ZMConversationConversationTypeKey) != \(ZMConversationType.invalid.rawValue) && \(ZMConversationConversationTypeKey) != \(selfType.rawValue) && \(#keyPath(ZMConversation.isDeletedRemotely)) == NO"
        )
    }

    @objc
    public class func predicate(forSearchQuery searchQuery: String, selfUser: ZMUser) -> NSPredicate! {
        let convoNameMatching = userDefinedNamePredicate(forSearch: searchQuery)

        let selfUserIsMember = NSPredicate(
            format: "%K == NULL OR (ANY %K.user == %@)",
            ZMConversationClearedTimeStampKey,
            ZMConversationParticipantRolesKey,
            selfUser
        )

        let groupOnly =
            NSPredicate(format: "(\(ZMConversationConversationTypeKey) == \(ZMConversationType.group.rawValue))")

        let notTeamOneToOne = NSCompoundPredicate(notPredicateWithSubpredicate: predicateForTeamOneToOneConversation())

        let userNamesMatching = predicateForConversationWithUsers(
            matchingQuery: searchQuery,
            selfUser: selfUser
        )
        let queryMatching = NSCompoundPredicate(
            orPredicateWithSubpredicates: [userNamesMatching, convoNameMatching]
        )

        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            queryMatching,
            selfUserIsMember,
            groupOnly,
            notTeamOneToOne,
        ])
    }

    private class func predicateForConversationWithUsers(
        matchingQuery query: String,
        selfUser: ZMUser
    ) -> NSPredicate {
        let roleNameMatchingRegexes = query.words
            .map { ".*\\b\(NSRegularExpression.escapedPattern(for: $0).lowercased()).*" }

        let roleNameMatchingConditions = roleNameMatchingRegexes.map { _ in
            "$role.user.normalizedName MATCHES %@"
        }.joined(separator: " OR ")

        return NSPredicate(
            format: "SUBQUERY(%K, $role, $role.user != %@ AND (\(roleNameMatchingConditions))).@count > 0",
            argumentArray: [
                ZMConversationParticipantRolesKey,
                selfUser,
            ] + roleNameMatchingRegexes
        )
    }

    @objc(predicateForConversationsInTeam:)
    class func predicateForConversations(in team: Team?) -> NSPredicate {
        if let team {
            return .init(format: "%K == %@", #keyPath(ZMConversation.team), team)
        }

        return .init(format: "%K == NULL", #keyPath(ZMConversation.team))
    }

    public class func predicateForTeamOneToOneConversation() -> NSPredicate {
        // We consider a conversation being an existing 1:1 team conversation in case the following point are true:
        //  1. It is a conversation inside a team
        //  2. The only participants are the current user and the selected user
        //  3. It does not have a custom display name

        let isTeamConversation = NSPredicate(format: "team != NULL")
        let isGroupConversation =
            NSPredicate(format: "\(ZMConversationConversationTypeKey) == \(ZMConversationType.group.rawValue)")
        let hasNoUserDefinedName = NSPredicate(format: "\(ZMConversationUserDefinedNameKey) == NULL")
        let hasOnlyOneParticipant = NSPredicate(format: "\(ZMConversationParticipantRolesKey).@count == 2")

        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            isTeamConversation,
            isGroupConversation,
            hasNoUserDefinedName,
            hasOnlyOneParticipant,
        ])
    }

    class func predicateForConversationsNeedingToBeCalculatedUnreadMessages() -> NSPredicate {
        NSPredicate(format: "%K == YES", ZMConversationNeedsToCalculateUnreadMessagesKey)
    }

    public static func predicateForConversationsArePendingToRefreshMetadata() -> NSPredicate {
        NSPredicate(format: "\(ZMConversationIsPendingMetadataRefreshKey) == YES")
    }
}

extension String {
    var words: [String] {
        var words: [String] = []
        enumerateSubstrings(in: startIndex..., options: .byWords) { substring, _, _, _ in
            words.append(String(substring!))
        }

        if words.isEmpty {
            words = [trimmingCharacters(in: .whitespacesAndNewlines)]
        }

        return words
    }
}
