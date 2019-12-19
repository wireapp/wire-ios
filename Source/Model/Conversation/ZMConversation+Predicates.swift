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
    public class func predicate(forSearchQuery searchQuery: String, selfUser: ZMUser) -> NSPredicate! {
        
        let convoNamePredicate = NSPredicate(formatDictionary: [ZMNormalizedUserDefinedNameKey: "%K MATCHES %@"], matchingSearch: searchQuery)!
        let usersPredicates = normalize(searchQuery).map { (strSearchQuery) in
            NSPredicate(format: "ANY %K.user != %@ AND ANY %K.user.normalizedName MATCHES %@", ZMConversationParticipantRolesKey, selfUser, ZMConversationParticipantRolesKey, strSearchQuery)
        }
        let usersPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: usersPredicates)
        let searchPredicate = NSCompoundPredicate(
            orPredicateWithSubpredicates: [usersPredicate, convoNamePredicate])
        let activeMemberPredicate = NSPredicate(format: "%K == NULL OR (ANY %K.user == %@)", ZMConversationClearedTimeStampKey, ZMConversationParticipantRolesKey, selfUser)
        let basePredicate = NSPredicate(format: "(\(ZMConversationConversationTypeKey) == \(ZMConversationType.group.rawValue))")

        /// do not include team 1 to 1 conversations

        let activeParticipantsPredicate = NSPredicate(format: "%K.@count == 1",                                                                      ZMConversationParticipantRolesKey
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
    
    @objc
    public class func normalize(_ string: String) -> [String] {
        var array: [String] = []
        string.components(separatedBy: " ").forEach { (str) in
            array.append(String(format: ".*\\b%@.*", str.lowercased()))
        }
        return array
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
    
    @objc(predicateForGroupConversations)
    class func predicateForGroupConversations() -> NSPredicate {
        let groupConversationPredicate = NSPredicate(format: "\(ZMConversationConversationTypeKey) == \(ZMConversationType.group.rawValue)")
        let notInFolderPredicate = NSCompoundPredicate(notPredicateWithSubpredicate: predicateForConversationsInFolders())
        let notTeamOneToOneConveration = NSCompoundPredicate(notPredicateWithSubpredicate: predicateForTeamOneToOneConversation())
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: [predicateForConversationsExcludingArchived(), groupConversationPredicate, notInFolderPredicate, notTeamOneToOneConveration])
    }
    
    @objc(predicateForLabeledConversations:)
    class func predicateForLabeledConversations(_ label: Label) -> NSPredicate {
        let labelPredicate = NSPredicate(format: "%@ IN \(ZMConversationLabelsKey)", label)
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: [predicateForConversationsExcludingArchived(), labelPredicate])
    }
    
    class func predicateForConversationsInFolders() -> NSPredicate {
        return NSPredicate(format: "ANY %K.%K == \(Label.Kind.folder.rawValue)", ZMConversationLabelsKey, #keyPath(Label.type))
    }
    
    class func predicateForUnconnectedConversations() -> NSPredicate {
        return NSPredicate(format: "\(ZMConversationConversationTypeKey) == \(ZMConversationType.connection.rawValue)")
    }
    
    class func predicateForOneToOneConversation() -> NSPredicate {
        return NSPredicate(format: "\(ZMConversationConversationTypeKey) == \(ZMConversationType.oneOnOne.rawValue)")
    }
    
    class func predicateForTeamOneToOneConversation() -> NSPredicate {
        // We consider a conversation being an existing 1:1 team conversation in case the following point are true:
        //  1. It is a conversation inside a team
        //  2. The only participants are the current user and the selected user
        //  3. It does not have a custom display name
        
        let isTeamConversation = NSPredicate(format: "team != NULL")
        let isGroupConversation = NSPredicate(format: "\(ZMConversationConversationTypeKey) == \(ZMConversationType.group.rawValue)")
        let hasNoUserDefinedName = NSPredicate(format: "\(ZMConversationUserDefinedNameKey) == NULL")
        let hasOnlyOneParticipant = NSPredicate(format: "\(ZMConversationParticipantRolesKey).@count == 2")
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: [isTeamConversation, isGroupConversation, hasNoUserDefinedName, hasOnlyOneParticipant])
    }
    
    @objc(predicateForOneToOneConversations)
    class func predicateForOneToOneConversations() -> NSPredicate {
        // We consider a conversation to be one-to-one if it's of type .oneToOne, is a team 1:1 or an outgoing connection request.
        let oneToOneConversationPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [predicateForOneToOneConversation(), predicateForTeamOneToOneConversation(), predicateForUnconnectedConversations()])
        let notInFolderPredicate = NSCompoundPredicate(notPredicateWithSubpredicate: predicateForConversationsInFolders())
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: [predicateForConversationsExcludingArchived(), oneToOneConversationPredicate, notInFolderPredicate])
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
