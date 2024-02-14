//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

public protocol FederationTerminationManagerInterface {

    func handleFederationTerminationWith(_ domain: String)
    func handleFederationTerminationBetween(_ domain: String, otherDomain: String)

}

public final class FederationTerminationManager: FederationTerminationManagerInterface {

    private var context: NSManagedObjectContext

    public init(with context: NSManagedObjectContext) {
        self.context = context
    }

    /// **Changes will be performed:**
    /// - for all conversations owned by self domain, remove all users that belong to `domain` from those conversations;
    /// - for all conversations owned by `domain`, remove all users from self domain from those conversations;
    /// - for all conversations that are NOT owned from self domain or `domain` and contain users from self domain and `domain`,
    /// remove users from `domain` and `otherDomain` from those conversations;
    /// - for any connection from a user on self domain to a user on `domain`, delete the connection;
    /// - for any 1:1 conversation, where one of the two users is on `domain`, remove self user from those conversations;
    /// - remove connection for all connected users owned by `domain`.
    public func handleFederationTerminationWith(_ domain: String) {
        removeUsers(with: domain, fromConversationsOwnedBy: context.selfDomain)
        removeUsers(with: context.selfDomain, fromConversationsOwnedBy: domain)
        removeUsers(with: [context.selfDomain, domain], fromConversationsNotOwnedBy: [context.selfDomain, domain])

        removeConnectionRequests(with: domain)
        markOneToOneConversationsAsReadOnly(with: domain)
        removeConnectedUsers(with: domain)
    }

    /// **Changes will be performed:**
    /// - for all conversations that are NOT owned from `domain` or `otherDomain` and contain users from `domain` and `otherDomain`,
    /// remove users from `domain` and `otherDomain` from those conversations;
    /// - for all conversations owned by `domain` that contains users from `otherDomain`, remove users from `otherDomain` from those conversations;
    /// - for all conversations owned by `otherDomain` that contains users from `domain`, remove users from `domain` from those conversations.
    public func handleFederationTerminationBetween(_ domain: String, otherDomain: String) {
        removeUsers(with: [domain, otherDomain], fromConversationsNotOwnedBy: [domain, otherDomain])
        removeUsers(with: domain, fromConversationsOwnedBy: otherDomain)
        removeUsers(with: otherDomain, fromConversationsOwnedBy: domain)
    }

}

private extension FederationTerminationManager {

    func markOneToOneConversationsAsReadOnly(with domain: String) {
        let connectedUsersPredicate = ZMUser.predicateForConnectedUsers(hostedOnDomain: domain)
        let fetchRequest = ZMUser.sortedFetchRequest(with: connectedUsersPredicate)
        if let users = context.fetchOrAssert(request: fetchRequest) as? [ZMUser] {
            users
                .compactMap(\.oneOnOneConversation)
                .filter { !$0.isForcedReadOnly }
                .forEach { conversation in
                    conversation.appendFederationTerminationSystemMessage(domains: [domain, context.selfDomain])
                    conversation.isForcedReadOnly = true
                }
        }
    }

    func removeConnectedUsers(with domain: String) {
        let connectedUsersPredicate = ZMUser.predicateForConnectedUsers(hostedOnDomain: domain)
        let fetchRequest = ZMUser.sortedFetchRequest(with: connectedUsersPredicate)
        if let connectedUsers = context.fetchOrAssert(request: fetchRequest) as? [ZMUser] {
            connectedUsers.forEach { user in
                user.connection = nil
            }
        }
    }

    func removeConnectionRequests(with domain: String) {
        let sentAndPendingConnectionsPredicate = ZMUser.predicateForSentAndPendingConnections(hostedOnDomain: domain)
        let pendingUsersFetchRequest = ZMUser.sortedFetchRequest(with: sentAndPendingConnectionsPredicate)
        if let pendingUsers = context.fetchOrAssert(request: pendingUsersFetchRequest) as? [ZMUser] {
            pendingUsers.forEach { user in
                user.connection?.status = (user.connection?.status == .pending) ? .ignored : .cancelled
            }
        }
    }

    func removeUsers(with userDomain: String, fromConversationsOwnedBy domain: String) {
        conversationsHosted(on: domain, withParticipantsOn: userDomain).forEach {
            $0.appendFederationTerminationSystemMessage(domains: [userDomain, domain])
            $0.removeParticipants(with: [userDomain])
        }
    }

    func conversationsHosted(on domain: String, withParticipantsOn userDomain: String) -> [ZMConversation] {
        return ZMConversation.groupConversations(hostedOnDomain: domain, in: context)
                             .filter { $0.hasLocalParticipantsFrom(Set([userDomain])) }
    }

    func removeUsers(with userDomains: [String], fromConversationsNotOwnedBy domains: [String]) {
        conversationsNotHosted(on: domains, withParticipantsOn: userDomains).forEach {
            $0.appendFederationTerminationSystemMessage(domains: userDomains)
            $0.removeParticipants(with: userDomains)
        }
    }

    func conversationsNotHosted(on domains: [String], withParticipantsOn userDomains: [String]) -> [ZMConversation] {
        return ZMConversation.groupConversations(notHostedOnDomains: domains, in: context)
                             .filter { $0.hasLocalParticipantsFrom(Set(userDomains)) }
    }

}

// MARK: - Append system messages

private extension ZMConversation {

    func appendParticipantsRemovedSystemMessage(_ users: Set<ZMUser>) {
        guard let context = managedObjectContext else {
            return
        }
        let selfUser = ZMUser.selfUser(in: context)
        appendParticipantsRemovedAnonymouslySystemMessage(users: users,
                                                          sender: selfUser,
                                                          removedReason: .federationTermination,
                                                          at: Date())
    }

    func appendFederationTerminationSystemMessage(domains: [String]) {
        guard let context = managedObjectContext else {
            return
        }
        let selfUser = ZMUser.selfUser(in: context)
        appendFederationTerminationSystemMessage(domains: domains, sender: selfUser, at: Date())
    }

}

private extension ZMConversation {

    func removeParticipants(with domains: [String]) {
        let participants = localParticipants.filter { user in
            if let domain = user.domain {
                return domain.isOne(of: domains)
            } else {
                return false
            }
        }

        removeParticipantsLocally(participants)
        appendParticipantsRemovedSystemMessage(participants)
    }

    func hasLocalParticipantsFrom(_ domains: Set<String>) -> Bool {
        let localParticipantDomains = Set(localParticipants.compactMap { $0.domain })

        return domains.isSubset(of: localParticipantDomains)
    }

}

private extension NSManagedObjectContext {

    var selfDomain: String {
        return ZMUser.selfUser(in: self).domain ?? ""
    }

}
