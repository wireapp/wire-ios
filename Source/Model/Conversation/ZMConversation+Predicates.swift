//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
        let selfType = ZMConversationType.init(rawValue: 1)!
        return NSPredicate(format: "\(ZMConversationConversationTypeKey) != \(ZMConversationType.invalid.rawValue) && \(ZMConversationConversationTypeKey) != \(selfType.rawValue)")
    }

    @objc
    public class func predicate(forSearchQuery searchQuery: String) -> NSPredicate! {
        let formatDict = [ZMConversationLastServerSyncedActiveParticipantsKey: "ANY %K.normalizedName MATCHES %@", ZMNormalizedUserDefinedNameKey: "%K MATCHES %@"]
        guard let searchPredicate = NSPredicate(formatDictionary: formatDict, matchingSearch: searchQuery) else { return .none }
        let activeMemberPredicate = NSPredicate(format: "%K == NULL OR %K == YES", ZMConversationClearedTimeStampKey, ZMConversationIsSelfAnActiveMemberKey)
        let basePredicate = NSPredicate(format: "(\(ZMConversationConversationTypeKey) == \(ZMConversationType.group.rawValue))")

        /// do not include team 1 to 1 conversations

        let activeParticipantsPredicate = NSPredicate(format: "%K.@count == 1",                                                                      ZMConversationLastServerSyncedActiveParticipantsKey
        )

        let userDefinedNamePredicate = NSPredicate(format: "%K == NULL",                                                                      ZMConversationUserDefinedNameKey
        )

        let teamRemoteIdentifierPredicate = NSPredicate(format: "%K != NULL",                                                                      TeamRemoteIdentifierDataKey
        )

        let notTeamMemberPredicate = NSCompoundPredicate(notPredicateWithSubpredicate: NSCompoundPredicate(andPredicateWithSubpredicates: [
            activeParticipantsPredicate,
            userDefinedNamePredicate ,
            teamRemoteIdentifierPredicate
            ]))

        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            searchPredicate,
            activeMemberPredicate,
            basePredicate,
            notTeamMemberPredicate
            ])
    }
    
    class func predicateForConversationsWhereSelfUserIsActive() -> NSPredicate {
        return .init(format: "%K == YES", ZMConversationIsSelfAnActiveMemberKey)
    }

    @objc(predicateForConversationsInTeam:)
    class func predicateForConversations(in team: Team?) -> NSPredicate {
        if let team = team {
            return .init(format: "%K == %@", #keyPath(ZMConversation.team), team)
        }

        return .init(format: "%K == NULL", #keyPath(ZMConversation.team))
    }

    @objc(predicateForPendingConversations)
    class func predicateForPendingConversations() -> NSPredicate {
        let basePredicate = predicateForFilteringResults()
        let pendingConversationPredicate = NSPredicate(format: "\(ZMConversationConversationTypeKey) == \(ZMConversationType.connection.rawValue) AND \(ZMConversationConnectionKey).status == \(ZMConnectionStatus.pending.rawValue)")
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: [basePredicate, pendingConversationPredicate])
    }

    @objc(predicateForClearedConversations)
    class func predicateForClearedConversations() -> NSPredicate {
        let cleared = NSPredicate(format: "\(ZMConversationClearedTimeStampKey) != NULL AND \(ZMConversationIsArchivedKey) == YES")
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: [cleared, predicateForValidConversations()])
    }

    @objc(predicateForConversationsIncludingArchived)
    class func predicateForConversationsIncludingArchived() -> NSPredicate {
        let notClearedTimestamp = NSPredicate(format: "\(ZMConversationClearedTimeStampKey) == NULL OR \(ZMConversationLastServerTimeStampKey) > \(ZMConversationClearedTimeStampKey) OR (\(ZMConversationLastServerTimeStampKey) == \(ZMConversationClearedTimeStampKey) AND \(ZMConversationIsArchivedKey) == NO)")
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: [notClearedTimestamp, predicateForValidConversations()])
    }

    @objc(predicateForArchivedConversations)
    class func predicateForArchivedConversations() -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [predicateForConversationsIncludingArchived(), NSPredicate(format: "\(ZMConversationIsArchivedKey) == YES")])
    }

    @objc(predicateForConversationsExcludingArchived)
    class func predicateForConversationsExcludingArchived() -> NSPredicate {
        let notArchivedPredicate = NSPredicate(format: "\(ZMConversationIsArchivedKey) == NO")
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: [predicateForConversationsIncludingArchived(), notArchivedPredicate])
    }

    @objc(predicateForSharableConversations)
    class func predicateForSharableConversations() -> NSPredicate {
        let basePredicate = predicateForConversationsIncludingArchived()
        let hasOtherActiveParticipants = NSPredicate(format: "\(ZMConversationLastServerSyncedActiveParticipantsKey).@count > 0")
        let oneOnOneOrGroupConversation = NSPredicate(format: "\(ZMConversationConversationTypeKey) == \(ZMConversationType.oneOnOne.rawValue) OR \(ZMConversationConversationTypeKey) == \(ZMConversationType.group.rawValue)")
        let selfIsActiveMember = NSPredicate(format: "isSelfAnActiveMember == YES")
        let synced = NSPredicate(format: "\(remoteIdentifierDataKey()!) != NULL")
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: [basePredicate, oneOnOneOrGroupConversation, hasOtherActiveParticipants, selfIsActiveMember, synced])
    }
    
    private class func predicateForValidConversations() -> NSPredicate {
        let basePredicate = predicateForFilteringResults()
        let notAConnection = NSPredicate(format: "\(ZMConversationConversationTypeKey) != \(ZMConversationType.connection.rawValue)")
        let activeConnection = NSPredicate(format: "NOT \(ZMConversationConnectionKey).status IN %@", [NSNumber(value: ZMConnectionStatus.pending.rawValue),
                                                                                                       NSNumber(value: ZMConnectionStatus.ignored.rawValue),
                                                                                                       NSNumber(value: ZMConnectionStatus.cancelled.rawValue)]) //pending connections should be in other list, ignored and cancelled are not displayed
        let predicate1 = NSCompoundPredicate(orPredicateWithSubpredicates: [notAConnection, activeConnection]) // one-to-one conversations and not pending and not ignored connections
        let noConnection = NSPredicate(format: "\(ZMConversationConnectionKey) == nil") // group conversations
        let notBlocked = NSPredicate(format: "\(ZMConversationConnectionKey).status != \(ZMConnectionStatus.blocked.rawValue)")
        let predicate2 = NSCompoundPredicate(orPredicateWithSubpredicates: [noConnection, notBlocked]) //group conversations and not blocked connections
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: [basePredicate, predicate1, predicate2])
    }
    
}
